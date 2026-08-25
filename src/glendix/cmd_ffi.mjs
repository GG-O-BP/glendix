import { execSync, spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { delimiter, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Some, None } from "../../gleam_stdlib/gleam/option.mjs";
import { Ok, Error as GleamError } from "../gleam.mjs";

const EXPERIMENTAL_NATIVE_MODE = "experimental-native";
const EXPERIMENTAL_NATIVE_RUNNER = "--glendix-experimental-native-runner";
const EXPERIMENTAL_NATIVE_SHIM = "--glendix-experimental-native-shim";
const PWT_NODE_VERSION = "v22.18.0";
const PWT_NPM_VERSION = "11.6.2";

function errorMessage(error) {
  return error instanceof globalThis.Error ? error.message : String(error);
}

export function command_error_message(error) {
  return errorMessage(error);
}
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
  const result = { pm: null, compatibility: null, bindings: {} };
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
      if (key === "compatibility") result.compatibility = value;
    } else if (currentSection === "bindings") {
      result.bindings[key] = value;
    }
  }
  return result;
}
function readPmOverride() {
  const config = parseGlendixToml();
  return config?.pm ? new Some(config.pm) : new None();
}

export function read_pm_override() {
  try {
    return new Ok(readPmOverride());
  } catch (error) {
    return new GleamError(error);
  }
}

export function read_experimental_native_mode() {
  try {
    const compatibility = parseGlendixToml()?.compatibility;
    if (compatibility === null || compatibility === undefined) {
      return new Ok(false);
    }
    if (compatibility !== EXPERIMENTAL_NATIVE_MODE) {
      throw new Error(
        `Unsupported [tools.glendix].compatibility value: ${compatibility}`,
      );
    }
    return new Ok(true);
  } catch (error) {
    return new GleamError(error);
  }
}
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
function execOrThrow(command) {
  if (command.startsWith("gleam ")) {
    execGleamFiltered(command);
  } else {
    execSync(command, { stdio: "inherit", shell: true });
  }
}

export function exec(command) {
  try {
    execOrThrow(command);
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}
export function file_exists(path) {
  return existsSync(path);
}
function generateBindingsOrThrow() {
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
    `// Generated by glendix/install. Do not edit manually.\n` +
    `import { Ok, Error as GleamError } from "../gleam.mjs";\n` +
    `import { createElement } from "react";\n` +
    imports.join("\n") +
    "\n\n" +
    `const _modules = {\n${entries.join(",\n")}\n};\n\n` +
    `export function get_module(name) {\n` +
    `  const mod = _modules[name];\n` +
    `  if (!mod) return new GleamError("바인딩에 등록되지 않은 모듈: " + name + ". gleam.toml [tools.glendix.bindings]를 확인하세요.");\n` +
    `  return new Ok(mod);\n` +
    `}\n\n` +
    `export function resolve(mod, name) {\n` +
    `  const c = mod[name];\n` +
    `  if (c === undefined) return new GleamError("모듈에 없는 컴포넌트: " + name);\n` +
    `  return new Ok(c);\n` +
    `}\n\n` +
    `function toProps(attributes) {\n` +
    `  const props = {};\n` +
    `  const classNames = [];\n` +
    `  for (const attribute of attributes.toArray()) {\n` +
    `    if (attribute.key === "none_") continue;\n` +
    `    if (attribute.key === "className") classNames.push(attribute.content);\n` +
    `    else props[attribute.key] = attribute.content;\n` +
    `  }\n` +
    `  if (classNames.length > 0) props.className = classNames.join(" ");\n` +
    `  return props;\n` +
    `}\n\n` +
    `export function component_element(component, attributes, children) {\n` +
    `  return createElement(component, toProps(attributes), ...children.toArray());\n` +
    `}\n\n` +
    `export function component_element_without_attributes(component, children) {\n` +
    `  return createElement(component, null, ...children.toArray());\n` +
    `}\n\n` +
    `export function void_component_element(component, attributes) {\n` +
    `  return createElement(component, toProps(attributes));\n` +
    `}\n\n` +
    `export function binding_error_message(error) {\n` +
    `  return error instanceof globalThis.Error ? error.message : String(error);\n` +
    `}\n`;
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
      } catch (error) {
        console.warn(
          `[glendix] binding directory could not be created: ${dir}`,
          error,
        );
        continue;
      }
    }
    try {
      writeFileSync(target, content);
      written++;
    } catch (error) {
      console.warn(`[glendix] binding file could not be written: ${target}`, error);
    }
  }
  if (written > 0) {
    const moduleNames = Object.keys(config).join(", ");
    console.log(`바인딩 생성 완료: ${moduleNames}`);
  }
}

export function generate_bindings() {
  try {
    generateBindingsOrThrow();
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}

const forceCloseRollupHelper =
  `function closeAfterBuild(configs) {\n` +
  `  if (configs.length === 0) return configs;\n` +
  `  const lastIndex = configs.length - 1;\n` +
  `  const lastConfig = configs[lastIndex];\n` +
  `  const plugins = Array.isArray(lastConfig.plugins) ? lastConfig.plugins : [];\n` +
  `  return configs.map((config, index) => index === lastIndex ? {\n` +
  `    ...config,\n` +
  `    plugins: [\n` +
  `      ...plugins,\n` +
  `      {\n` +
  `        name: "glendix-force-close",\n` +
  `        closeBundle() {\n` +
  `          if (!process.env.ROLLUP_WATCH) {\n` +
  `            setTimeout(() => process.exit(0));\n` +
  `          }\n` +
  `        },\n` +
  `      },\n` +
  `    ],\n` +
  `  } : config);\n` +
  `}\n\n`;

export function render_rollup_config(secondaryWidgets) {
  if (secondaryWidgets.length > 0) {
    return `import { readFileSync } from "node:fs";\n\n` +
      forceCloseRollupHelper +
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
      `  return closeAfterBuild(result);\n` +
      `};\n`;
  }

  return forceCloseRollupHelper +
    `export default args => {\n` +
    `  const configs = args.configDefaultConfig;\n` +
    `  const result = configs.map(config => {\n` +
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
    `  return closeAfterBuild(result);\n` +
    `};\n`;
}

export function fail_process() {
  process.exitCode = 1;
}

function setupBridge() {
  generateBindingsOrThrow();
  execGleamFiltered("gleam build");
  const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
  const widgetName = pkg.widgetName;
  const widgets = pkg.widgets;
  const gleamProject = readFileSync("gleam.toml", "utf-8").match(/^name\s*=\s*"([^"]+)"/m)[1];
  const gleamModule = gleamProject.replace(/-/g, "_");
  const bridgeFiles = [];
  if (widgets) {
    for (const [componentName, fnName] of Object.entries(widgets)) {
      const bridge = `src/${componentName}.js`;
      let cssLine = "";
      if (existsSync(`src/ui/${componentName}.css`)) {
        cssLine = `import "./ui/${componentName}.css";\n`;
      } else if (existsSync(`src/ui/${widgetName}.css`)) {
        cssLine = `import "./ui/${widgetName}.css";\n`;
      }
      writeFileSync(bridge,
        `// Generated Glendix bridge. Do not edit manually.\n` +
        `import { ${fnName} } from "../build/dev/javascript/${gleamProject}/${gleamModule}.mjs";\n` +
        cssLine + `\n` +
        `export const ${componentName} = ${fnName};\n`
      );
      bridgeFiles.push(bridge);
      const editorBridge = `src/${componentName}.editorConfig.js`;
      if (existsSync(`src/${fnName}_editor_config.gleam`)) {
        writeFileSync(editorBridge,
          `// Generated Glendix bridge. Do not edit manually.\n` +
          `import { get_properties } from "../build/dev/javascript/${gleamProject}/${fnName}_editor_config.mjs";\n\n` +
          `export const getProperties = get_properties;\n`
        );
        bridgeFiles.push(editorBridge);
      } else if (existsSync("src/editor_config.gleam")) {
        writeFileSync(editorBridge,
          `// Generated Glendix bridge. Do not edit manually.\n` +
          `import { get_properties } from "../build/dev/javascript/${gleamProject}/editor_config.mjs";\n\n` +
          `export const getProperties = get_properties;\n`
        );
        bridgeFiles.push(editorBridge);
      }
      const previewBridge = `src/${componentName}.editorPreview.js`;
      if (existsSync(`src/${fnName}_editor_preview.gleam`)) {
        writeFileSync(previewBridge,
          `// Generated Glendix bridge. Do not edit manually.\n` +
          `import { preview } from "../build/dev/javascript/${gleamProject}/${fnName}_editor_preview.mjs";\n\n` +
          `export { preview };\n` +
          `export function getPreviewCss() {\n` +
          `  return require("./ui/${componentName}.css");\n` +
          `}\n`
        );
        bridgeFiles.push(previewBridge);
      } else if (existsSync("src/editor_preview.gleam")) {
        writeFileSync(previewBridge,
          `// Generated Glendix bridge. Do not edit manually.\n` +
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
    const widgetBridge = `src/${widgetName}.js`;
    writeFileSync(widgetBridge,
      `// Generated Glendix bridge. Do not edit manually.\n` +
      `import { widget } from "../build/dev/javascript/${gleamProject}/${gleamModule}.mjs";\n` +
      `import "./ui/${widgetName}.css";\n\n` +
      `export const ${widgetName} = widget;\n`
    );
    bridgeFiles.push(widgetBridge);
    if (existsSync("src/editor_config.gleam")) {
      const editorBridge = `src/${widgetName}.editorConfig.js`;
      writeFileSync(editorBridge,
        `// Generated Glendix bridge. Do not edit manually.\n` +
        `import { get_properties } from "../build/dev/javascript/${gleamProject}/editor_config.mjs";\n\n` +
        `export const getProperties = get_properties;\n`
      );
      bridgeFiles.push(editorBridge);
    }
    if (existsSync("src/editor_preview.gleam")) {
      const previewBridge = `src/${widgetName}.editorPreview.js`;
      writeFileSync(previewBridge,
        `// Generated Glendix bridge. Do not edit manually.\n` +
        `import { preview } from "../build/dev/javascript/${gleamProject}/editor_preview.mjs";\n\n` +
        `export { preview };\n` +
        `export function getPreviewCss() {\n` +
        `  return require("./ui/${widgetName}.css");\n` +
        `}\n`
      );
      bridgeFiles.push(previewBridge);
    }
  }
  const rollupConfig = "rollup.config.mjs";
  const hasCustomRollup = existsSync(rollupConfig);
  if (!hasCustomRollup) {
    const secondaryWidgets = widgets
      ? Object.keys(widgets).filter(name => name !== widgetName)
      : [];
    writeFileSync(
      rollupConfig,
      `// Generated by Glendix. Do not edit manually.\n` +
      render_rollup_config(secondaryWidgets),
    );
    bridgeFiles.push(rollupConfig);
  }
  const cleanup = () => {
    for (const f of bridgeFiles) {
      try { unlinkSync(f); } catch (error) { console.warn(`[glendix] bridge cleanup failed: ${f}`, error); }
    }
  };
  return { cleanup, widgetBridge: `src/${widgetName}.js` };
}
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

function splitCommandArguments(args) {
  if (args.trim() === "") return [];
  const matches = args.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? [];
  return matches.map(argument => {
    if (
      (argument.startsWith('"') && argument.endsWith('"'))
      || (argument.startsWith("'") && argument.endsWith("'"))
    ) {
      return argument.slice(1, -1);
    }
    return argument;
  });
}

function findExecutable(name) {
  const pathValue = process.env.PATH ?? process.env.Path ?? "";
  const extensions = process.platform === "win32"
    ? (process.env.PATHEXT ?? ".COM;.EXE;.BAT;.CMD").split(";")
    : [""];
  let lastInspectionError;
  for (const directory of pathValue.split(delimiter)) {
    if (!directory) continue;
    for (const extension of extensions) {
      const candidate = join(directory, name + extension.toLowerCase());
      const uppercaseCandidate = join(directory, name + extension.toUpperCase());
      for (const path of [candidate, uppercaseCandidate]) {
        try {
          if (existsSync(path) && statSync(path).isFile()) return path;
        } catch (error) {
          lastInspectionError = error;
        }
      }
    }
  }
  throw new Error(
    `Cannot find required experimental-native executable: ${name}`,
    { cause: lastInspectionError },
  );
}

function runtimeNameForPackageManager(packageManager) {
  switch (packageManager) {
    case "bun": return "bun";
    case "deno": return "deno";
    case "npm":
    case "yarn":
    case "pnpm":
      return "node";
    default:
      throw new Error(`Unsupported experimental-native package manager: ${packageManager}`);
  }
}

function runtimeArguments(runtimeName, scriptPath, args) {
  if (runtimeName === "deno") {
    return [
      "run",
      "-A",
      "--node-modules-dir=manual",
      scriptPath,
      ...args,
    ];
  }
  return [scriptPath, ...args];
}

function shellQuote(value) {
  return `'${String(value).replaceAll("'", `'"'"'`)}'`;
}

function commandQuote(value) {
  return `"${String(value).replaceAll('"', '""')}"`;
}

function renderShim(runtimeExecutable, runtimeName, modulePath, shimName) {
  const args = runtimeArguments(
    runtimeName,
    modulePath,
    [EXPERIMENTAL_NATIVE_SHIM, shimName],
  );
  if (process.platform === "win32") {
    const command = [runtimeExecutable, ...args].map(commandQuote).join(" ");
    return `@echo off\r\n${command} %*\r\nexit /b %errorlevel%\r\n`;
  }
  const command = [runtimeExecutable, ...args].map(shellQuote).join(" ");
  return `#!/bin/sh\nexec ${command} "$@"\n`;
}

function writeShim(directory, name, runtimeExecutable, runtimeName, modulePath) {
  const filename = process.platform === "win32" ? `${name}.cmd` : name;
  const path = join(directory, filename);
  writeFileSync(
    path,
    renderShim(runtimeExecutable, runtimeName, modulePath, name),
    "utf-8",
  );
  if (process.platform !== "win32") chmodSync(path, 0o700);
}

function resolvePluggableWidgetsToolsBin() {
  const directPackageJson = join(
    process.cwd(),
    "node_modules",
    "@mendix",
    "pluggable-widgets-tools",
    "package.json",
  );
  let packageJsonPath = directPackageJson;
  if (!existsSync(packageJsonPath)) {
    const projectRequire = createRequire(join(process.cwd(), "package.json"));
    packageJsonPath = projectRequire.resolve(
      "@mendix/pluggable-widgets-tools/package.json",
    );
  }
  const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));
  const bin = typeof packageJson.bin === "string"
    ? packageJson.bin
    : packageJson.bin?.["pluggable-widgets-tools"];
  if (!bin) {
    throw new Error(
      "@mendix/pluggable-widgets-tools does not declare its CLI binary",
    );
  }
  const path = join(dirname(packageJsonPath), bin);
  if (!existsSync(path)) {
    throw new Error(`Cannot find Pluggable Widgets Tools CLI: ${path}`);
  }
  return path;
}

function createExperimentalNativeEnvironment(packageManager) {
  const runtimeName = runtimeNameForPackageManager(packageManager);
  const runtimeExecutable = findExecutable(runtimeName);
  const managerExecutable = findExecutable(packageManager);
  const shimDirectory = mkdtempSync(
    join(tmpdir(), "glendix-experimental-native-"),
  );
  const modulePath = fileURLToPath(import.meta.url);
  try {
    for (const shimName of ["node", "npm", "npx"]) {
      writeShim(
        shimDirectory,
        shimName,
        runtimeExecutable,
        runtimeName,
        modulePath,
      );
    }
  } catch (error) {
    rmSync(shimDirectory, { recursive: true, force: true });
    throw error;
  }
  const originalPath = process.env.PATH ?? process.env.Path ?? "";
  const scopedPath = [shimDirectory, originalPath].filter(Boolean).join(delimiter);
  return {
    cleanup() {
      rmSync(shimDirectory, { recursive: true, force: true });
    },
    environment: {
      ...process.env,
      CI: "true",
      PATH: scopedPath,
      Path: scopedPath,
      GLENDIX_EXPERIMENTAL_NATIVE_PM: packageManager,
      GLENDIX_EXPERIMENTAL_NATIVE_RUNTIME: runtimeName,
      GLENDIX_EXPERIMENTAL_NATIVE_RUNTIME_EXECUTABLE: runtimeExecutable,
      GLENDIX_EXPERIMENTAL_NATIVE_MANAGER_EXECUTABLE: managerExecutable,
    },
    runtimeExecutable,
    runtimeName,
  };
}

function writeProcessOutput(result) {
  if (result.stdout && result.stdout.length > 0) process.stdout.write(result.stdout);
  if (result.stderr && result.stderr.length > 0) {
    const filtered = filterBabelNotes(result.stderr.toString());
    if (filtered) process.stderr.write(filtered + "\n");
  }
}

function runExperimentalNativeProcessOrThrow(packageManager, args) {
  const scoped = createExperimentalNativeEnvironment(packageManager);
  try {
    const modulePath = fileURLToPath(import.meta.url);
    const toolPath = resolvePluggableWidgetsToolsBin();
    const runtimeArgs = runtimeArguments(scoped.runtimeName, modulePath, [
      EXPERIMENTAL_NATIVE_RUNNER,
      toolPath,
      ...splitCommandArguments(args),
    ]);
    console.log(
      `[glendix] experimental-native (${packageManager}): `
      + "using scoped Node/npm compatibility shims",
    );
    const result = spawnSync(scoped.runtimeExecutable, runtimeArgs, {
      env: scoped.environment,
      stdio: ["inherit", "pipe", "pipe"],
    });
    writeProcessOutput(result);
    if (result.error) throw result.error;
    if (result.status !== 0) {
      const error = new Error(
        `experimental-native Pluggable Widgets Tools failed for ${packageManager}`,
      );
      error.status = result.status;
      throw error;
    }
  } finally {
    scoped.cleanup();
  }
}

function spawnShimProcess(executable, args) {
  const shell = process.platform === "win32"
    && /\.(?:cmd|bat)$/i.test(executable);
  const result = spawnSync(executable, args, {
    env: process.env,
    shell,
    stdio: "inherit",
  });
  if (result.error) {
    console.error(`[glendix] experimental-native shim failed: ${errorMessage(result.error)}`);
    return 1;
  }
  return result.status ?? 1;
}

function npmInstallInvocation(packageManager, managerExecutable, args) {
  if (args.includes("--package-lock-only")) {
    throw new Error(
      "experimental-native does not emulate npm --package-lock-only; "
      + `use ${packageManager}'s lockfile command directly`,
    );
  }
  switch (packageManager) {
    case "npm": return [managerExecutable, ["install", ...args]];
    case "yarn": return [managerExecutable, ["install", ...args]];
    case "pnpm": return [managerExecutable, ["install", ...args]];
    case "bun": return [managerExecutable, ["install", ...args]];
    case "deno":
      return [managerExecutable, [
        "install",
        "--node-modules-dir=manual",
        "--node-modules-linker=hoisted",
        "--allow-scripts=npm:@parcel/watcher,npm:@swc/core,npm:core-js,npm:unrs-resolver",
        ...args,
      ]];
    default:
      throw new Error(`Unsupported npm install adapter: ${packageManager}`);
  }
}

function npmRunInvocation(packageManager, managerExecutable, args) {
  switch (packageManager) {
    case "deno": return [managerExecutable, ["task", ...args]];
    case "npm":
    case "yarn":
    case "pnpm":
    case "bun":
      return [managerExecutable, ["run", ...args]];
    default:
      throw new Error(`Unsupported npm run adapter: ${packageManager}`);
  }
}

function npmExecInvocation(packageManager, managerExecutable, args) {
  switch (packageManager) {
    case "npm": return [managerExecutable, ["exec", ...args]];
    case "yarn": return [managerExecutable, ["exec", ...args]];
    case "pnpm": return [managerExecutable, ["exec", ...args]];
    case "bun": return [managerExecutable, ["x", ...args]];
    case "deno": {
      const [packageName, ...packageArgs] = args;
      if (!packageName) {
        throw new Error("experimental-native npx adapter requires a package name");
      }
      return [managerExecutable, [
        "x",
        "-A",
        "-p",
        packageName,
        packageName,
        ...packageArgs,
      ]];
    }
    default:
      throw new Error(`Unsupported npm exec adapter: ${packageManager}`);
  }
}

function runNpmShim(args) {
  if (["--version", "-v", "version"].includes(args[0])) {
    console.log(PWT_NPM_VERSION);
    return 0;
  }
  const packageManager = process.env.GLENDIX_EXPERIMENTAL_NATIVE_PM;
  const managerExecutable =
    process.env.GLENDIX_EXPERIMENTAL_NATIVE_MANAGER_EXECUTABLE;
  if (!packageManager || !managerExecutable) {
    throw new Error("experimental-native npm shim environment is incomplete");
  }
  const [command, ...commandArgs] = args;
  let invocation;
  switch (command) {
    case "install":
    case "i":
      invocation = npmInstallInvocation(
        packageManager,
        managerExecutable,
        commandArgs,
      );
      break;
    case "run":
      invocation = npmRunInvocation(packageManager, managerExecutable, commandArgs);
      break;
    case "exec":
    case "x":
      invocation = npmExecInvocation(packageManager, managerExecutable, commandArgs);
      break;
    default:
      throw new Error(
        `experimental-native does not emulate npm ${command ?? ""}`.trim(),
      );
  }
  return spawnShimProcess(invocation[0], invocation[1]);
}

function runNodeShim(args) {
  if (["--version", "-v"].includes(args[0])) {
    console.log(PWT_NODE_VERSION);
    return 0;
  }
  const runtimeExecutable =
    process.env.GLENDIX_EXPERIMENTAL_NATIVE_RUNTIME_EXECUTABLE;
  const runtimeName = process.env.GLENDIX_EXPERIMENTAL_NATIVE_RUNTIME;
  if (!runtimeExecutable || !runtimeName) {
    throw new Error("experimental-native node shim environment is incomplete");
  }
  if (args.length === 0) {
    throw new Error("experimental-native node shim requires a script path");
  }
  const [scriptPath, ...scriptArgs] = args;
  return spawnShimProcess(
    runtimeExecutable,
    runtimeArguments(runtimeName, scriptPath, scriptArgs),
  );
}

function runExperimentalNativeShim(shimName, args) {
  try {
    if (shimName === "node") return runNodeShim(args);
    if (shimName === "npm") return runNpmShim(args);
    if (shimName === "npx") {
      const packageManager = process.env.GLENDIX_EXPERIMENTAL_NATIVE_PM;
      const managerExecutable =
        process.env.GLENDIX_EXPERIMENTAL_NATIVE_MANAGER_EXECUTABLE;
      if (!packageManager || !managerExecutable) {
        throw new Error("experimental-native npx shim environment is incomplete");
      }
      const invocation = npmExecInvocation(
        packageManager,
        managerExecutable,
        args,
      );
      return spawnShimProcess(invocation[0], invocation[1]);
    }
    throw new Error(`Unknown experimental-native shim: ${shimName}`);
  } catch (error) {
    console.error(`[glendix] ${errorMessage(error)}`);
    return 1;
  }
}

function startExperimentalNativeRunner(toolPath, args) {
  const require = createRequire(import.meta.url);
  process.argv = [process.execPath, toolPath, ...args];
  require(toolPath);
}

function runWithBridgeOrThrow(command) {
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

export function run_with_bridge(command) {
  try {
    runWithBridgeOrThrow(command);
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}

export function run_experimental_native(packageManager, args) {
  try {
    runExperimentalNativeProcessOrThrow(packageManager, args);
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}

export function run_experimental_native_with_bridge(packageManager, args) {
  const { cleanup } = setupBridge();
  process.on("SIGINT", () => { cleanup(); process.exit(130); });
  try {
    runExperimentalNativeProcessOrThrow(packageManager, args);
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  } finally {
    cleanup();
  }
}

function runDevWithBridgeUsing(execBuild) {
  const { cleanup } = setupBridge();
  console.log("[glendix] 초기 빌드 시작\n");
  try {
    execBuild();
  } catch (error) {
    cleanup();
    throw error;
  }
  console.log("\n[glendix] .gleam 파일 변경 감지 활성화 — 저장 시 자동 빌드\n");
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
        } catch (error) {
          console.warn(`[glendix] could not inspect source path: ${p}`, error);
        }
      }
    } catch (error) {
      console.warn(`[glendix] could not scan source directory: ${dir}`, error);
    }
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
          } catch (error) {
            console.warn(`[glendix] could not inspect source path: ${p}`, error);
          }
        }
      } catch (error) {
        console.warn(`[glendix] could not scan source directory: ${dir}`, error);
      }
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
    } catch (error) {
      console.error("[glendix] rebuild failed", error);
    }
  }, 500);
  process.on("SIGINT", () => {
    clearInterval(pollId);
    cleanup();
    process.exit(130);
  });
}

function runDevWithBridgeOrThrow(buildCommand) {
  runDevWithBridgeUsing(() => {
    const result = spawnSync(buildCommand, {
      shell: true,
      stdio: ["inherit", "pipe", "pipe"],
    });
    writeProcessOutput(result);
    if (result.error) throw result.error;
    if (result.status !== 0) throw new Error("Build failed");
  });
}

export function run_dev_with_bridge(buildCommand) {
  try {
    runDevWithBridgeOrThrow(buildCommand);
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}

export function run_experimental_native_dev_with_bridge(packageManager, args) {
  try {
    runDevWithBridgeUsing(() => {
      runExperimentalNativeProcessOrThrow(packageManager, args);
    });
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}

if (process.argv[2] === EXPERIMENTAL_NATIVE_SHIM) {
  const [, , , shimName, ...shimArgs] = process.argv;
  process.exit(runExperimentalNativeShim(shimName, shimArgs));
}

if (process.argv[2] === EXPERIMENTAL_NATIVE_RUNNER) {
  const [, , , toolPath, ...toolArgs] = process.argv;
  try {
    startExperimentalNativeRunner(toolPath, toolArgs);
  } catch (error) {
    console.error(`[glendix] experimental-native runner failed: ${errorMessage(error)}`);
    process.exit(1);
  }
}
