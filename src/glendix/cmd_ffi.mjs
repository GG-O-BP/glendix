// 셸 명령어 실행 + 파일 존재 확인 + 브릿지 자동 생성 + 바인딩 생성 FFI 어댑터
import { execSync, spawnSync, spawn } from "node:child_process";
import { existsSync, readFileSync, writeFileSync, unlinkSync, mkdirSync, readdirSync, statSync, readSync } from "node:fs";
import { inflateRawSync } from "node:zlib";
import { Some, None } from "../../gleam_stdlib/gleam/option.mjs";

// ── TOML 파서/라이터 (tools.glendix 섹션) ──

const TOML_MX_DIR = ".marketplace-cache";
const TOML_SESSION_PATH = `${TOML_MX_DIR}/session.json`;
const TOML_API_BASE = "https://marketplace-api.mendix.com/v1";

function parseTomlValue(raw) {
  if (raw.startsWith('"') && raw.endsWith('"')) return raw.slice(1, -1);
  if (raw.startsWith('[') && raw.endsWith(']')) {
    const inner = raw.slice(1, -1).trim();
    if (inner === "") return [];
    return inner.split(',').map(s => {
      s = s.trim();
      if (s.startsWith('"') && s.endsWith('"')) return s.slice(1, -1);
      return s;
    });
  }
  const num = parseInt(raw, 10);
  if (!isNaN(num) && String(num) === raw) return num;
  if (raw === "true") return true;
  if (raw === "false") return false;
  return raw;
}

function parseGlendixToml() {
  if (!existsSync("gleam.toml")) return null;
  const content = readFileSync("gleam.toml", "utf-8");
  const lines = content.split(/\r?\n/);
  const result = { pm: null, bindings: {}, widgets: {} };
  let currentSection = null;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;

    const sectionMatch = trimmed.match(/^\[(.+)\]$/);
    if (sectionMatch) {
      const path = sectionMatch[1];
      if (path === "tools.glendix") currentSection = "root";
      else if (path === "tools.glendix.bindings") currentSection = "bindings";
      else if (path.startsWith("tools.glendix.widgets.")) {
        const wn = path.slice("tools.glendix.widgets.".length);
        currentSection = "widgets." + wn;
        if (!result.widgets[wn]) result.widgets[wn] = {};
      } else currentSection = null;
      continue;
    }

    if (!currentSection) continue;

    const kvMatch = trimmed.match(/^("(?:[^"\\]|\\.)*"|[A-Za-z0-9_-]+)\s*=\s*(.+)$/);
    if (!kvMatch) continue;

    let key = kvMatch[1].trim();
    if (key.startsWith('"') && key.endsWith('"')) key = key.slice(1, -1);
    const value = parseTomlValue(kvMatch[2].trim());

    if (currentSection === "root") {
      if (key === "pm") result.pm = value;
    } else if (currentSection === "bindings") {
      result.bindings[key] = value;
    } else if (currentSection.startsWith("widgets.")) {
      const wn = currentSection.slice("widgets.".length);
      result.widgets[wn][key] = value;
    }
  }

  return result;
}

function formatTomlValue(value) {
  if (typeof value === "string") return `"${value}"`;
  if (typeof value === "number") return String(value);
  if (typeof value === "boolean") return value ? "true" : "false";
  if (Array.isArray(value)) return "[" + value.map(v => `"${v}"`).join(", ") + "]";
  return String(value);
}

function writeTomlKey(sectionPath, key, value) {
  const content = readFileSync("gleam.toml", "utf-8");
  const lines = content.split(/\r?\n/);
  const sectionHeader = `[${sectionPath}]`;
  let sectionStart = -1;
  let sectionEnd = lines.length;

  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (trimmed === sectionHeader) sectionStart = i;
    else if (sectionStart >= 0 && /^\[/.test(trimmed)) { sectionEnd = i; break; }
  }

  if (sectionStart === -1) {
    writeTomlSection(sectionPath, [[key, value]]);
    return;
  }

  const needsQuote = /[^A-Za-z0-9_-]/.test(key);
  const formattedKey = needsQuote ? `"${key}"` : key;
  const newLine = `${formattedKey} = ${formatTomlValue(value)}`;

  let keyLine = -1;
  let commentedKeyLine = -1;
  for (let i = sectionStart + 1; i < sectionEnd; i++) {
    const trimmed = lines[i].trim();
    const kvMatch = trimmed.match(/^("(?:[^"\\]|\\.)*"|[A-Za-z0-9_-]+)\s*=\s*/);
    if (kvMatch) {
      let k = kvMatch[1].trim();
      if (k.startsWith('"') && k.endsWith('"')) k = k.slice(1, -1);
      if (k === key) { keyLine = i; break; }
    }
    const commentMatch = trimmed.match(/^#\s*("(?:[^"\\]|\\.)*"|[A-Za-z0-9_-]+)\s*=\s*/);
    if (commentMatch) {
      let k = commentMatch[1].trim();
      if (k.startsWith('"') && k.endsWith('"')) k = k.slice(1, -1);
      if (k === key) commentedKeyLine = i;
    }
  }

  if (keyLine >= 0) lines[keyLine] = newLine;
  else if (commentedKeyLine >= 0) lines[commentedKeyLine] = newLine;
  else lines.splice(sectionEnd, 0, newLine);

  writeFileSync("gleam.toml", lines.join("\n"));
}

function writeTomlSection(sectionPath, entries) {
  const content = readFileSync("gleam.toml", "utf-8");
  const lines = content.split(/\r?\n/);
  const sectionHeader = `[${sectionPath}]`;

  for (const line of lines) {
    if (line.trim() === sectionHeader) {
      for (const [key, value] of entries) writeTomlKey(sectionPath, key, value);
      return;
    }
  }

  let lastGlendixEnd = -1;
  let inGlendix = false;
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (trimmed.startsWith("[tools.glendix")) { inGlendix = true; lastGlendixEnd = i; }
    else if (inGlendix && /^\[/.test(trimmed) && !trimmed.startsWith("[tools.glendix")) break;
    else if (inGlendix) lastGlendixEnd = i;
  }

  const block = [`\n${sectionHeader}`];
  for (const [key, value] of entries) {
    const needsQuote = /[^A-Za-z0-9_-]/.test(key);
    const fk = needsQuote ? `"${key}"` : key;
    block.push(`${fk} = ${formatTomlValue(value)}`);
  }

  if (lastGlendixEnd >= 0) lines.splice(lastGlendixEnd + 1, 0, ...block);
  else lines.push(...block);

  writeFileSync("gleam.toml", lines.join("\n"));
}

// ── TOML 위젯 다운로드 헬퍼 ──

function curlJsonSimple(url, pat) {
  try {
    const result = execSync(
      `curl -s -H "Authorization: MxToken ${pat}" "${url}"`,
      { encoding: "utf-8", shell: true },
    );
    return JSON.parse(result);
  } catch { return null; }
}

function escPw(s) {
  return s.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}

function runPwScript(script, timeout) {
  if (!existsSync(TOML_MX_DIR)) mkdirSync(TOML_MX_DIR, { recursive: true });
  const tmp = `${TOML_MX_DIR}/pw_${Date.now()}.mjs`;
  writeFileSync(tmp, script);
  try {
    return execSync(`node "${tmp}"`, {
      encoding: "utf-8", timeout: timeout || 300000,
      shell: true, stdio: ["pipe", "pipe", "inherit"],
    }).trim();
  } finally {
    try { unlinkSync(tmp); } catch {}
  }
}

function ensureSessionForResolve() {
  if (existsSync(TOML_SESSION_PATH)) {
    try {
      const out = runPwScript(
`import { chromium } from 'playwright';
const b = await chromium.launch({ headless: true });
const c = await b.newContext({ storageState: '${escPw(TOML_SESSION_PATH)}' });
const p = await c.newPage();
await p.goto('https://marketplace.mendix.com/', { waitUntil: 'domcontentloaded' });
await p.waitForTimeout(3000);
const valid = !p.url().includes('login.mendix');
await b.close();
console.log(JSON.stringify({ valid }));
`, 30000);
      if (JSON.parse(out).valid) return true;
    } catch {}
    console.log("  저장된 세션이 만료되었습니다.");
  }

  console.log("  브라우저에서 Mendix 로그인을 완료하세요...\n");
  try {
    const tmp = `${TOML_MX_DIR}/pw_${Date.now()}.mjs`;
    writeFileSync(tmp,
`import { chromium } from 'playwright';
const b = await chromium.launch({ headless: false });
const c = await b.newContext();
const p = await c.newPage();
await p.goto('https://login.mendix.com/');
await p.waitForURL(u => !u.toString().includes('login.mendix'), { timeout: 300000 });
await c.storageState({ path: '${escPw(TOML_SESSION_PATH)}' });
await b.close();
`);
    try {
      execSync(`node "${tmp}"`, { timeout: 300000, shell: true, stdio: "inherit" });
    } finally {
      try { unlinkSync(tmp); } catch {}
    }
    if (existsSync(TOML_SESSION_PATH)) {
      console.log("  로그인 성공!\n");
      return true;
    }
    console.log("  세션 파일이 생성되지 않았습니다.\n");
    return false;
  } catch (e) {
    console.log(`  로그인 실패: ${e.message}\n`);
    return false;
  }
}

function searchContentByName(name, pat) {
  const url = `${TOML_API_BASE}/content?name=${encodeURIComponent(name)}`;
  const data = curlJsonSimple(url, pat);
  if (!data?.items) return null;
  const match = data.items.find(i => i.type === "Widget" || i.type === "Module");
  return match ? match.contentId : null;
}

function getS3IdForVersion(contentId, targetVersion) {
  try {
    const out = runPwScript(
`import { chromium } from 'playwright';
const b = await chromium.launch({ headless: true });
const c = await b.newContext({ storageState: '${escPw(TOML_SESSION_PATH)}' });
const p = await c.newPage();
const responsePromises = [];
const xasHandler = (response) => {
  if (!response.url().includes('/xas/')) return;
  responsePromises.push(response.json().catch(() => null));
};
p.on('response', xasHandler);
try {
  await p.goto('https://marketplace.mendix.com/link/component/${contentId}', {
    waitUntil: 'networkidle', timeout: 30000,
  });
  const tabSelectors = [
    'a.mx-name-tabPage10',
    'a[role="tab"]:has-text("Releases")',
    'text="Releases"',
  ];
  for (const sel of tabSelectors) {
    try {
      const tab = p.locator(sel).first();
      if (await tab.isVisible({ timeout: 2000 }).catch(() => false)) {
        await tab.click();
        await p.waitForLoadState('networkidle');
        break;
      }
    } catch {}
  }
  await p.waitForTimeout(3000);
} catch {}
p.removeListener('response', xasHandler);
const responses = await Promise.all(responsePromises);
let result = null;
for (const json of responses) {
  if (!json?.objects) continue;
  for (const obj of json.objects) {
    if (obj.objectType !== 'AppStore.Version') continue;
    const attrs = obj.attributes;
    if (!attrs?.S3ObjectId?.value) continue;
    const vn = attrs.DisplayVersionNumber?.value;
    if (vn === '${targetVersion}') { result = attrs.S3ObjectId.value; break; }
  }
  if (result) break;
}
await b.close();
console.log(JSON.stringify({ s3_id: result }));
`, 180000);
    const data = JSON.parse(out);
    return data.s3_id || null;
  } catch (e) {
    console.log(`  Playwright 오류: ${e.message}`);
    return null;
  }
}

function promptSyncSimple(question) {
  process.stdout.write(question);
  let input = "";
  const buf = Buffer.alloc(1);
  while (true) {
    try {
      const bytesRead = readSync(0, buf, 0, 1);
      if (bytesRead === 0) break;
      const char = buf.toString("utf-8");
      if (char === "\n") break;
      if (char === "\r") continue;
      input += char;
    } catch { break; }
  }
  return input.trim();
}

function readEnvValueSimple(key) {
  if (!existsSync(".env")) return null;
  const lines = readFileSync(".env", "utf-8").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;
    const re = new RegExp(`^${key}\\s*=\\s*(.+)$`);
    const match = trimmed.match(re);
    if (match) return match[1].replace(/^["']|["']$/g, "").trim();
  }
  return null;
}

function downloadAndExtractToCache(name, version, id, url) {
  const cacheDir = `build/widgets/${name}`;
  if (!existsSync(cacheDir)) mkdirSync(cacheDir, { recursive: true });

  const tmpPath = `${cacheDir}/_tmp.mpk`;
  try {
    execSync(`curl -s -L -o "${tmpPath}" "${url}"`, { shell: true });
  } catch {
    console.log(`${name} — 다운로드 실패`);
    return false;
  }
  if (!existsSync(tmpPath)) {
    console.log(`${name} — 다운로드 실패`);
    return false;
  }

  try {
    const buf = readFileSync(tmpPath);
    const entries = listZipEntries(buf);

    // package.xml 저장
    try {
      writeFileSync(`${cacheDir}/package.xml`, readZipEntry(buf, "package.xml"));
    } catch {}

    // 위젯 XML 경로 추출 + 저장
    const pkgXml = readZipEntry(buf, "package.xml").toString("utf-8");
    const widgetFilePaths = extractAllWidgetFilePaths(pkgXml);
    for (const xmlPath of widgetFilePaths) {
      try {
        const xml = readZipEntry(buf, xmlPath);
        const fn = xmlPath.substring(xmlPath.lastIndexOf("/") + 1);
        writeFileSync(`${cacheDir}/${fn}`, xml);
      } catch {}
    }

    // .mjs 추출
    for (const entry of entries) {
      if (entry.endsWith(".mjs")) {
        try {
          const content = readZipEntry(buf, entry);
          const fn = entry.substring(entry.lastIndexOf("/") + 1);
          writeFileSync(`${cacheDir}/${fn}`, content);
        } catch {}
      }
    }

    // .css 추출 (editorPreview 제외)
    for (const entry of entries) {
      if (entry.endsWith(".css") && !entry.includes("editorPreview")) {
        try {
          const content = readZipEntry(buf, entry);
          const fn = entry.substring(entry.lastIndexOf("/") + 1);
          writeFileSync(`${cacheDir}/${fn}`, content);
        } catch {}
      }
    }

    // meta.json 기록
    const meta = { version };
    if (id != null) meta.id = id;
    writeFileSync(`${cacheDir}/meta.json`, JSON.stringify(meta, null, 2));

    try { unlinkSync(tmpPath); } catch {}
    console.log(`${name} v${version} — 캐시 완료`);
    return true;
  } catch (e) {
    console.log(`${name} — 추출 실패: ${e.message}`);
    try { unlinkSync(tmpPath); } catch {}
    return false;
  }
}

// gleam.toml [tools.glendix.widgets.*]에 등록된 위젯을 다운로드/캐시한다
export function resolve_toml_widgets() {
  const config = parseGlendixToml();
  if (!config?.widgets || Object.keys(config.widgets).length === 0) return;

  for (const [name, widget] of Object.entries(config.widgets)) {
    if (!widget.version) {
      console.log(`경고: ${name} 위젯에 version이 지정되지 않았습니다`);
      continue;
    }

    // 캐시 확인
    const metaPath = `build/widgets/${name}/meta.json`;
    if (existsSync(metaPath)) {
      try {
        const meta = JSON.parse(readFileSync(metaPath, "utf-8"));
        if (meta.version === widget.version) {
          console.log(`${name} v${widget.version} — 캐시 사용`);
          continue;
        }
      } catch {}
    }

    // s3_id 직접 다운로드
    if (widget.s3_id) {
      const url = `https://files.appstore.mendix.com/${widget.s3_id}`;
      downloadAndExtractToCache(name, widget.version, widget.id || null, url);
      continue;
    }

    // id 없으면 Content API 검색
    let contentId = widget.id;
    if (!contentId) {
      const pat = readEnvValueSimple("MENDIX_PAT");
      if (!pat) {
        console.log(`${name} — PAT 필요: .env에 MENDIX_PAT 설정`);
        continue;
      }
      contentId = searchContentByName(name, pat);
      if (!contentId) {
        console.log(`'${name}' 위젯을 찾을 수 없습니다`);
        continue;
      }
      writeTomlKey(`tools.glendix.widgets.${name}`, "id", contentId);
    }

    // Playwright 세션 + s3_id 확보
    if (!ensureSessionForResolve()) {
      console.log("로그인 실패");
      continue;
    }
    const s3_id = getS3IdForVersion(contentId, widget.version);
    if (!s3_id) {
      console.log(`'${name}' v${widget.version} s3_id 확보 실패`);
      continue;
    }

    // s3_id 저장 여부 확인
    const answer = promptSyncSimple(`  ${name}의 s3_id를 gleam.toml에 저장하시겠습니까? (y/n): `);
    if (answer.toLowerCase() === "y") {
      writeTomlKey(`tools.glendix.widgets.${name}`, "s3_id", s3_id);
    }

    // 다운로드 + 추출
    downloadAndExtractToCache(name, widget.version, contentId, `https://files.appstore.mendix.com/${s3_id}`);
  }
}

// gleam.toml에 위젯 항목을 쓰기/업데이트한다
export function write_widget_toml(name, version, id_option, s3_id_option) {
  const entries = [["version", version]];
  if (id_option instanceof Some) entries.push(["id", id_option[0]]);
  if (s3_id_option instanceof Some) entries.push(["s3_id", s3_id_option[0]]);

  const sectionPath = `tools.glendix.widgets.${name}`;
  const config = parseGlendixToml();
  const existing = config?.widgets?.[name];

  if (existing) {
    for (const [key, value] of entries) writeTomlKey(sectionPath, key, value);
  } else {
    writeTomlSection(sectionPath, entries);
  }
}

// .mpk를 다운로드하고 build/widgets/{name}/에 추출한다 (marketplace용)
export function download_to_cache(url, name, version, id_option) {
  const id = (id_option instanceof Some) ? id_option[0] : null;
  return downloadAndExtractToCache(name, version, id, url);
}

// gleam.toml의 [tools.glendix].pm 오버라이드를 읽는다
export function read_pm_override() {
  const config = parseGlendixToml();
  return config?.pm ? new Some(config.pm) : new None();
}

// gleam_erlang 패키지의 Unused value 경고 블록을 제거한다
function filterErlangWarnings(stderr) {
  const lines = stderr.split(/\r?\n/);
  const result = [];
  let skip = false;
  let skipNextEmpty = false;

  for (let i = 0; i < lines.length; i++) {
    if (!skip && lines[i] === "warning: Unused value") {
      if (i + 1 < lines.length && lines[i + 1].includes("gleam_erlang")) {
        skip = true;
        continue;
      }
    }
    if (skip) {
      if (lines[i].includes("not needed")) {
        skip = false;
        skipNextEmpty = true;
      }
      continue;
    }
    if (skipNextEmpty) {
      skipNextEmpty = false;
      if (lines[i].trim() === "") continue;
    }
    result.push(lines[i]);
  }

  return result.join("\n").replace(/\n{3,}/g, "\n\n").trim();
}

// gleam_erlang의 Unused value 경고를 필터링하여 gleam 명령을 실행한다
function execGleamFiltered(command) {
  const result = spawnSync(command, { shell: true, stdio: ["inherit", "pipe", "pipe"] });
  if (result.stdout && result.stdout.length > 0) process.stdout.write(result.stdout);
  if (result.stderr && result.stderr.length > 0) {
    const filtered = filterErlangWarnings(result.stderr.toString());
    if (filtered) process.stderr.write(filtered + "\n");
  }
  if (result.status !== 0) {
    const err = new Error("Command failed: " + command);
    err.status = result.status;
    throw err;
  }
}

export function exec(command) {
  if (command.startsWith("gleam ")) {
    execGleamFiltered(command);
  } else {
    execSync(command, { stdio: "inherit", shell: true });
  }
}

export function file_exists(path) {
  return existsSync(path);
}


// bindings.json → binding_ffi.mjs 생성
// glendix 빌드 경로에 직접 생성하여 사용자가 .mjs를 작성하지 않아도 되게 한다
export function generate_bindings() {
  const tomlConfig = parseGlendixToml();
  let config;

  if (tomlConfig?.bindings && Object.keys(tomlConfig.bindings).length > 0) {
    config = {};
    for (const [pkg, components] of Object.entries(tomlConfig.bindings)) {
      config[pkg] = { components: Array.isArray(components) ? components : [components] };
    }
    if (existsSync("bindings.json")) {
      console.log("경고: gleam.toml에 bindings 설정이 있으므로 bindings.json은 무시됩니다");
    }
  } else if (existsSync("bindings.json")) {
    try {
      config = JSON.parse(readFileSync("bindings.json", "utf-8"));
    } catch (e) {
      console.log("bindings.json 파싱 실패: " + e.message);
      return;
    }
  } else {
    return;
  }

  const imports = [];
  const entries = [];

  for (const [moduleName, entry] of Object.entries(config)) {
    const components = entry.components || [];
    if (components.length === 0) continue;

    imports.push(`import { ${components.join(", ")} } from "${moduleName}";`);
    entries.push(`  "${moduleName}": { ${components.join(", ")} }`);
  }

  if (imports.length === 0) return;

  const content =
    `// @generated glendix/install — 직접 수정 금지\n` +
    imports.join("\n") +
    "\n\n" +
    `const _modules = {\n${entries.join(",\n")}\n};\n\n` +
    `export function get_module(name) {\n` +
    `  const mod = _modules[name];\n` +
    `  if (!mod) throw new Error("바인딩에 등록되지 않은 모듈: " + name + ". gleam.toml [tools.glendix.bindings] 또는 bindings.json을 확인하세요.");\n` +
    `  return mod;\n` +
    `}\n\n` +
    `export function resolve(mod, name) {\n` +
    `  const c = mod[name];\n` +
    `  if (c === undefined) throw new Error("모듈에 없는 컴포넌트: " + name);\n` +
    `  return c;\n` +
    `}\n`;

  // glendix 빌드 경로에 생성 (gleam build 시 복사되는 소스 + 즉시 사용 가능한 출력)
  const targets = [
    "build/packages/glendix/src/glendix/binding_ffi.mjs",
    "build/dev/javascript/glendix/glendix/binding_ffi.mjs",
  ];

  let written = 0;
  for (const target of targets) {
    const dir = target.substring(0, target.lastIndexOf("/"));
    if (!existsSync(dir)) {
      try {
        mkdirSync(dir, { recursive: true });
      } catch {
        continue;
      }
    }
    writeFileSync(target, content);
    written++;
  }

  if (written > 0) {
    const moduleNames = Object.keys(config).join(", ");
    console.log(`바인딩 생성 완료: ${moduleNames}`);
  }
}

// ZIP 엔트리 목록을 반환한다 (Central Directory 기반)
function listZipEntries(buf) {
  let eocdOff = -1;
  for (let i = buf.length - 22; i >= 0; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocdOff = i; break; }
  }
  if (eocdOff === -1) throw new Error("EOCD를 찾을 수 없습니다");

  const cdOff = buf.readUInt32LE(eocdOff + 16);
  const totalEntries = buf.readUInt16LE(eocdOff + 10);
  const entries = [];
  let off = cdOff;

  for (let i = 0; i < totalEntries; i++) {
    const nameLen = buf.readUInt16LE(off + 28);
    const extraLen = buf.readUInt16LE(off + 30);
    const commentLen = buf.readUInt16LE(off + 32);
    entries.push(buf.toString("utf-8", off + 46, off + 46 + nameLen));
    off += 46 + nameLen + extraLen + commentLen;
  }

  return entries;
}

// ZIP에서 특정 파일의 내용을 읽는다 (deflate/store 지원)
function readZipEntry(buf, fileName) {
  let eocdOff = -1;
  for (let i = buf.length - 22; i >= 0; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocdOff = i; break; }
  }
  if (eocdOff === -1) throw new Error("EOCD를 찾을 수 없습니다");

  const cdOff = buf.readUInt32LE(eocdOff + 16);
  const totalEntries = buf.readUInt16LE(eocdOff + 10);
  let off = cdOff;

  for (let i = 0; i < totalEntries; i++) {
    const nameLen = buf.readUInt16LE(off + 28);
    const extraLen = buf.readUInt16LE(off + 30);
    const commentLen = buf.readUInt16LE(off + 32);
    const name = buf.toString("utf-8", off + 46, off + 46 + nameLen);
    const method = buf.readUInt16LE(off + 10);
    const compSize = buf.readUInt32LE(off + 20);
    const localOff = buf.readUInt32LE(off + 42);

    if (name === fileName) {
      const localNameLen = buf.readUInt16LE(localOff + 26);
      const localExtraLen = buf.readUInt16LE(localOff + 28);
      const dataOff = localOff + 30 + localNameLen + localExtraLen;
      const raw = buf.subarray(dataOff, dataOff + compSize);

      if (method === 0) return raw;
      if (method === 8) return inflateRawSync(raw);
      throw new Error("지원하지 않는 압축 방식: " + method);
    }

    off += 46 + nameLen + extraLen + commentLen;
  }

  throw new Error("ZIP 엔트리를 찾을 수 없습니다: " + fileName);
}

// XML 문자열에서 <name>...</name> 추출
function parseWidgetName(xmlString) {
  const match = xmlString.match(/<name>([^<]+)<\/name>/);
  return match ? match[1] : null;
}

// 위젯 이름을 유효한 JS 식별자로 변환한다 ("Progress Bar" → "ProgressBar")
function toSafeIdentifier(name) {
  return name.replace(/[^a-zA-Z0-9_$]/g, "");
}

// 위젯 XML에서 속성 정보(key, required)를 파싱한다
function parseProperties(widgetXml) {
  const properties = [];
  const regex = /<property\s+([^>]*)(?:\/>|>[\s\S]*?<\/property>)/g;
  let match;
  while ((match = regex.exec(widgetXml)) !== null) {
    const attrs = match[1];
    const keyMatch = attrs.match(/key="([^"]+)"/);
    const requiredMatch = attrs.match(/required="([^"]+)"/);
    if (keyMatch) {
      properties.push({
        key: keyMatch[1],
        required: requiredMatch ? requiredMatch[1] === "true" : false,
      });
    }
  }
  return properties;
}

// default export가 존재하는지 판별한다
function hasDefaultExport(src) {
  return /\bexport\s+default\b/.test(src) ||
    /\bexport\s*\{[^}]*\bas\s+default\b/.test(src);
}

// 첫 번째 named export 이름을 추출한다
function findNamedExport(src) {
  // export { Name, ... } — "as default" 항목 제외
  const blockMatch = src.match(/\bexport\s*\{([^}]+)\}/);
  if (blockMatch) {
    for (const entry of blockMatch[1].split(",")) {
      const parts = entry.trim().split(/\s+as\s+/);
      const name = parts.length === 2 ? parts[1].trim() : parts[0].trim();
      if (name && name !== "default") return name;
    }
  }
  // export const/let/var/function/class Name
  const declMatch = src.match(/\bexport\s+(?:const|let|var|function|class)\s+(\w+)/);
  if (declMatch) return declMatch[1];
  return null;
}

// camelCase → snake_case 변환
function toSnakeCase(str) {
  return str
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1_$2")
    .toLowerCase();
}

// 위젯 이름 → Gleam 모듈 파일명 ("Progress Bar" → "progress_bar", "Switch" → "switch")
function toModuleFileName(name) {
  return name
    .replace(/\s+/g, "_")
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1_$2")
    .toLowerCase();
}

const GLEAM_KEYWORDS = new Set([
  "as", "assert", "auto", "case", "const", "delegate", "derive", "echo",
  "else", "fn", "if", "implement", "import", "let", "macro", "opaque",
  "panic", "pub", "return", "test", "todo", "type", "use",
]);

// 속성 key를 Gleam 변수명으로 변환 (snake_case + 예약어 회피)
function toGleamVar(key) {
  const snake = toSnakeCase(key);
  return GLEAM_KEYWORDS.has(snake) ? snake + "_" : snake;
}

// .mpk 위젯의 .gleam 바인딩 파일을 src/widgets/에 생성한다
function generateWidgetGleamFile(widgetName, widgetXml) {
  const props = parseProperties(widgetXml);
  if (props.length === 0) return;

  const requiredProps = props.filter((p) => p.required);
  const optionalProps = props.filter((p) => !p.required);
  const hasOptional = optionalProps.length > 0;
  const moduleFileName = toModuleFileName(widgetName);
  const filePath = `src/widgets/${moduleFileName}.gleam`;

  // 이미 존재하면 덮어쓰지 않는다
  if (existsSync(filePath)) return;

  // 디렉토리 생성
  if (!existsSync("src/widgets")) {
    mkdirSync("src/widgets", { recursive: true });
  }

  // import 섹션
  let imports = "";
  if (hasOptional) {
    imports += "import gleam/option.{None, Some}\n";
  }
  imports += "import glendix/mendix.{type JsProps}\n";
  imports += "import redraw.{type Element}\n";
  imports += "import redraw/dom/attribute\n";
  imports += "import glendix/interop\n";
  imports += "import glendix/widget\n";

  // render 함수 본문
  let body = "";
  for (const prop of requiredProps) {
    body += `  let ${toGleamVar(prop.key)} = mendix.get_prop_required(props, "${prop.key}")\n`;
  }

  body += `\n  let comp = widget.component("${widgetName}")\n`;
  body += "  interop.component_el(\n    comp,\n    [\n";

  for (const prop of requiredProps) {
    body += `      attribute.attribute("${prop.key}", ${toGleamVar(prop.key)}),\n`;
  }
  for (const prop of optionalProps) {
    body += `      optional_attr(props, "${prop.key}"),\n`;
  }

  body += "    ],\n    [],\n  )\n";

  // 파일 내용 조합
  let content = `// ${widgetName} 위젯 바인딩 컴포넌트\n\n`;
  content += imports;
  content += "\n";
  content += `/// ${widgetName} 위젯 렌더링 - props에서 속성을 읽어 위젯에 전달\n`;
  content += "pub fn render(props: JsProps) -> Element {\n";
  content += body;
  content += "}\n";

  if (hasOptional) {
    content += "\n";
    content += "/// optional prop을 조건부 attribute로 변환\n";
    content += "fn optional_attr(props: JsProps, key: String) -> attribute.Attribute {\n";
    content += "  case mendix.get_prop(props, key) {\n";
    content += "    Some(val) -> attribute.attribute(key, val)\n";
    content += "    None -> attribute.none()\n";
    content += "  }\n";
    content += "}\n";
  }

  writeFileSync(filePath, content);
  console.log(`위젯 바인딩 Gleam 파일 생성: ${filePath}`);
}

// Classic .mpk 감지 — .mjs 파일이 없으면 Classic (Dojo) 위젯
// Pluggable 위젯은 항상 .mjs를 포함하고, Classic은 .js만 포함한다
function isClassicMpk(buf, entries) {
  try {
    return !entries.some(e => e.endsWith(".mjs"));
  } catch {
    return false;
  }
}

// package.xml에서 모든 widgetFile path를 추출한다
function extractAllWidgetFilePaths(packageXml) {
  const paths = [];
  const regex = /widgetFile\s+path="([^"]+)"/g;
  let match;
  while ((match = regex.exec(packageXml)) !== null) {
    paths.push(match[1]);
  }
  return paths;
}

// 위젯 XML의 widget id="..." 속성에서 .mjs 파일 경로를 추론한다
// 예: id="com.mendix.widget.web.areachart.AreaChart" → "com/mendix/widget/web/areachart/AreaChart.mjs"
function findWidgetMjsEntry(widgetXml, entries) {
  const idMatch = widgetXml.match(/widget\s+[^>]*id="([^"]+)"/);
  if (!idMatch) return null;
  const expectedPath = idMatch[1].replace(/\./g, "/") + ".mjs";
  return entries.find(e => e === expectedPath) || null;
}

// 위젯 XML의 widget id="..." 속성에서 .css 파일 경로를 추론한다
function findWidgetCssEntry(widgetXml, entries) {
  const idMatch = widgetXml.match(/widget\s+[^>]*id="([^"]+)"/);
  if (!idMatch) return null;
  const expectedPath = idMatch[1].replace(/\./g, "/") + ".css";
  return entries.find(e => e === expectedPath) || null;
}

// 위젯 디렉토리 외의 공유 .mjs/.css 파일을 식별한다
function findSharedFiles(entries, widgetMjsPaths) {
  const widgetDirs = new Set();
  for (const mjsPath of widgetMjsPaths) {
    const dir = mjsPath.substring(0, mjsPath.lastIndexOf("/") + 1);
    widgetDirs.add(dir);
  }

  return entries.filter(e => {
    if (e.endsWith("/")) return false;
    if (!e.endsWith(".mjs") && !e.endsWith(".css")) return false;
    // 위젯 디렉토리에 속하지 않는 파일만 공유 의존성으로 취급
    for (const dir of widgetDirs) {
      if (e.startsWith(dir)) return false;
    }
    return true;
  });
}

// Classic 위젯 에셋 추출
function extractClassicWidget(buf, entries) {
  const packageXml = readZipEntry(buf, "package.xml").toString("utf-8");

  // widgetFile path에서 위젯 XML 경로 추출
  const widgetFileMatch = packageXml.match(/widgetFile\s+path="([^"]+)"/);
  if (!widgetFileMatch) return null;

  const widgetXmlPath = widgetFileMatch[1];
  let widgetXml;
  try {
    widgetXml = readZipEntry(buf, widgetXmlPath).toString("utf-8");
  } catch {
    return null;
  }

  // 위젯 이름
  const name = parseWidgetName(widgetXml);
  if (!name) return null;

  // 위젯 ID (widget id="..." 속성)
  const idMatch = widgetXml.match(/widget\s+[^>]*id="([^"]+)"/);
  const widgetId = idMatch ? idMatch[1] : null;
  if (!widgetId) return null;

  // 속성 파싱
  const properties = parseProperties(widgetXml);

  // 파일 분류
  const jsFiles = {};
  const templateFiles = {};
  let css = "";
  const libFiles = {};

  for (const entry of entries) {
    if (entry.endsWith("/") || entry === "package.xml" || entry === widgetXmlPath) continue;

    try {
      const content = readZipEntry(buf, entry);

      if (entry.endsWith(".js")) {
        if (entry.includes("/lib/")) {
          libFiles[entry] = content.toString("utf-8");
        } else {
          jsFiles[entry] = content.toString("utf-8");
        }
      } else if (entry.endsWith(".html")) {
        templateFiles[entry] = content.toString("utf-8");
      } else if (entry.endsWith(".css")) {
        css += content.toString("utf-8") + "\n";
      }
    } catch {
      // 추출 실패한 파일은 무시
    }
  }

  return { name, widgetId, widgetXml, jsFiles, templateFiles, css: css.trim(), libFiles, properties };
}

// Classic 위젯의 .gleam 바인딩 파일을 src/widgets/에 생성한다
function generateClassicGleamFile(widgetName, widgetId, properties) {
  const moduleFileName = toModuleFileName(widgetName);
  const filePath = `src/widgets/${moduleFileName}.gleam`;

  // 이미 존재하면 덮어쓰지 않는다
  if (existsSync(filePath)) return;

  // 디렉토리 생성
  if (!existsSync("src/widgets")) {
    mkdirSync("src/widgets", { recursive: true });
  }

  const requiredProps = properties.filter((p) => p.required);
  const optionalProps = properties.filter((p) => !p.required);
  const hasOptional = optionalProps.length > 0;

  // import 섹션
  let imports = "";
  if (hasOptional) {
    imports += "import gleam/dynamic\n";
    imports += "import gleam/option.{None, Some}\n";
  }
  imports += "import glendix/classic\n";
  imports += "import glendix/mendix.{type JsProps}\n";
  imports += "import redraw.{type Element}\n";

  // render 함수 본문
  let body = "";
  for (const prop of requiredProps) {
    body += `  let ${toGleamVar(prop.key)} = mendix.get_prop_required(props, "${prop.key}")\n`;
  }

  body += `\n  classic.render("${widgetId}", [\n`;

  for (const prop of requiredProps) {
    body += `    #("${prop.key}", classic.to_dynamic(${toGleamVar(prop.key)})),\n`;
  }
  for (const prop of optionalProps) {
    body += `    optional_prop(props, "${prop.key}"),\n`;
  }

  body += "  ])\n";

  // 파일 내용 조합
  let content = `// ${widgetName} Classic 위젯 바인딩 컴포넌트\n\n`;
  content += imports;
  content += "\n";
  content += `/// ${widgetName} Classic 위젯 렌더링\n`;
  content += "pub fn render(props: JsProps) -> Element {\n";
  content += body;
  content += "}\n";

  if (hasOptional) {
    content += "\n";
    content += "/// optional prop을 #(key, Dynamic) 튜플로 변환\n";
    content += "fn optional_prop(props: JsProps, key: String) -> #(String, dynamic.Dynamic) {\n";
    content += "  case mendix.get_prop(props, key) {\n";
    content += "    Some(val) -> #(key, classic.to_dynamic(val))\n";
    content += "    None -> #(key, classic.to_dynamic(Nil))\n";
    content += "  }\n";
    content += "}\n";
  }

  writeFileSync(filePath, content);
  console.log(`Classic 위젯 바인딩 Gleam 파일 생성: ${filePath}`);
}

// JS 문자열을 이스케이프한다 (템플릿 리터럴용)
function escapeForTemplate(str) {
  return str.replace(/\\/g, "\\\\").replace(/`/g, "\\`").replace(/\$/g, "\\$");
}

// classic_ffi.mjs 생성
function generateClassicFfi(classicWidgets) {
  if (classicWidgets.length === 0) return;

  // 위젯 에셋 데이터 구조체
  const widgetEntries = [];
  for (const w of classicWidgets) {
    const jsEntries = Object.entries(w.jsFiles)
      .map(([path, code]) => `      "${path}": \`${escapeForTemplate(code)}\``)
      .join(",\n");
    const templateEntries = Object.entries(w.templateFiles)
      .map(([path, html]) => `      "${path}": \`${escapeForTemplate(html)}\``)
      .join(",\n");
    const libEntries = Object.entries(w.libFiles)
      .map(([path, code]) => `      "${path}": \`${escapeForTemplate(code)}\``)
      .join(",\n");

    widgetEntries.push(
      `  "${w.safeId}": {\n` +
      `    widgetId: "${w.widgetId}",\n` +
      `    js: {\n${jsEntries}\n    },\n` +
      `    templates: {\n${templateEntries}\n    },\n` +
      `    css: \`${escapeForTemplate(w.css)}\`,\n` +
      `    libs: {\n${libEntries}\n    },\n` +
      `  }`,
    );
  }

  const content =
    `// @generated glendix/install — 직접 수정 금지\n` +
    `import * as React from "react";\n\n` +

    `const _classicWidgets = {\n${widgetEntries.join(",\n")}\n};\n\n` +

    // CSS 주입 (한 번만)
    `const _injectedCss = new Set();\n` +
    `function injectCss(name, css) {\n` +
    `  if (!css || _injectedCss.has(name)) return;\n` +
    `  _injectedCss.add(name);\n` +
    `  const style = document.createElement("style");\n` +
    `  style.setAttribute("data-classic-widget", name);\n` +
    `  style.textContent = css;\n` +
    `  document.head.appendChild(style);\n` +
    `}\n\n` +

    // AMD 모듈 등록 (script tag injection)
    `const _registeredModules = new Set();\n` +
    `function registerAmdModules(widget) {\n` +
    `  // lib 파일 먼저 등록\n` +
    `  for (const [path, code] of Object.entries(widget.libs)) {\n` +
    `    const moduleId = path.replace(/\\.js$/, "");\n` +
    `    if (_registeredModules.has(moduleId)) continue;\n` +
    `    _registeredModules.add(moduleId);\n` +
    `    const script = document.createElement("script");\n` +
    `    script.textContent = code;\n` +
    `    document.head.appendChild(script);\n` +
    `  }\n` +
    `  // 위젯 JS 파일 등록\n` +
    `  for (const [path, code] of Object.entries(widget.js)) {\n` +
    `    const moduleId = path.replace(/\\.js$/, "");\n` +
    `    if (_registeredModules.has(moduleId)) continue;\n` +
    `    _registeredModules.add(moduleId);\n` +
    `    const script = document.createElement("script");\n` +
    `    script.textContent = code;\n` +
    `    document.head.appendChild(script);\n` +
    `  }\n` +
    `}\n\n` +

    // Template 캐시 등록
    `function registerTemplates(widget) {\n` +
    `  if (typeof window.require === "undefined" || !window.require.cache) return;\n` +
    `  for (const [path, html] of Object.entries(widget.templates)) {\n` +
    `    const cacheKey = "url:dojo/text!" + path;\n` +
    `    if (!window.require.cache[cacheKey]) {\n` +
    `      window.require.cache[cacheKey] = html;\n` +
    `    }\n` +
    `  }\n` +
    `}\n\n` +

    // Classic 위젯 마운트
    `function mountClassicWidget(widgetId, container, properties) {\n` +
    `  // 위젯 이름에서 에셋 키 추출 ("CameraWidget.widget.CameraWidget" → "CameraWidget")\n` +
    `  const assetKey = widgetId.split(".")[0];\n` +
    `  const widget = _classicWidgets[assetKey];\n` +
    `  if (!widget) {\n` +
    `    console.error("Classic 위젯을 찾을 수 없습니다: " + assetKey);\n` +
    `    return Promise.resolve(null);\n` +
    `  }\n\n` +
    `  // 에셋 등록\n` +
    `  injectCss(assetKey, widget.css);\n` +
    `  registerTemplates(widget);\n` +
    `  registerAmdModules(widget);\n\n` +
    `  // AMD require로 위젯 모듈 로드\n` +
    `  return new Promise((resolve) => {\n` +
    `    if (typeof window.require !== "function") {\n` +
    `      console.error("AMD 로더(window.require)가 없습니다. Mendix 런타임 내에서 실행하세요.");\n` +
    `      resolve(null);\n` +
    `      return;\n` +
    `    }\n` +
    `    window.require([widgetId], (WidgetClass) => {\n` +
    `      try {\n` +
    `        const props = {};\n` +
    `        for (const [key, value] of properties) {\n` +
    `          props[key] = value;\n` +
    `        }\n` +
    `        const instance = new WidgetClass(props, container);\n` +
    `        if (typeof instance.startup === "function") instance.startup();\n` +
    `        resolve(instance);\n` +
    `      } catch (e) {\n` +
    `        console.error("Classic 위젯 마운트 실패: " + e.message);\n` +
    `        resolve(null);\n` +
    `      }\n` +
    `    }, (err) => {\n` +
    `      console.error("Classic 위젯 AMD 로드 실패: " + err);\n` +
    `      resolve(null);\n` +
    `    });\n` +
    `  });\n` +
    `}\n\n` +

    // React 래퍼 컴포넌트
    `function ClassicWidgetWrapper({ widgetId, properties, className }) {\n` +
    `  const containerRef = React.useRef(null);\n` +
    `  const instanceRef = React.useRef(null);\n\n` +
    `  React.useEffect(() => {\n` +
    `    if (!containerRef.current) return;\n` +
    `    let cancelled = false;\n\n` +
    `    mountClassicWidget(widgetId, containerRef.current, properties).then((inst) => {\n` +
    `      if (cancelled) {\n` +
    `        if (inst) destroyWidget(inst);\n` +
    `        return;\n` +
    `      }\n` +
    `      instanceRef.current = inst;\n` +
    `    });\n\n` +
    `    return () => {\n` +
    `      cancelled = true;\n` +
    `      if (instanceRef.current) {\n` +
    `        destroyWidget(instanceRef.current);\n` +
    `        instanceRef.current = null;\n` +
    `      }\n` +
    `    };\n` +
    `  }, [widgetId]);\n\n` +
    `  return React.createElement("div", { ref: containerRef, className: className || undefined });\n` +
    `}\n\n` +

    `function destroyWidget(instance) {\n` +
    `  try {\n` +
    `    if (typeof instance.uninitialize === "function") instance.uninitialize();\n` +
    `    if (typeof instance.destroyRecursive === "function") instance.destroyRecursive();\n` +
    `    else if (typeof instance.destroy === "function") instance.destroy();\n` +
    `  } catch {}\n` +
    `}\n\n` +

    `const MemoizedWrapper = React.memo(ClassicWidgetWrapper);\n\n` +

    // 공개 API
    `export function classic_widget_element(widget_id, properties) {\n` +
    `  const props = properties.toArray();\n` +
    `  return React.createElement(MemoizedWrapper, {\n` +
    `    widgetId: widget_id,\n` +
    `    properties: props,\n` +
    `  });\n` +
    `}\n\n` +

    `export function classic_widget_element_with_class(widget_id, properties, class_name) {\n` +
    `  const props = properties.toArray();\n` +
    `  return React.createElement(MemoizedWrapper, {\n` +
    `    widgetId: widget_id,\n` +
    `    properties: props,\n` +
    `    className: class_name,\n` +
    `  });\n` +
    `}\n`;

  // 빌드 경로에 쓰기
  const basePaths = [
    "build/packages/glendix/src/glendix",
    "build/dev/javascript/glendix/glendix",
  ];

  let written = 0;
  for (const base of basePaths) {
    try {
      if (!existsSync(base)) {
        try {
          mkdirSync(base, { recursive: true });
        } catch {
          continue;
        }
      }
      writeFileSync(`${base}/classic_ffi.mjs`, content);
      written++;
    } catch {
      continue;
    }
  }

  if (written > 0) {
    const names = classicWidgets.map((w) => w.name).join(", ");
    console.log(`Classic 위젯 바인딩 생성 완료: ${names}`);
  }
}

// widgets/ 디렉토리의 .mpk + build/widgets/ 캐시에서 위젯 바인딩을 생성한다
export function generate_widget_bindings() {
  const hasWidgetsDir = existsSync("widgets");
  const hasCacheDir = existsSync("build/widgets");
  if (!hasWidgetsDir && !hasCacheDir) return;

  const widgets = []; // pluggable: { name, safeId, mjsContent, cssContent, mjsZipPath?, cssZipPath?, isMultiWidget? }
  const classicWidgets = []; // classic: { name, safeId, widgetId, jsFiles, templateFiles, css, libFiles }
  const mpkSharedFiles = []; // multi-widget MPK 공유 의존성: { zipPath, content }
  const processedNames = new Set();

  // ── build/widgets/ 캐시에서 읽기 (TOML 기반, 우선) ──
  if (hasCacheDir) {
    try {
      const cacheDirs = readdirSync("build/widgets");
      for (const dirName of cacheDirs) {
        const cacheDir = `build/widgets/${dirName}`;
        try {
          if (!statSync(cacheDir).isDirectory()) continue;
        } catch { continue; }
        const metaPath = `${cacheDir}/meta.json`;
        if (!existsSync(metaPath)) continue;

        const files = readdirSync(cacheDir);
        const mjsFile = files.find(f => f.endsWith(".mjs"));
        if (!mjsFile) continue;

        const mjsContent = readFileSync(`${cacheDir}/${mjsFile}`);
        const cssFile = files.find(f => f.endsWith(".css") && !f.includes("editorPreview"));
        const cssContent = cssFile ? readFileSync(`${cacheDir}/${cssFile}`) : null;

        const xmlFile = files.find(f => f.endsWith(".xml") && f !== "package.xml");
        let widgetName = dirName;
        if (xmlFile) {
          const widgetXml = readFileSync(`${cacheDir}/${xmlFile}`, "utf-8");
          const parsed = parseWidgetName(widgetXml);
          if (parsed) widgetName = parsed;
          generateWidgetGleamFile(widgetName, widgetXml);
        }

        const safeId = toSafeIdentifier(widgetName);
        widgets.push({ name: widgetName, safeId, mjsContent, cssContent });
        processedNames.add(widgetName);
      }
    } catch {}
  }

  // ── widgets/*.mpk에서 읽기 (기존 로직, 캐시에 없는 위젯만) ──
  let mpkFiles = [];
  if (hasWidgetsDir) {
    try {
      mpkFiles = readdirSync("widgets").filter((f) => f.endsWith(".mpk"));
    } catch {}
  }

  if (mpkFiles.length === 0 && widgets.length === 0) return;

  for (const mpkFile of mpkFiles) {
    try {
      const buf = readFileSync(`widgets/${mpkFile}`);
      const entries = listZipEntries(buf);

      // Classic .mpk 감지 — .mjs가 없으면 Classic (Dojo) 위젯
      if (isClassicMpk(buf, entries)) {
        const classic = extractClassicWidget(buf, entries);
        if (!classic) {
          console.log(`경고: ${mpkFile} Classic 위젯 추출 실패`);
          continue;
        }
        if (processedNames.has(classic.name)) continue;

        // Classic .gleam 바인딩 생성
        generateClassicGleamFile(classic.name, classic.widgetId, classic.properties);

        const safeId = toSafeIdentifier(classic.name);
        classicWidgets.push({
          name: classic.name,
          safeId,
          widgetId: classic.widgetId,
          jsFiles: classic.jsFiles,
          templateFiles: classic.templateFiles,
          css: classic.css,
          libFiles: classic.libFiles,
        });
        continue;
      }

      // ── Pluggable 위젯 처리 ──

      // package.xml에서 모든 위젯 파일 경로 추출
      const packageXml = readZipEntry(buf, "package.xml").toString("utf-8");
      const widgetFilePaths = extractAllWidgetFilePaths(packageXml);
      if (widgetFilePaths.length === 0) {
        console.log(`경고: ${mpkFile}에서 widgetFile을 찾을 수 없습니다`);
        continue;
      }

      if (widgetFilePaths.length === 1) {
        // ── 단일 위젯 (기존 로직 유지) ──
        const widgetXmlPath = widgetFilePaths[0];
        const widgetXml = readZipEntry(buf, widgetXmlPath).toString("utf-8");
        const widgetName = parseWidgetName(widgetXml);
        if (!widgetName) {
          console.log(`경고: ${mpkFile}에서 위젯 이름을 찾을 수 없습니다`);
          continue;
        }
        if (processedNames.has(widgetName)) continue;

        const mjsEntry = entries.find((e) => e.endsWith(".mjs"));
        if (!mjsEntry) {
          console.log(`경고: ${mpkFile}에서 .mjs 파일을 찾을 수 없습니다`);
          continue;
        }

        const cssEntry = entries.find(
          (e) => e.endsWith(".css") && !e.includes("editorPreview"),
        );

        const mjsContent = readZipEntry(buf, mjsEntry);
        const cssContent = cssEntry ? readZipEntry(buf, cssEntry) : null;

        generateWidgetGleamFile(widgetName, widgetXml);

        const safeId = toSafeIdentifier(widgetName);
        widgets.push({ name: widgetName, safeId, mjsContent, cssContent });

      } else {
        // ── 다중 위젯 (multi-widget MPK) ──
        const widgetMjsPaths = [];

        for (const widgetXmlPath of widgetFilePaths) {
          let widgetXml;
          try {
            widgetXml = readZipEntry(buf, widgetXmlPath).toString("utf-8");
          } catch {
            console.log(`경고: ${mpkFile}에서 ${widgetXmlPath}를 읽을 수 없습니다`);
            continue;
          }

          const widgetName = parseWidgetName(widgetXml);
          if (!widgetName) {
            console.log(`경고: ${mpkFile}의 ${widgetXmlPath}에서 위젯 이름을 찾을 수 없습니다`);
            continue;
          }
          if (processedNames.has(widgetName)) continue;

          const mjsEntry = findWidgetMjsEntry(widgetXml, entries);
          if (!mjsEntry) {
            console.log(`경고: ${mpkFile}의 ${widgetName}에서 .mjs 파일을 찾을 수 없습니다`);
            continue;
          }

          const cssEntry = findWidgetCssEntry(widgetXml, entries);

          const mjsContent = readZipEntry(buf, mjsEntry);
          const cssContent = cssEntry ? readZipEntry(buf, cssEntry) : null;

          generateWidgetGleamFile(widgetName, widgetXml);

          // .mjs 파일명에서 실제 JS export 이름을 추출한다
          // 예: "com/mendix/widget/web/areachart/AreaChart.mjs" → "AreaChart"
          const mjsBaseName = mjsEntry.substring(mjsEntry.lastIndexOf("/") + 1).replace(/\.mjs$/, "");
          const safeId = mjsBaseName;
          widgetMjsPaths.push(mjsEntry);
          widgets.push({
            name: widgetName,
            safeId,
            mjsContent,
            cssContent,
            mjsZipPath: mjsEntry,
            cssZipPath: cssEntry,
            isMultiWidget: true,
          });
        }

        // 공유 의존성 파일 수집
        const sharedFiles = findSharedFiles(entries, widgetMjsPaths);
        for (const sharedPath of sharedFiles) {
          try {
            const content = readZipEntry(buf, sharedPath);
            mpkSharedFiles.push({ zipPath: sharedPath, content });
          } catch {
            // 추출 실패한 파일은 무시
          }
        }
      }
    } catch (e) {
      console.log(`경고: ${mpkFile} 처리 실패: ${e.message}`);
    }
  }

  // Pluggable 위젯 바인딩 (widget_ffi.mjs)
  if (widgets.length > 0) {
    const cssImports = widgets
      .filter((w) => w.cssContent)
      .map((w) => w.isMultiWidget
        ? `import "./widgets/${w.cssZipPath}";`
        : `import "./widgets/${w.safeId}.css";`)
      .join("\n");
    const mjsImports = widgets
      .map((w) => {
        const src = w.mjsContent ? w.mjsContent.toString("utf8") : "";
        const path = w.isMultiWidget
          ? `./widgets/${w.mjsZipPath}`
          : `./widgets/${w.safeId}.mjs`;
        if (hasDefaultExport(src)) {
          return `import ${w.safeId} from "${path}";`;
        }
        const exportName = findNamedExport(src);
        if (exportName && exportName !== w.safeId) {
          return `import { ${exportName} as ${w.safeId} } from "${path}";`;
        }
        if (exportName) {
          return `import { ${w.safeId} } from "${path}";`;
        }
        return `import ${w.safeId} from "${path}";`;
      })
      .join("\n");
    const widgetEntries = widgets
      .map((w) => `  "${w.name}": ${w.safeId}`)
      .join(",\n");

    const content =
      `// @generated glendix/install — 직접 수정 금지\n` +
      (cssImports ? cssImports + "\n" : "") +
      mjsImports +
      "\n\n" +
      `const _widgets = {\n${widgetEntries}\n};\n\n` +
      `export function get_widget(name) {\n` +
      `  const w = _widgets[name];\n` +
      `  if (!w) throw new Error("위젯 바인딩에 등록되지 않은 위젯: " + name + ". widgets/ 디렉토리를 확인하세요.");\n` +
      `  return w;\n` +
      `}\n`;

    // 빌드 경로에 쓰기
    const basePaths = [
      "build/packages/glendix/src/glendix",
      "build/dev/javascript/glendix/glendix",
    ];

    let written = 0;
    for (const base of basePaths) {
      try {
        // widget_ffi.mjs
        const dir = base;
        if (!existsSync(dir)) {
          try {
            mkdirSync(dir, { recursive: true });
          } catch {
            continue;
          }
        }
        writeFileSync(`${base}/widget_ffi.mjs`, content);

        // widgets/ 서브 디렉토리
        const widgetsDir = `${base}/widgets`;
        if (!existsSync(widgetsDir)) {
          mkdirSync(widgetsDir, { recursive: true });
        }

        for (const w of widgets) {
          if (w.isMultiWidget) {
            // 다중 위젯: ZIP 경로 구조 유지
            const mjsDir = `${widgetsDir}/${w.mjsZipPath.substring(0, w.mjsZipPath.lastIndexOf("/"))}`;
            mkdirSync(mjsDir, { recursive: true });
            writeFileSync(`${widgetsDir}/${w.mjsZipPath}`, w.mjsContent);
            if (w.cssContent && w.cssZipPath) {
              writeFileSync(`${widgetsDir}/${w.cssZipPath}`, w.cssContent);
            }
          } else {
            // 단일 위젯: 플랫 구조
            writeFileSync(`${widgetsDir}/${w.safeId}.mjs`, w.mjsContent);
            if (w.cssContent) {
              writeFileSync(`${widgetsDir}/${w.safeId}.css`, w.cssContent);
            }
          }
        }

        // 공유 의존성 파일 추출 (디렉토리 구조 유지)
        for (const sf of mpkSharedFiles) {
          const sfPath = `${widgetsDir}/${sf.zipPath}`;
          const sfDir = sfPath.substring(0, sfPath.lastIndexOf("/"));
          mkdirSync(sfDir, { recursive: true });
          writeFileSync(sfPath, sf.content);
        }

        written++;
      } catch {
        continue;
      }
    }

    if (written > 0) {
      const names = widgets.map((w) => w.name).join(", ");
      console.log(`위젯 바인딩 생성 완료: ${names}`);
    }
  }

  // Classic 위젯 바인딩 (classic_ffi.mjs)
  generateClassicFfi(classicWidgets);
}

// 브릿지 JS 파일을 생성하고 정리 함수를 반환한다
function setupBridge() {
  generate_bindings();
  generate_widget_bindings();
  execGleamFiltered("gleam build");

  const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
  const widgetName = pkg.widgetName;
  const widgets = pkg.widgets;
  const gleamProject = readFileSync("gleam.toml", "utf-8").match(/^name\s*=\s*"([^"]+)"/m)[1];
  const gleamModule = gleamProject.replace(/-/g, "_");

  const bridgeFiles = [];

  if (widgets) {
    // === 멀티 위젯 모드 ===
    for (const [componentName, fnName] of Object.entries(widgets)) {
      // 위젯 브릿지
      const bridge = `src/${componentName}.js`;
      let cssLine = "";
      if (existsSync(`src/ui/${componentName}.css`)) {
        cssLine = `import "./ui/${componentName}.css";\n`;
      } else if (existsSync(`src/ui/${widgetName}.css`)) {
        cssLine = `import "./ui/${widgetName}.css";\n`;
      }
      writeFileSync(bridge,
        `// 자동 생성 브릿지 — 수동 편집 금지\n` +
        `import { ${fnName} } from "../build/dev/javascript/${gleamProject}/${gleamModule}.mjs";\n` +
        cssLine + `\n` +
        `export const ${componentName} = ${fnName};\n`
      );
      bridgeFiles.push(bridge);

      // Editor config 브릿지 (위젯별 → 공유 폴백)
      const editorBridge = `src/${componentName}.editorConfig.js`;
      if (existsSync(`src/${fnName}_editor_config.gleam`)) {
        writeFileSync(editorBridge,
          `// 자동 생성 브릿지 — 수동 편집 금지\n` +
          `import { get_properties } from "../build/dev/javascript/${gleamProject}/${fnName}_editor_config.mjs";\n\n` +
          `export const getProperties = get_properties;\n`
        );
        bridgeFiles.push(editorBridge);
      } else if (existsSync("src/editor_config.gleam")) {
        writeFileSync(editorBridge,
          `// 자동 생성 브릿지 — 수동 편집 금지\n` +
          `import { get_properties } from "../build/dev/javascript/${gleamProject}/editor_config.mjs";\n\n` +
          `export const getProperties = get_properties;\n`
        );
        bridgeFiles.push(editorBridge);
      }

      // Preview 브릿지 (위젯별 → 공유 폴백)
      const previewBridge = `src/${componentName}.editorPreview.js`;
      if (existsSync(`src/${fnName}_editor_preview.gleam`)) {
        writeFileSync(previewBridge,
          `// 자동 생성 브릿지 — 수동 편집 금지\n` +
          `import { preview } from "../build/dev/javascript/${gleamProject}/${fnName}_editor_preview.mjs";\n\n` +
          `export { preview };\n` +
          `export function getPreviewCss() {\n` +
          `  return require("./ui/${componentName}.css");\n` +
          `}\n`
        );
        bridgeFiles.push(previewBridge);
      } else if (existsSync("src/editor_preview.gleam")) {
        writeFileSync(previewBridge,
          `// 자동 생성 브릿지 — 수동 편집 금지\n` +
          `import { preview } from "../build/dev/javascript/${gleamProject}/editor_preview.mjs";\n\n` +
          `export { preview };\n` +
          `export function getPreviewCss() {\n` +
          `  return require("./ui/${componentName}.css");\n` +
          `}\n`
        );
        bridgeFiles.push(previewBridge);
      }
    }
  } else {
    // === 단일 위젯 모드 (하위 호환) ===
    const widgetBridge = `src/${widgetName}.js`;
    writeFileSync(widgetBridge,
      `// 자동 생성 브릿지 — 수동 편집 금지\n` +
      `import { widget } from "../build/dev/javascript/${gleamProject}/${gleamModule}.mjs";\n` +
      `import "./ui/${widgetName}.css";\n\n` +
      `export const ${widgetName} = widget;\n`
    );
    bridgeFiles.push(widgetBridge);

    if (existsSync("src/editor_config.gleam")) {
      const editorBridge = `src/${widgetName}.editorConfig.js`;
      writeFileSync(editorBridge,
        `// 자동 생성 브릿지 — 수동 편집 금지\n` +
        `import { get_properties } from "../build/dev/javascript/${gleamProject}/editor_config.mjs";\n\n` +
        `export const getProperties = get_properties;\n`
      );
      bridgeFiles.push(editorBridge);
    }

    if (existsSync("src/editor_preview.gleam")) {
      const previewBridge = `src/${widgetName}.editorPreview.js`;
      writeFileSync(previewBridge,
        `// 자동 생성 브릿지 — 수동 편집 금지\n` +
        `import { preview } from "../build/dev/javascript/${gleamProject}/editor_preview.mjs";\n\n` +
        `export { preview };\n` +
        `export function getPreviewCss() {\n` +
        `  return require("./ui/${widgetName}.css");\n` +
        `}\n`
      );
      bridgeFiles.push(previewBridge);
    }
  }

  // rollup.config.mjs 자동 생성 — react 서브패스 external 처리 + Rollup 경고 억제
  const rollupConfig = "rollup.config.mjs";
  const hasCustomRollup = existsSync(rollupConfig);

  if (!hasCustomRollup) {
    const secondaryWidgets = widgets
      ? Object.keys(widgets).filter(name => name !== widgetName)
      : [];

    if (secondaryWidgets.length > 0) {
      // 멀티 위젯 rollup config — 추가 위젯 엔트리 포함
      writeFileSync(rollupConfig,
        `// @generated glendix — 직접 수정 금지\n` +
        `import { readFileSync } from "node:fs";\n\n` +
        `export default args => {\n` +
        `  const configs = args.configDefaultConfig;\n` +
        `  const secondaryWidgets = ${JSON.stringify(secondaryWidgets)};\n\n` +
        `  function patchConfig(config) {\n` +
        `    const origExternal = config.external;\n` +
        `    return {\n` +
        `      ...config,\n` +
        `      external(id) {\n` +
        `        if (/^react(-dom)?($|\\/)/.test(id)) return true;\n` +
        `        if (typeof origExternal === "function") return origExternal(id);\n` +
        `        if (Array.isArray(origExternal)) {\n` +
        `          return origExternal.some(e =>\n` +
        `            e instanceof RegExp ? e.test(id) : e === id\n` +
        `          );\n` +
        `        }\n` +
        `        return false;\n` +
        `      },\n` +
        `      onwarn(warning, warn) {\n` +
        `        if (warning.code === "CIRCULAR_DEPENDENCY") return;\n` +
        `        if (warning.code === "UNUSED_EXTERNAL_IMPORT") return;\n` +
        `        if (config.onwarn) config.onwarn(warning, warn);\n` +
        `        else warn(warning);\n` +
        `      },\n` +
        `    };\n` +
        `  }\n\n` +
        `  const result = configs.map(patchConfig);\n\n` +
        `  const baseConfig = configs.find(c =>\n` +
        `    c.output && !c.output.file?.includes("editorConfig") &&\n` +
        `    !c.output.file?.includes("editorPreview")\n` +
        `  ) || configs[0];\n\n` +
        `  for (const name of secondaryWidgets) {\n` +
        `    const xml = readFileSync(\`src/\${name}.xml\`, "utf-8");\n` +
        `    const id = xml.match(/id="([^"]+)"/)[1];\n` +
        `    const outputPath = \`dist/tmp/widgets/\${id.replace(/\\./g, "/")}.js\`;\n\n` +
        `    result.push(patchConfig({\n` +
        `      ...baseConfig,\n` +
        `      input: \`src/\${name}.js\`,\n` +
        `      output: { ...baseConfig.output, file: outputPath },\n` +
        `    }));\n` +
        `  }\n\n` +
        `  return result;\n` +
        `};\n`
      );
    } else {
      writeFileSync(rollupConfig,
        `// @generated glendix — 직접 수정 금지\n` +
        `export default args => {\n` +
        `  const configs = args.configDefaultConfig;\n` +
        `  return configs.map(config => {\n` +
        `    const origExternal = config.external;\n` +
        `    return {\n` +
        `      ...config,\n` +
        `      external(id) {\n` +
        `        if (/^react(-dom)?($|\\/)/.test(id)) return true;\n` +
        `        if (typeof origExternal === "function") return origExternal(id);\n` +
        `        if (Array.isArray(origExternal)) {\n` +
        `          return origExternal.some(e =>\n` +
        `            e instanceof RegExp ? e.test(id) : e === id\n` +
        `          );\n` +
        `        }\n` +
        `        return false;\n` +
        `      },\n` +
        `      onwarn(warning, warn) {\n` +
        `        if (warning.code === "CIRCULAR_DEPENDENCY") return;\n` +
        `        if (warning.code === "UNUSED_EXTERNAL_IMPORT") return;\n` +
        `        if (config.onwarn) config.onwarn(warning, warn);\n` +
        `        else warn(warning);\n` +
        `      },\n` +
        `    };\n` +
        `  });\n` +
        `};\n`
      );
    }
    bridgeFiles.push(rollupConfig);
  }

  const cleanup = () => {
    for (const f of bridgeFiles) {
      try { unlinkSync(f); } catch {}
    }
  };

  return { cleanup, widgetBridge: `src/${widgetName}.js` };
}

// BABEL Note 경고만 필터링한다 (Rollup 경고는 rollup.config.mjs onwarn이 처리)
function filterBabelNotes(stderr) {
  return stderr
    .split(/\r?\n/)
    .filter(line =>
      !line.includes("[BABEL] Note: The code generator has deoptimised") &&
      !line.includes("as it exceeds the max of")
    )
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

// 브릿지 JS 파일을 자동 생성하고 명령 실행 후 삭제
export function run_with_bridge(command) {
  const { cleanup } = setupBridge();
  process.on("SIGINT", () => { cleanup(); process.exit(130); });

  try {
    const result = spawnSync(command, { shell: true, stdio: ["inherit", "pipe", "pipe"] });
    if (result.stdout && result.stdout.length > 0) process.stdout.write(result.stdout);
    if (result.stderr && result.stderr.length > 0) {
      const filtered = filterBabelNotes(result.stderr.toString());
      if (filtered) process.stderr.write(filtered + "\n");
    }
    if (result.status !== 0) {
      const err = new Error("Command failed: " + command);
      err.status = result.status;
      throw err;
    }
  } finally {
    cleanup();
  }
}

// 개발 모드: .gleam 변경 감지 + build:web 반복 실행
// Rollup --watch를 사용하지 않는다 — Windows에서 chokidar watcher 설정이 2분+ 소요
export function run_dev_with_bridge(buildCommand) {
  const { cleanup } = setupBridge();

  // BABEL Note만 필터링하여 Rollup 빌드를 실행한다
  function execBuild() {
    const result = spawnSync(buildCommand, { shell: true, stdio: ["inherit", "pipe", "pipe"] });
    if (result.stdout && result.stdout.length > 0) process.stdout.write(result.stdout);
    if (result.stderr && result.stderr.length > 0) {
      const filtered = filterBabelNotes(result.stderr.toString());
      if (filtered) process.stderr.write(filtered + "\n");
    }
    if (result.status !== 0) throw new Error("Build failed");
  }

  // 초기 빌드
  console.log("[glendix] 초기 빌드 시작\n");
  execBuild();
  console.log("\n[glendix] .gleam 파일 변경 감지 활성화 — 저장 시 자동 빌드\n");

  // .gleam 파일 mtime 추적
  const mtimes = {};

  function scanGleam(dir) {
    try {
      const entries = readdirSync(dir);
      for (const name of entries) {
        if (name.startsWith(".")) continue;
        const p = dir + "/" + name;
        try {
          const s = statSync(p);
          if (s.isDirectory()) scanGleam(p);
          else if (name.endsWith(".gleam")) mtimes[p] = s.mtimeMs;
        } catch {}
      }
    } catch {}
  }

  function hasChanges() {
    let changed = false;
    function check(dir) {
      try {
        const entries = readdirSync(dir);
        for (const name of entries) {
          if (name.startsWith(".")) continue;
          const p = dir + "/" + name;
          try {
            const s = statSync(p);
            if (s.isDirectory()) { check(p); continue; }
            if (!name.endsWith(".gleam")) continue;
            const prev = mtimes[p];
            mtimes[p] = s.mtimeMs;
            if (prev === undefined || prev !== s.mtimeMs) changed = true;
          } catch {}
        }
      } catch {}
    }
    check("src");
    return changed;
  }

  scanGleam("src");

  const pollId = setInterval(() => {
    if (!hasChanges()) return;
    console.log("\n[glendix] 변경 감지 → 리빌드");
    try {
      execGleamFiltered("gleam build");
      execBuild();
      console.log("[glendix] 빌드 완료");
    } catch {
      // 빌드 에러는 이미 출력됨
    }
  }, 500);

  process.on("SIGINT", () => {
    clearInterval(pollId);
    cleanup();
    process.exit(130);
  });
}
