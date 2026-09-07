// Plinth 0.11.0 binds the picker operation itself but does not expose
// capability detection. Keep this adapter to the single missing predicate so
// unsupported runtimes are reported before Plinth attempts the browser call.
export function modern_picker_is_available() {
  return typeof globalThis.showOpenFilePicker === "function";
}
