import { expect, mock, test } from "bun:test";

const calls = [];
let failure = null;

function record(name, arguments_) {
  if (failure !== null) throw failure;
  calls.push([name, ...arguments_]);
}

mock.module("@mendix/pluggable-widgets-tools", () => ({
  hidePropertyIn(...arguments_) {
    record("hidePropertyIn", arguments_);
  },
  hidePropertiesIn(...arguments_) {
    record("hidePropertiesIn", arguments_);
  },
  hideNestedPropertiesIn(...arguments_) {
    record("hideNestedPropertiesIn", arguments_);
  },
  transformGroupsIntoTabs(...arguments_) {
    record("transformGroupsIntoTabs", arguments_);
  },
  moveProperty(...arguments_) {
    record("moveProperty", arguments_);
  },
}));

const editorConfig = await import("../src/glendix/editor_config_ffi.mjs");

test("editor config adapters preserve calls and the properties handle", () => {
  calls.length = 0;
  failure = null;
  const properties = { groups: [] };

  expect(editorConfig.hide_property_in(properties, "title")).toBe(properties);
  expect(
    editorConfig.hide_properties_in(properties, "first, second, ,third"),
  ).toBe(properties);
  expect(
    editorConfig.hide_nested_property_in(properties, "rows", 2, "caption"),
  ).toBe(properties);
  expect(
    editorConfig.hide_nested_properties_in(
      properties,
      "rows",
      3,
      "first, second, ",
    ),
  ).toBe(properties);
  expect(editorConfig.transform_groups_into_tabs(properties)).toBe(properties);
  expect(editorConfig.move_property(properties, 4, 1)).toBe(properties);

  expect(calls).toEqual([
    ["hidePropertyIn", properties, {}, "title"],
    ["hidePropertyIn", properties, {}, "first"],
    ["hidePropertyIn", properties, {}, "second"],
    ["hidePropertyIn", properties, {}, "third"],
    ["hidePropertyIn", properties, {}, "rows", 2, "caption"],
    ["hidePropertyIn", properties, {}, "rows", 3, "first"],
    ["hidePropertyIn", properties, {}, "rows", 3, "second"],
    ["transformGroupsIntoTabs", properties],
    ["moveProperty", 4, 1, properties],
  ]);
});

test("editor config adapters preserve Mendix helper exceptions", () => {
  calls.length = 0;
  failure = new Error("editor config failed");
  const properties = { groups: [] };

  expect(() => editorConfig.hide_property_in(properties, "title")).toThrow(
    "editor config failed",
  );

  failure = null;
});
