// 셸 명령어 실행 + 파일 존재 확인 + 브릿지 자동 생성 + 바인딩 생성 FFI 어댑터
import { execSync, spawnSync, spawn } from "node:child_process";
import { existsSync, readFileSync, writeFileSync, unlinkSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { Some, None } from "../../gleam_stdlib/gleam/option.mjs";

// ── TOML 파서 (tools.glendix 섹션) ──

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
  const result = { pm: null, bindings: {} };
  let currentSection = null;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;

    const sectionMatch = trimmed.match(/^\[(.+)\]$/);
    if (sectionMatch) {
      const path = sectionMatch[1];
      if (path === "tools.glendix") currentSection = "root";
      else if (path === "tools.glendix.bindings") currentSection = "bindings";
      else currentSection = null;
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
    }
  }

  return result;
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


// gleam.toml [tools.glendix.bindings] → binding_ffi.mjs 생성
// glendix 빌드 경로에 직접 생성하여 사용자가 .mjs를 작성하지 않아도 되게 한다
export function generate_bindings() {
  const tomlConfig = parseGlendixToml();

  if (!tomlConfig?.bindings || Object.keys(tomlConfig.bindings).length === 0) {
    return;
  }

  const config = {};
  for (const [pkg, components] of Object.entries(tomlConfig.bindings)) {
    config[pkg] = { components: Array.isArray(components) ? components : [components] };
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
    `  if (!mod) throw new Error("바인딩에 등록되지 않은 모듈: " + name + ". gleam.toml [tools.glendix.bindings]를 확인하세요.");\n` +
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

// 브릿지 JS 파일을 생성하고 정리 함수를 반환한다
function setupBridge() {
  generate_bindings();
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
