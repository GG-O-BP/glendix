// 셸 명령어 실행 + 파일 존재 확인 + 브릿지 자동 생성 + 바인딩 생성 FFI 어댑터
import { execSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync, unlinkSync, mkdirSync, readdirSync } from "node:fs";
import { inflateRawSync } from "node:zlib";

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
  imports += "import glendix/mendix\n";
  imports += "import glendix/react.{type JsProps, type ReactElement}\n";
  imports += "import glendix/react/attribute\n";
  imports += "import glendix/widget\n";

  // render 함수 본문
  let body = "";
  for (const prop of requiredProps) {
    body += `  let ${toGleamVar(prop.key)} = mendix.get_prop_required(props, "${prop.key}")\n`;
  }

  body += `\n  let comp = widget.component("${widgetName}")\n`;
  body += "  react.component_el(\n    comp,\n    [\n";

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
  content += "pub fn render(props: JsProps) -> ReactElement {\n";
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

// Classic .mpk 감지 — package.xml에 clientModule이 있으면 Classic (Dojo) 위젯
function isClassicMpk(buf) {
  try {
    const packageXml = readZipEntry(buf, "package.xml").toString("utf-8");
    return packageXml.includes("clientModule");
  } catch {
    return false;
  }
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
  let imports = "import gleam/dynamic\n";
  if (hasOptional) {
    imports += "import gleam/option.{None, Some}\n";
  }
  imports += "import glendix/classic\n";
  imports += "import glendix/mendix\n";
  imports += "import glendix/react.{type JsProps, type ReactElement}\n";

  // render 함수 본문
  let body = "";
  for (const prop of requiredProps) {
    body += `  let ${toGleamVar(prop.key)} = mendix.get_prop_required(props, "${prop.key}")\n`;
  }

  body += `\n  classic.render("${widgetId}", [\n`;

  for (const prop of requiredProps) {
    body += `    #("${prop.key}", dynamic.from(${toGleamVar(prop.key)})),\n`;
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
  content += "pub fn render(props: JsProps) -> ReactElement {\n";
  content += body;
  content += "}\n";

  if (hasOptional) {
    content += "\n";
    content += "/// optional prop을 #(key, Dynamic) 튜플로 변환\n";
    content += "fn optional_prop(props: JsProps, key: String) -> #(String, dynamic.Dynamic) {\n";
    content += "  case mendix.get_prop(props, key) {\n";
    content += "    Some(val) -> #(key, dynamic.from(val))\n";
    content += "    None -> #(key, dynamic.from(Nil))\n";
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

// widgets/ 디렉토리의 .mpk에서 위젯 바인딩을 생성한다
export function generate_widget_bindings() {
  if (!existsSync("widgets")) return;

  let mpkFiles;
  try {
    mpkFiles = readdirSync("widgets").filter((f) => f.endsWith(".mpk"));
  } catch {
    return;
  }

  if (mpkFiles.length === 0) return;

  const widgets = []; // pluggable: { name, safeId, mjsContent, cssContent }
  const classicWidgets = []; // classic: { name, safeId, widgetId, jsFiles, templateFiles, css, libFiles }

  for (const mpkFile of mpkFiles) {
    try {
      const buf = readFileSync(`widgets/${mpkFile}`);
      const entries = listZipEntries(buf);

      // Classic .mpk 감지 — .mjs가 없고 clientModule이 있으면 Classic
      if (isClassicMpk(buf)) {
        const classic = extractClassicWidget(buf, entries);
        if (!classic) {
          console.log(`경고: ${mpkFile} Classic 위젯 추출 실패`);
          continue;
        }

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

      // ── Pluggable 위젯 처리 (기존 로직) ──

      // package.xml에서 위젯 파일 경로 추출
      const packageXml = readZipEntry(buf, "package.xml").toString("utf-8");
      const widgetFileMatch = packageXml.match(
        /widgetFile\s+path="([^"]+)"/,
      );
      if (!widgetFileMatch) {
        console.log(`경고: ${mpkFile}에서 widgetFile을 찾을 수 없습니다`);
        continue;
      }

      // 위젯 XML에서 <name> 추출
      const widgetXmlPath = widgetFileMatch[1];
      const widgetXml = readZipEntry(buf, widgetXmlPath).toString("utf-8");
      const widgetName = parseWidgetName(widgetXml);
      if (!widgetName) {
        console.log(`경고: ${mpkFile}에서 위젯 이름을 찾을 수 없습니다`);
        continue;
      }

      // .mjs 파일 찾기
      const mjsEntry = entries.find((e) => e.endsWith(".mjs"));
      if (!mjsEntry) {
        console.log(`경고: ${mpkFile}에서 .mjs 파일을 찾을 수 없습니다`);
        continue;
      }

      // .css 파일 찾기 (없을 수도 있음)
      const cssEntry = entries.find(
        (e) => e.endsWith(".css") && !e.includes("editorPreview"),
      );

      // 위젯 에셋 추출
      const mjsContent = readZipEntry(buf, mjsEntry);
      const cssContent = cssEntry ? readZipEntry(buf, cssEntry) : null;

      // 위젯 바인딩 .gleam 파일 생성
      generateWidgetGleamFile(widgetName, widgetXml);

      const safeId = toSafeIdentifier(widgetName);
      widgets.push({ name: widgetName, safeId, mjsContent, cssContent });
    } catch (e) {
      console.log(`경고: ${mpkFile} 처리 실패: ${e.message}`);
    }
  }

  // Pluggable 위젯 바인딩 (widget_ffi.mjs)
  if (widgets.length > 0) {
    const cssImports = widgets
      .filter((w) => w.cssContent)
      .map((w) => `import "./widgets/${w.safeId}.css";`)
      .join("\n");
    const mjsImports = widgets
      .map((w) => `import { ${w.safeId} } from "./widgets/${w.safeId}.mjs";`)
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
          writeFileSync(`${widgetsDir}/${w.safeId}.mjs`, w.mjsContent);
          if (w.cssContent) {
            writeFileSync(`${widgetsDir}/${w.safeId}.css`, w.cssContent);
          }
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

// 브릿지 JS 파일을 자동 생성하고 명령 실행 후 삭제
export function run_with_bridge(command) {
  // 바인딩 자동 갱신 (bindings.json 있을 때만)
  generate_bindings();

  // 위젯 바인딩 자동 갱신 (widgets/ 있을 때만)
  generate_widget_bindings();

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
