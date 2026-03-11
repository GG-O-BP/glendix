// 셸 명령어 실행 + 파일 존재 확인 + 브릿지 자동 생성 + 바인딩 생성 FFI 어댑터
import { execSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync, unlinkSync, mkdirSync } from "node:fs";

export function exec(command) {
  execSync(command, { stdio: "inherit", shell: true });
}

export function file_exists(path) {
  return existsSync(path);
}

// bindings.json → binding_ffi.mjs 생성
// glendix 빌드 경로에 직접 생성하여 사용자가 .mjs를 작성하지 않아도 되게 한다
export function generate_bindings() {
  if (!existsSync("bindings.json")) return;

  let config;
  try {
    config = JSON.parse(readFileSync("bindings.json", "utf-8"));
  } catch (e) {
    console.log("bindings.json 파싱 실패: " + e.message);
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
    `  if (!mod) throw new Error("바인딩에 등록되지 않은 모듈: " + name + ". bindings.json을 확인하세요.");\n` +
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

// 브릿지 JS 파일을 자동 생성하고 명령 실행 후 삭제
export function run_with_bridge(command) {
  // 바인딩 자동 갱신 (bindings.json 있을 때만)
  generate_bindings();

  // Gleam 빌드 출력 보장 (Rollup이 .mjs를 resolve할 수 있도록)
  execSync("gleam build", { stdio: "inherit", shell: true });

  const widgetName = JSON.parse(readFileSync("package.json", "utf-8")).widgetName;
  const gleamProject = readFileSync("gleam.toml", "utf-8").match(/^name\s*=\s*"([^"]+)"/m)[1];

  const widgetBridge = `src/${widgetName}.js`;
  const editorBridge = `src/${widgetName}.editorConfig.js`;
  const previewBridge = `src/${widgetName}.editorPreview.js`;

  // 위젯 브릿지 생성
  writeFileSync(
    widgetBridge,
    `// 자동 생성 브릿지 — 수동 편집 금지\n` +
    `import { widget } from "../build/dev/javascript/${gleamProject}/${gleamProject.replace(/-/g, "_")}.mjs";\n` +
    `import "./ui/${widgetName}.css";\n\n` +
    `export const ${widgetName} = widget;\n`,
  );

  // editorConfig 브릿지 (src/widget/editor_config.gleam 존재 시만)
  const hasEditor = existsSync("src/editor_config.gleam");
  if (hasEditor) {
    writeFileSync(
      editorBridge,
      `// 자동 생성 브릿지 — 수동 편집 금지\n` +
      `import { get_properties } from "../build/dev/javascript/${gleamProject}/editor_config.mjs";\n\n` +
      `export const getProperties = get_properties;\n`,
    );
  }

  // editorPreview 브릿지 (src/editor_preview.gleam 존재 시만)
  const hasPreview = existsSync("src/editor_preview.gleam");
  if (hasPreview) {
    writeFileSync(
      previewBridge,
      `// 자동 생성 브릿지 — 수동 편집 금지\n` +
      `import { preview } from "../build/dev/javascript/${gleamProject}/editor_preview.mjs";\n\n` +
      `export { preview };\n` +
      `export function getPreviewCss() {\n` +
      `  return require("./ui/${widgetName}.css");\n` +
      `}\n`,
    );
  }

  // SIGINT 핸들러 + try/finally로 정리 보장
  const cleanup = () => {
    try { unlinkSync(widgetBridge); } catch {}
    if (hasEditor) try { unlinkSync(editorBridge); } catch {}
    if (hasPreview) try { unlinkSync(previewBridge); } catch {}
  };
  process.on("SIGINT", () => { cleanup(); process.exit(130); });

  try {
    execSync(command, { stdio: "inherit", shell: true });
  } finally {
    cleanup();
  }
}
