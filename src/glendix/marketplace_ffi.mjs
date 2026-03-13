// Mendix Marketplace Content API + Playwright 브라우저 다운로드 FFI 어댑터
import { execSync, spawn } from "node:child_process";
import {
  existsSync,
  readFileSync,
  readSync,
  writeFileSync,
  mkdirSync,
  unlinkSync,
} from "node:fs";

// ── 동기 stdin 입력 (Windows/Unix 호환) ──

function promptSync(question) {
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
    } catch {
      break;
    }
  }
  return input.trim();
}

// ── .env에서 값 읽기 ──

function readEnvValue(key) {
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

// ── Content API 호출 ──

function curlJson(url, pat) {
  try {
    const result = execSync(
      `curl -s -H "Authorization: MxToken ${pat}" "${url}"`,
      { encoding: "utf-8", shell: true },
    );
    return JSON.parse(result);
  } catch {
    return null;
  }
}

const API_BASE = "https://marketplace-api.mendix.com/v1";
const FETCH_SIZE = 40;
const DISPLAY_SIZE = 10;

// 위젯 로드 상태
let allWidgets = [];
let apiOffset = 0;
let allLoaded = false;

const MX_DIR = ".marketplace-cache";
const CACHE_PATH = `${MX_DIR}/widget_cache.json`;
const CACHE_TMP = `${MX_DIR}/widget_cache.tmp`;
const SEED_PATH = `${MX_DIR}/loader_seed.json`;

function sleepMs(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

// API에서 한 배치 로드 (첫 배치용)
function loadBatch(pat) {
  if (allLoaded) return false;
  const url = `${API_BASE}/content?limit=${FETCH_SIZE}&offset=${apiOffset}`;
  const data = curlJson(url, pat);
  if (!data) {
    allLoaded = true;
    return false;
  }

  if (data.error) {
    if (data.error.code === 401) {
      console.log("인증 실패 — MENDIX_PAT를 확인하세요");
    } else {
      console.log(`API 에러: ${data.error.message}`);
    }
    allLoaded = true;
    return false;
  }

  const items = data.items || [];
  if (items.length === 0) {
    allLoaded = true;
    return false;
  }

  for (const item of items) {
    if (item.type === "Widget") allWidgets.push(item);
  }

  apiOffset += FETCH_SIZE;
  if (items.length < FETCH_SIZE) allLoaded = true;
  return true;
}

// 백그라운드 로더 프로세스 시작 (나머지 배치)
function spawnLoader(pat) {
  writeFileSync(SEED_PATH, JSON.stringify({
    pat, offset: apiOffset, widgets: allWidgets,
  }));

  const script = [
    'import { execSync } from "node:child_process";',
    'import { readFileSync, writeFileSync, renameSync, unlinkSync } from "node:fs";',
    '',
    `const { pat, offset: startOffset, widgets: seedWidgets } = JSON.parse(readFileSync("${SEED_PATH}", "utf-8"));`,
    `try { unlinkSync("${SEED_PATH}"); } catch {}`,
    '',
    `const FETCH_SIZE = ${FETCH_SIZE};`,
    'let offset = startOffset;',
    'let widgets = seedWidgets;',
    '',
    'function curlJson(url) {',
    '  try {',
    '    return JSON.parse(execSync(',
    '      \'curl -s -H "Authorization: MxToken \' + pat + \'" "\' + url + \'"\',',
    '      { encoding: "utf-8", shell: true }',
    '    ));',
    '  } catch { return null; }',
    '}',
    '',
    'function writeCache(done) {',
    '  const data = JSON.stringify({ done, widgets, offset });',
    `  writeFileSync("${CACHE_TMP}", data);`,
    `  try { renameSync("${CACHE_TMP}", "${CACHE_PATH}"); }`,
    `  catch { writeFileSync("${CACHE_PATH}", data); }`,
    '}',
    '',
    'while (true) {',
    `  const data = curlJson("${API_BASE}/content?limit=" + FETCH_SIZE + "&offset=" + offset);`,
    '  if (!data || data.error || !(data.items?.length)) { writeCache(true); break; }',
    '  for (const item of data.items) {',
    '    if (item.type === "Widget") widgets.push(item);',
    '  }',
    '  offset += FETCH_SIZE;',
    '  writeCache(data.items.length < FETCH_SIZE);',
    '  if (data.items.length < FETCH_SIZE) break;',
    '}',
  ].join('\n');

  const scriptPath = `${MX_DIR}/loader_${Date.now()}.mjs`;
  writeFileSync(scriptPath, script);
  const child = spawn(process.execPath, [scriptPath], { stdio: "ignore" });
  return { child, scriptPath };
}

// 캐시 파일에서 위젯 동기화
function syncFromCache() {
  try {
    const cache = JSON.parse(readFileSync(CACHE_PATH, "utf-8"));
    if (cache.widgets.length > allWidgets.length) {
      allWidgets = cache.widgets;
    }
    if (cache.offset > apiOffset) {
      apiOffset = cache.offset;
    }
    if (cache.done) allLoaded = true;
  } catch {}
}

// 전체 로드 완료 대기
function waitForAllLoaded() {
  while (!allLoaded) {
    sleepMs(200);
    syncFromCache();
  }
}

// 로더 프로세스 정리
function cleanupLoader(loader) {
  if (!loader) return;
  try { loader.child.kill(); } catch {}
  try { unlinkSync(loader.scriptPath); } catch {}
  try { unlinkSync(CACHE_PATH); } catch {}
  try { unlinkSync(CACHE_TMP); } catch {}
  try { unlinkSync(SEED_PATH); } catch {}
}

// 검색 필터
function filterWidgets(widgets, query) {
  if (!query) return widgets;
  const q = query.toLowerCase();
  return widgets.filter((item) => {
    const name = getName(item) || "";
    const pub = getPublisher(item) || "";
    return name.toLowerCase().includes(q) || pub.toLowerCase().includes(q);
  });
}

// ── 아이템 필드 접근 ──

function getName(item) {
  return item.latestVersion ? item.latestVersion.name : null;
}

function getContentId(item) {
  return item.contentId;
}

function getPublisher(item) {
  return item.publisher;
}

function getLatestVersion(item) {
  return item.latestVersion ? item.latestVersion.versionNumber : null;
}

// ── Playwright 스크립트 실행 ──

const SESSION_PATH = `${MX_DIR}/session.json`;

function esc(s) {
  return s.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}

function runPw(script, timeout) {
  const tmp = `${MX_DIR}/pw_${Date.now()}.mjs`;
  writeFileSync(tmp, script);
  try {
    return execSync(`node "${tmp}"`, {
      encoding: "utf-8",
      timeout: timeout || 300000,
      shell: true,
      stdio: ["pipe", "pipe", "inherit"],
    }).trim();
  } finally {
    try {
      unlinkSync(tmp);
    } catch {}
  }
}

// ── Mendix 로그인 세션 관리 ──

function ensureSession() {
  // 저장된 세션 유효성 확인 (headless)
  if (existsSync(SESSION_PATH)) {
    try {
      const out = runPw(
        `
import { chromium } from 'playwright';
const b = await chromium.launch({ headless: true });
const c = await b.newContext({ storageState: '${esc(SESSION_PATH)}' });
const p = await c.newPage();
await p.goto('https://marketplace.mendix.com/', { waitUntil: 'domcontentloaded' });
await p.waitForTimeout(3000);
const valid = !p.url().includes('login.mendix');
await b.close();
console.log(JSON.stringify({ valid }));
`,
        30000,
      );
      if (JSON.parse(out).valid) return true;
    } catch {}
    console.log("  저장된 세션이 만료되었습니다.");
  }

  // 브라우저 열어서 로그인
  console.log("  브라우저에서 Mendix 로그인을 완료하세요...\n");
  try {
    const tmp = `${MX_DIR}/pw_${Date.now()}.mjs`;
    writeFileSync(
      tmp,
      `
import { chromium } from 'playwright';
const b = await chromium.launch({ headless: false });
const c = await b.newContext();
const p = await c.newPage();
await p.goto('https://login.mendix.com/');
await p.waitForURL(u => !u.toString().includes('login.mendix'), { timeout: 300000 });
await c.storageState({ path: '${esc(SESSION_PATH)}' });
await b.close();
`,
    );
    try {
      execSync(`node "${tmp}"`, {
        timeout: 300000,
        shell: true,
        stdio: "inherit",
      });
    } finally {
      try {
        unlinkSync(tmp);
      } catch {}
    }
    if (existsSync(SESSION_PATH)) {
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

// ── Content API로 버전 목록 조회 ──

function fetchVersions(contentId, pat) {
  const url = `${API_BASE}/content/${contentId}/versions`;
  const data = curlJson(url, pat);
  if (!data || !data.items) return [];
  // publicationDate 내림차순 (최신 먼저)
  return data.items.sort(
    (a, b) => new Date(b.publicationDate) - new Date(a.publicationDate),
  );
}

// ── Playwright로 버전별 다운로드 정보 추출 ──

function getAllVersionInfo(contentIds) {
  const ids = JSON.stringify(contentIds);
  try {
    const out = runPw(
      `
import { chromium } from 'playwright';

const ids = ${ids};
const results = {};

const b = await chromium.launch({ headless: true });
const c = await b.newContext({ storageState: '${esc(SESSION_PATH)}' });
const p = await c.newPage();

for (const id of ids) {
  // XAS 응답 promise를 동기적으로 수집 (async handler race condition 방지)
  const responsePromises = [];

  const xasHandler = (response) => {
    if (!response.url().includes('/xas/')) return;
    // response.json()을 즉시 호출하여 promise 저장 — await하지 않음
    responsePromises.push(response.json().catch(() => null));
  };
  p.on('response', xasHandler);

  try {
    await p.goto('https://marketplace.mendix.com/link/component/' + id, {
      waitUntil: 'networkidle',
      timeout: 30000,
    });

    // Releases 탭 클릭 시도
    let tabClicked = false;
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
          tabClicked = true;
          break;
        }
      } catch {}
    }

    // 추가 XAS 응답 대기
    await p.waitForTimeout(3000);
  } catch (e) {
    process.stderr.write('  [pw] 오류 (id=' + id + '): ' + e.message + '\\n');
  }

  p.removeListener('response', xasHandler);

  // 수집한 모든 XAS 응답에서 버전 데이터 추출
  const versions = [];
  const seen = new Set();
  const responses = await Promise.all(responsePromises);

  for (const json of responses) {
    if (!json || !json.objects) continue;
    for (const obj of json.objects) {
      if (obj.objectType !== 'AppStore.Version') continue;
      const attrs = obj.attributes;
      if (!attrs?.S3ObjectId?.value) continue;
      const s3Id = attrs.S3ObjectId.value;
      if (seen.has(s3Id)) continue;
      seen.add(s3Id);
      versions.push({
        s3ObjectId: s3Id,
        reactReady: !!attrs?.IsReactClientReady?.value,
        publishDate: attrs.PublishDate?.value || 0,
        versionNumber: attrs.DisplayVersionNumber?.value || null,
      });
    }
  }

  results[id] = versions;

  if (versions.length === 0) {
    process.stderr.write('  [pw] 다운로드 가능한 버전 없음 (id=' + id + ')\\n');
  }
}

await b.close();
console.log(JSON.stringify(results));
`,
      180000,
    );
    return JSON.parse(out);
  } catch (e) {
    console.log(`        Playwright 오류: ${e.message}`);
    return {};
  }
}

// ── 버전 목록 병합 (Content API + XAS) ──

// S3ObjectId에서 URL 템플릿을 추출한다
// "5/54611/3.2.2/StarRating.mpk" → { prefix: "5/54611", fileName: "StarRating.mpk" }
function extractS3Template(xasVersions) {
  for (const x of xasVersions) {
    if (!x.s3ObjectId) continue;
    const parts = x.s3ObjectId.split("/");
    if (parts.length >= 4) {
      return { prefix: parts.slice(0, 2).join("/"), fileName: parts.slice(3).join("/") };
    }
  }
  return null;
}

// XAS 버전을 DisplayVersionNumber 또는 S3ObjectId에서 추출한 버전으로 인덱싱
function buildXasIndex(xasVersions) {
  const byVersion = new Map();
  for (const x of xasVersions) {
    // DisplayVersionNumber
    if (x.versionNumber) byVersion.set(x.versionNumber, x);
    // S3ObjectId에서 추출 ("5/54611/3.2.2/StarRating.mpk" → "3.2.2")
    if (x.s3ObjectId) {
      const parts = x.s3ObjectId.split("/");
      if (parts.length >= 4) byVersion.set(parts[2], x);
    }
  }
  return byVersion;
}

function mergeVersionData(apiVersions, xasVersions) {
  const xasIndex = buildXasIndex(xasVersions);
  const s3Template = extractS3Template(xasVersions);

  return apiVersions.map((api) => {
    const xas = xasIndex.get(api.versionNumber) || null;

    if (xas) {
      // XAS에서 직접 매칭 — reactReady 확정
      return {
        versionNumber: api.versionNumber,
        publicationDate: api.publicationDate,
        minMendixVersion: api.minSupportedMendixVersion || null,
        s3ObjectId: xas.s3ObjectId,
        reactReady: xas.reactReady,
        downloadable: true,
      };
    }

    // XAS 미매칭 — S3 URL 템플릿으로 구성 (reactReady 알 수 없음)
    if (s3Template) {
      return {
        versionNumber: api.versionNumber,
        publicationDate: api.publicationDate,
        minMendixVersion: api.minSupportedMendixVersion || null,
        s3ObjectId: `${s3Template.prefix}/${api.versionNumber}/${s3Template.fileName}`,
        reactReady: null, // 알 수 없음
        downloadable: true,
      };
    }

    return {
      versionNumber: api.versionNumber,
      publicationDate: api.publicationDate,
      minMendixVersion: api.minSupportedMendixVersion || null,
      s3ObjectId: null,
      reactReady: null,
      downloadable: false,
    };
  });
}

// ── 버전 선택 UI ──

function displayVersionList(widgetName, versions) {
  console.log(`\n  ${widgetName} — 버전 선택:\n`);
  for (let i = 0; i < versions.length; i++) {
    const v = versions[i];
    const date = v.publicationDate ? v.publicationDate.slice(0, 10) : "?";
    const minMx = v.minMendixVersion ? ` (Mendix ≥${v.minMendixVersion})` : "";
    let typeLabel;
    if (!v.downloadable) {
      typeLabel = " [다운로드 불가]";
    } else if (v.reactReady === true) {
      typeLabel = " [Pluggable]";
    } else if (v.reactReady === false) {
      typeLabel = " [Classic]";
    } else {
      typeLabel = "";
    }
    const defaultMark = i === 0 ? "  ← 기본" : "";
    console.log(`    [${i}] v${v.versionNumber} (${date})${minMx}${typeLabel}${defaultMark}`);
  }
  console.log("");
}

function promptVersionSelection(versions) {
  const input = promptSync("  버전 번호 (Enter=최신): ");
  if (input === "") return 0;
  const idx = parseInt(input);
  if (isNaN(idx) || idx < 0 || idx >= versions.length) return -1;
  return idx;
}

// ── S3 URL에서 다운로드 ──

function downloadFromUrl(url) {
  const fileName = url.split("/").pop();
  const dest = `widgets/${fileName}`;

  if (existsSync(dest)) {
    console.log(`        → ${fileName} 이미 존재 (스킵)`);
    return fileName;
  }

  try {
    execSync(`curl -s -L -o "${dest}" "${url}"`, { shell: true });
    return fileName;
  } catch {
    console.log(`        ✗ 다운로드 실패`);
    return null;
  }
}

// ── 페이지 표시 ──

function displayPage(items, pageNum, totalPages) {
  console.log(`  ── 페이지 ${pageNum}/${totalPages} ──\n`);

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const ver = getLatestVersion(item);
    const verStr = ver ? ` v${ver}` : "";
    const pub = getPublisher(item);
    const pubStr = pub ? ` — ${pub}` : "";
    console.log(
      `  [${i}] ${getName(item)} (${getContentId(item)})${verStr}${pubStr}`,
    );
  }

  console.log(
    "\n  번호: 다운로드 | 검색어: 이름 검색 | n: 다음 | p: 이전 | r: 초기화 | q: 종료\n",
  );
}

// ── 메인 ──

export function download_widgets() {
  const pat = readEnvValue("MENDIX_PAT");
  if (!pat) {
    console.log(
      ".env 파일에 MENDIX_PAT가 필요합니다.\n\n" +
        "예시 (.env):\n" +
        "  MENDIX_PAT=your_personal_access_token\n\n" +
        "PAT는 Mendix Portal → Settings → Personal Access Tokens에서 발급합니다.\n" +
        "필요한 scope: mx:marketplace-content:read",
    );
    return;
  }

  // 상태 초기화
  if (!existsSync(MX_DIR)) mkdirSync(MX_DIR, { recursive: true });

  allWidgets = [];
  apiOffset = 0;
  allLoaded = false;

  // 첫 배치 직접 로드 → 즉시 표시
  loadBatch(pat);
  if (allWidgets.length === 0) {
    console.log("  위젯을 불러올 수 없습니다.\n");
    return;
  }

  // 나머지를 백그라운드 프로세스에서 로드
  let loader = allLoaded ? null : spawnLoader(pat);

  // Ctrl+C 종료 시 정리
  const onExit = () => {
    cleanupLoader(loader);
    process.exit();
  };
  process.on("SIGINT", onExit);

  let filtered = null;
  let pageIndex = 0;
  let downloaded = 0;

  function source() {
    return filtered || allWidgets;
  }

  function currentPageItems() {
    return source().slice(pageIndex * DISPLAY_SIZE, (pageIndex + 1) * DISPLAY_SIZE);
  }

  function totalPagesStr() {
    const total = Math.max(1, Math.ceil(source().length / DISPLAY_SIZE));
    return allLoaded || filtered ? `${total}` : `${total}+`;
  }

  function showPage() {
    displayPage(currentPageItems(), pageIndex + 1, totalPagesStr());
  }

  try {
    showPage();

    while (true) {
      const input = promptSync("> ");

      // 매 입력마다 백그라운드 로더 결과 동기화
      if (!allLoaded) syncFromCache();

      if (input === "q") break;
      if (input === "") continue;

      // 다음 페이지
      if (input === "n") {
        if ((pageIndex + 1) * DISPLAY_SIZE >= source().length) {
          console.log("  마지막 페이지입니다.\n");
          continue;
        }
        pageIndex++;
        console.log("");
        showPage();
        continue;
      }

      // 이전 페이지
      if (input === "p") {
        if (pageIndex === 0) {
          console.log("  첫 페이지입니다.\n");
          continue;
        }
        pageIndex--;
        console.log("");
        showPage();
        continue;
      }

      // 초기화 (검색 해제)
      if (input === "r") {
        filtered = null;
        pageIndex = 0;
        console.log("\n  검색 초기화\n");
        showPage();
        continue;
      }

      // 숫자 입력 → 다운로드
      const page = currentPageItems();
      if (/^[\d,\s]+$/.test(input) && page.length > 0) {
        const indices = input
          .split(",")
          .map((s) => parseInt(s.trim()))
          .filter((i) => i >= 0 && i < page.length);

        if (indices.length > 0) {
          if (!existsSync("widgets")) mkdirSync("widgets", { recursive: true });

          // 다운로드 진행 전 백그라운드 로더 중지 (리소스 확보)
          if (loader) {
            syncFromCache();
            try { loader.child.kill(); } catch {}
          }

          const selectedWidgets = indices.map((idx) => ({
            contentId: getContentId(page[idx]),
            name: getName(page[idx]),
          }));

          // 다운로드 시 로그인 세션 확인 (xas 접근에 필요)
          const sessionReady = ensureSession();
          if (!sessionReady) {
            console.log("  Mendix 로그인이 필요합니다.\n");
            if (!allLoaded) loader = spawnLoader(pat);
            showPage();
            continue;
          }

          // Playwright로 전체 버전 다운로드 정보 일괄 조회
          console.log("\n  버전 정보 조회 중...");
          const allXasData = getAllVersionInfo(selectedWidgets.map((w) => w.contentId));

          // 각 위젯별로 버전 선택 → 다운로드
          for (const w of selectedWidgets) {
            // Content API에서 버전 목록 조회
            const apiVersions = fetchVersions(w.contentId, pat);
            const xasVersions = allXasData[w.contentId] || [];

            if (apiVersions.length === 0) {
              console.log(`\n  ${w.name} — 버전 정보를 가져올 수 없습니다.`);
              continue;
            }

            // API + XAS 데이터 병합
            const merged = mergeVersionData(apiVersions, xasVersions);

            // 버전 목록 표시 + 선택
            displayVersionList(w.name, merged);
            const vIdx = promptVersionSelection(merged);

            if (vIdx < 0) {
              console.log("    잘못된 선택입니다. 건너뜁니다.\n");
              continue;
            }

            const selected = merged[vIdx];
            if (!selected.downloadable || !selected.s3ObjectId) {
              console.log(`    v${selected.versionNumber}은 다운로드할 수 없습니다.\n`);
              continue;
            }

            const url = "https://files.appstore.mendix.com/" + selected.s3ObjectId;
            const fn = downloadFromUrl(url);
            if (fn) {
              const typeLabel = selected.reactReady === true ? "Pluggable" : selected.reactReady === false ? "Classic" : "";
              console.log(`        → ${fn} 다운로드 완료${typeLabel ? ` (${typeLabel})` : ""}`);
              downloaded++;
            }
          }

          // 다운로드 완료 후 로더 재시작
          if (!allLoaded) {
            loader = spawnLoader(pat);
          }

          console.log("");
          showPage();
          continue;
        }
      }

      // 검색어 → 로드된 위젯에서 필터
      const result = filterWidgets(allWidgets, input);
      pageIndex = 0;

      if (result.length === 0) {
        console.log(`  "${input}" 검색 결과가 없습니다.${allLoaded ? "" : " (로드 중 — 더 있을 수 있음)"}\n`);
        filtered = null;
        continue;
      }

      filtered = result;
      const suffix = allLoaded ? "" : " (로드 중 — 더 있을 수 있음)";
      console.log(`\n  "${input}" 검색 결과: ${filtered.length}개${suffix} — r: 전체 목록으로 복귀\n`);
      showPage();
    }
  } finally {
    process.removeListener("SIGINT", onExit);
    cleanupLoader(loader);
  }

  if (downloaded > 0) {
    console.log(`\n다운로드 완료: ${downloaded}개`);
  }
}
