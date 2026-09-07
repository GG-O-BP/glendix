import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { useEffect } from "react";
import TestRenderer, { act } from "react-test-renderer";
import { toList } from "./gleam.mjs";
import {
  create_wasm_asset_plugin,
  render_rollup_config,
} from "./glendix/cmd_ffi.mjs";

function clone_list(list, clone) {
  return toList(list.toArray().map(clone));
}

function clone_attribute(attribute) {
  return { ...attribute };
}

function clone_node(node) {
  const cloned = { ...node };
  if (node.attributes) {
    cloned.attributes = clone_list(node.attributes, clone_attribute);
  }
  if (node.children) {
    cloned.children = clone_list(node.children, clone_node);
  }
  if (node.child) {
    cloned.child = clone_node(node.child);
  }
  if (node.view) {
    cloned.view = () => clone_node(node.view());
  }
  return cloned;
}

export function clone_lustre_tree(element) {
  return clone_node(element);
}

function collect_summary(element, parts) {
  if (element === null || element === undefined || element === false) return;
  if (typeof element === "string") {
    parts.push(element);
    return;
  }
  if (Array.isArray(element)) {
    for (const child of element) collect_summary(child, parts);
    return;
  }
  if (!element.props) return;
  if (typeof element.type === "string") {
    const id = element.props.id ? `#${element.props.id}` : "";
    parts.push(element.type + id);
  }
  collect_summary(element.props.children, parts);
}

export function rendered_tree_summary(element) {
  const parts = [];
  collect_summary(element, parts);
  return parts.join("|");
}

export function test_component() {
  return "section";
}

export function generated_rollup_config_source(withSecondaryWidget) {
  return render_rollup_config(withSecondaryWidget ? ["SecondaryWidget"] : []);
}

function wasmAst(source, specifiers) {
  return {
    type: "Program",
    body: specifiers.map(specifier => {
      const expression = `new URL(${JSON.stringify(specifier)}, import.meta.url)`;
      const start = source.indexOf(expression);
      if (start === -1) throw new Error(`Missing test expression: ${expression}`);
      return {
        type: "ExpressionStatement",
        expression: {
          type: "NewExpression",
          start,
          end: start + expression.length,
          callee: { type: "Identifier", name: "URL" },
          arguments: [
            { type: "Literal", value: specifier },
            {
              type: "MemberExpression",
              computed: false,
              object: {
                type: "MetaProperty",
                meta: { name: "import" },
                property: { name: "meta" },
              },
              property: { type: "Identifier", name: "url" },
            },
          ],
        },
      };
    }),
  };
}

function transformWasmFixture(outputFormat, specifiers) {
  const directory = mkdtempSync(join(tmpdir(), "glendix-wasm-test-"));
  try {
    const modulePath = join(directory, "module.mjs");
    writeFileSync(join(directory, "engine.wasm"), Buffer.from([0, 97, 115, 109]));
    const source = specifiers
      .map(specifier => `new URL(${JSON.stringify(specifier)}, import.meta.url)`)
      .join(";\n");
    const emitted = [];
    const plugin = create_wasm_asset_plugin(
      outputFormat,
      `/workspace/dist/tmp/widgets/example/widget/Widget.${outputFormat === "es" ? "mjs" : "js"}`,
    );
    const result = plugin.transform.call(
      {
        parse: () => wasmAst(source, specifiers),
        emitFile: asset => emitted.push(asset),
        error: message => {
          throw new Error(message);
        },
      },
      source,
      modulePath,
    );
    return `${emitted.length}\n${emitted[0]?.fileName ?? ""}\n${result?.code ?? ""}`;
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

export function wasm_asset_es_transform_summary() {
  return transformWasmFixture("es", ["engine.wasm", "engine.wasm?cache=1#ready"]);
}

export function wasm_asset_amd_transform_summary() {
  return transformWasmFixture("amd", ["./engine.wasm"]);
}

export function wasm_asset_noop_contract() {
  const plugin = create_wasm_asset_plugin(
    "es",
    "/workspace/dist/tmp/widgets/example/widget/Widget.mjs",
  );
  return plugin.transform.call(
    {
      parse: () => ({ type: "Program", body: [] }),
      emitFile: () => {
        throw new Error("No asset should be emitted");
      },
    },
    "const value = 1;",
    "/workspace/module.mjs",
  ) === null;
}

export function wasm_asset_missing_error() {
  const directory = mkdtempSync(join(tmpdir(), "glendix-wasm-test-"));
  try {
    const source = 'new URL("missing.wasm", import.meta.url)';
    const plugin = create_wasm_asset_plugin(
      "es",
      "/workspace/dist/tmp/widgets/example/widget/Widget.mjs",
    );
    try {
      plugin.transform.call(
        {
          parse: () => wasmAst(source, ["missing.wasm"]),
          emitFile: () => undefined,
          error: message => {
            throw new Error(message);
          },
        },
        source,
        join(directory, "module.mjs"),
      );
      return "";
    } catch (error) {
      return error instanceof Error ? error.message : String(error);
    }
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

export function process_exit_code() {
  return process.exitCode ?? 0;
}

export function reset_process_exit_code() {
  process.exitCode = 0;
}

// Installs a deterministic `matchMedia` stub so color-scheme mapping is tested
// without a real browser. Each installer sets the full global state, so the
// tests do not depend on execution order.
function install_match_media(preference) {
  globalThis.matchMedia = query => {
    const wants_dark = query.includes("dark");
    const wants_light = query.includes("light");
    let matches = false;
    if (preference === "dark") matches = wants_dark;
    else if (preference === "light") matches = wants_light;
    return { matches };
  };
}

export function stub_prefers_dark() {
  install_match_media("dark");
}

export function stub_prefers_light() {
  install_match_media("light");
}

export function stub_prefers_none() {
  // matchMedia is present but neither query matches (no explicit preference).
  install_match_media("none");
}

export function clear_match_media() {
  delete globalThis.matchMedia;
}

export function object_json(object) {
  return JSON.stringify(object);
}

export function element_prop_json(element, key) {
  return JSON.stringify(element.props[key]);
}

export function element_prop_is(element, key, expected) {
  return element.props[key] === expected;
}

export function new_promise_callback_counter() {
  return { count: 0 };
}

export function increment_promise_callback_counter(counter) {
  counter.count += 1;
}

export function promise_callback_count(counter) {
  return counter.count;
}

export function promise_rejection_is_error(rejection) {
  return rejection instanceof Error;
}

export function promise_rejection_message(rejection) {
  return rejection instanceof Error ? rejection.message : String(rejection);
}

let keyedHostMountCount = 0;
let keyedHostUnmountCount = 0;
let keyedHostProps = [];

export function record_keyed_host_props(props) {
  keyedHostProps.push(props);
}

export function track_keyed_host_lifecycle() {
  useEffect(() => {
    keyedHostMountCount += 1;
    return () => {
      keyedHostUnmountCount += 1;
    };
  }, []);
}

function rendered_text(renderer) {
  const json = renderer.toJSON();
  if (!json || Array.isArray(json)) return "";
  return json.children?.join("") ?? "";
}

export function keyed_host_lifecycle_summary(keyedHost, render) {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
  keyedHostMountCount = 0;
  keyedHostUnmountCount = 0;
  keyedHostProps = [];

  let renderer;
  act(() => {
    renderer = TestRenderer.create(keyedHost("", "first", render));
  });
  const initial =
    `${keyedHostMountCount}/${keyedHostUnmountCount}:${rendered_text(renderer)}`;

  act(() => {
    renderer.update(keyedHost("", "fresh", render));
  });
  const unchanged =
    `${keyedHostMountCount}/${keyedHostUnmountCount}:${rendered_text(renderer)}`;

  act(() => {
    renderer.update(keyedHost("replacement", "replacement", render));
  });
  const changed =
    `${keyedHostMountCount}/${keyedHostUnmountCount}:${rendered_text(renderer)}`;

  act(() => {
    renderer.unmount();
  });

  return [
    `initial=${initial}`,
    `unchanged=${unchanged}`,
    `changed=${changed}`,
    `props=${keyedHostProps.join(",")}`,
    `cleanup=${keyedHostUnmountCount}`,
  ].join(";");
}

function collect_rendered_summary(node, parts) {
  if (node === null || node === undefined || node === false) return;
  if (typeof node === "string") {
    parts.push(node);
    return;
  }
  if (Array.isArray(node)) {
    for (const child of node) collect_rendered_summary(child, parts);
    return;
  }
  if (typeof node.type === "string") parts.push(node.type);
  collect_rendered_summary(node.children, parts);
}

export function keyed_host_nested_summary(keyedHost, render) {
  globalThis.IS_REACT_ACT_ENVIRONMENT = true;
  let renderer;
  act(() => {
    renderer = TestRenderer.create(keyedHost("", undefined, render));
  });
  const parts = [];
  collect_rendered_summary(renderer.toJSON(), parts);
  act(() => {
    renderer.unmount();
  });
  return parts.join("|");
}
