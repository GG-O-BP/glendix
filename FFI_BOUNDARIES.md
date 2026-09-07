# Glendix FFI boundary reference

This is the source-of-truth inventory for every Gleam `@external` declaration
shipped or tested by Glendix. It records the JavaScript contract, the reason a
boundary remains, the ecosystem work that replaced adjacent handwritten code,
and the tests that protect the behavior. The package CI runs
`scripts/check-ffi-contracts.py` so declarations, implementation exports, and
the exact mapping table at the end of this document cannot drift.

All production externals target JavaScript. Raw declarations remain private;
public callers use typed Gleam wrappers. A "package adapter" below means the
operation is primarily delegated to an ecosystem package, while a minimal FFI
cast, capability check, or semantic gap remains. "Retained" means no package
can provide the Glendix-specific contract without losing required behavior.

## Production contracts

### Generated npm binding host

- **Boundary:** `src/glendix/binding_ffi.mjs`.
- **Inputs and outputs:** configured module/export names become opaque
  `JsModule`/`JsComponent` handles; initialization returns a Promise in a
  `Result`; component helpers convert Redraw attribute/child lists into React
  elements.
- **Errors:** missing modules/exports, thrown initializers, and non-Promise
  initializer results become typed `BindingError` or `InitializationError`
  values. Rejection reasons and other raw values use one deterministic message
  conversion.
- **Retention:** generated package and export names are known only after
  Glendix has compiled, while `@external` literals must be compile-time
  constants. The generated host therefore keeps deterministic static imports
  and direct React creation. Issue #7 moved Promise sharing, retry state, and
  lifecycle handling into Gleam but cannot replace this generated boundary.
- **Coverage:** `binding_*` tests in `test/glendix_test.gleam` cover missing
  bindings, element props, static initializer generation, success, synchronous
  failure, rejected/non-Promise initialization, one-flight sharing, retry, and
  reset behavior.

### Command execution and Glendix build tooling

- **Boundaries:** `src/glendix/command_ffi.mjs` and
  `src/glendix/cmd_ffi.mjs`.
- **Inputs and outputs:** command strings execute synchronously and return
  `Result(Nil, CommandError)`; bridge operations consume the deterministic
  binding tuples parsed in Gleam; render/generate helpers produce or write
  binding and Rollup sources; `fail_process` marks the process unsuccessful.
- **Errors:** package-backed and custom runners convert thrown process failures
  to typed command errors and preserve actionable messages. The filtered Gleam
  runner inherits stdin, writes stdout, removes only the known Erlang warning
  block from stderr, and fails on a non-zero status. Bridge and native tooling
  clean temporary state in their existing success/failure paths.
- **Retention:** issue #20 moved the generic path to `shellout`. Platform shell
  selection, SIGINT-listener restoration, warning-filtered Gleam execution,
  bridge generation/cleanup, development watching, experimental-native setup,
  Node/npm shims, and Rollup/WASM asset rewriting have no package API with the
  same synchronous stream and build semantics.
- **Coverage:** `test/glendix/command_test.gleam` covers success, failure,
  shell syntax, filtering, and SIGINT cleanup. Command, binding-generation,
  process-exit, Rollup, and WASM tests in `test/glendix_test.gleam` cover the
  Glendix-specific tooling.

### Mendix Studio Pro editor configuration

- **Boundary:** `src/glendix/editor_config_ffi.mjs`.
- **Inputs and outputs:** an opaque Mendix `Properties` handle plus keys and
  indexes are passed to `@mendix/pluggable-widgets-tools`; each operation mutates
  that editor-owned structure and returns the identical handle for Gleam
  composition. Comma-separated key helpers trim entries and ignore empties.
- **Errors:** the public API has no `Result`; invalid handles, indexes, or
  underlying Mendix helper failures propagate as JavaScript exceptions, which
  preserves the existing editor-config contract.
- **Retention:** these are npm-only Mendix host operations with mutable runtime
  structures, not a portable Gleam/Hex capability. The FFI is the typed adapter
  to the official Mendix helpers rather than a reimplementation.
- **Coverage:** `test/editor_config_ffi_test.mjs` mocks the official helper
  module and verifies argument order, CSV trimming, nested paths, same-handle
  returns, and exception propagation for all six adapters. Full Mendix-host
  behavior remains owned by the upstream helper package.

### Raw terminal control

- **Boundary:** `src/glendix/internal/define/terminal_control_ffi.mjs`.
- **Inputs and outputs:** TTY detection returns `Bool`; raw-mode toggling returns
  `Result(Nil, RawModeError)`; polling returns one `#(code, text)` value in a
  Promise; decoding maps navigation, Enter, Backspace, Ctrl+C, Tab, Escape, and
  UTF-8 input to the established TUI encoding.
- **Errors and fallback:** unsupported or throwing `setRawMode` calls preserve a
  readable error. A positive timeout resolves with the empty key when no input
  arrives. Terminal size is no longer FFI: `term_size` owns it and Gleam keeps
  the 80x24 fallback.
- **Retention:** issue #18 found no reliable package for the runtime TTY probe,
  raw-mode lifecycle, shared stdin queue, or non-blocking one-shot polling.
- **Coverage:** `test/glendix/internal/define/terminal_control_test.gleam`
  covers terminal-size fallback, all key classes, unsupported/throwing raw
  mode, enable/disable lifecycle, queued input, and timeout behavior.

### DOM compatibility adapter

- **Boundary:** `src/glendix/js/dom_ffi.mjs`.
- **Inputs and outputs:** identity casts preserve Glendix's public DOM element
  and rectangle handles while Plinth owns focus, blur, rectangle lookup, and
  selector lookup. The two direct operations invoke native `click()` and
  default `scrollIntoView()` and return `Nil`.
- **Errors:** selector miss maps to `None`; native DOM exceptions from malformed
  handles/selectors or direct method calls propagate, matching the previous
  API.
- **Retention:** Plinth 0.11.0 has no `HTMLElement.click` binding and its scroll
  helper forces options that differ from the platform defaults. Issue #17
  reduced the boundary to these gaps and zero-cost handle casts.
- **Coverage:** `test/glendix/js/dom_test.gleam` covers every operation,
  including selector hit/miss and rectangle fields.

### Browser environment

- **Boundary:** `src/glendix/js/environment_ffi.mjs`.
- **Inputs and outputs:** zero-argument queries report `matchMedia` capability
  and dark/light query matches as booleans; Gleam converts them to
  `ColorScheme` and `ResolvedColorScheme`.
- **Errors and fallback:** absent or non-callable `matchMedia`, null results, and
  missing `matches` fields are non-error false values. If a callable host
  implementation itself throws, that exception propagates.
- **Retention:** no selected package exposes the exact capability-aware
  `prefers-color-scheme` adapter needed in browsers and DOM-free runtimes.
  Issue #9 deliberately kept this small boundary instead of requiring each
  widget to own local FFI.
- **Coverage:** environment tests in `test/glendix_test.gleam` cover dark,
  light, no preference, and unavailable `matchMedia`.

### Browser file picker capability

- **Boundary:** `src/glendix/js/file_ffi.mjs`.
- **Inputs and outputs:** `modern_picker_is_available` returns true only when
  `globalThis.showOpenFilePicker` is callable. It does not open a picker, touch
  a file handle, read bytes, construct DOM, or trigger a click.
- **Errors and fallback:** capability absence becomes typed
  `PickerUnsupported` before any browser call. Picker/open/read failures are
  mapped by the Plinth-backed Gleam path; download object URLs are owned and
  released through Gossamer.
- **Retention:** Plinth 0.11.0 provides picker and file operations but no
  capability predicate. Issue #8 retained only this missing query.
- **Coverage:** `test/glendix/js/file_test.gleam` covers unsupported hosts,
  cancellation, open/select/read failures, empty/max-size/type validation,
  ordering, and object-URL lifetime. `BROWSER_FILE_CAPABILITIES.md` holds the
  user-facing capability contract.

### Plain JavaScript data objects

- **Boundary:** `src/glendix/js/object_ffi.mjs`.
- **Inputs and outputs:** typed scalars and object handles are identity-cast to
  opaque `JsValue`; ordered `List(#(String, JsValue))` entries become a live
  plain object; `empty` returns a new ordinary object.
- **Errors:** valid typed inputs have no domain error. Duplicate keys keep the
  final value. `Object.fromEntries` defines `__proto__` as an own data property
  rather than invoking the legacy prototype setter.
- **Retention:** no evaluated Gleam package builds a live, general,
  prototype-safe JavaScript object; JSON encoding would be lossy for handles.
  Issue #19 isolated this safe data construction from dynamic reflection.
- **Coverage:** `test/glendix/js/object_test.gleam` covers ordering, empty
  objects, duplicate keys, supported value shapes, normal prototypes, and the
  `__proto__` guarantee.

### Promise semantic gaps

- **Boundary:** `src/glendix/js/promise_ffi.mjs`.
- **Inputs and outputs:** `reject` creates a rejected Promise whose reason is a
  JavaScript `Error`; `catch_` receives the opaque rejection and returns a
  Promise-producing recovery callback whose result is flattened by native
  Promise semantics.
- **Errors:** rejection is data at this boundary and is not swallowed. Callback
  throws or returned Promise rejection follow normal JavaScript Promise rules.
- **Retention:** issue #12 delegated resolve, map, await/then, all, and race to
  `gleam/javascript/promise`. That package has neither an error-wrapping reject
  constructor nor Promise-returning rescue with the established opaque reason.
- **Coverage:** Promise tests in `test/glendix_test.gleam` cover every delegated
  operation plus rejected `Error` identity, recovery pass-through, flattening,
  first rejection, and callback count.

### Dynamic JavaScript reflection

- **Boundary:** `src/glendix/js/reflect_ffi.mjs`.
- **Inputs and outputs:** opaque object/value/constructor handles support
  property get/set/delete/has, receiver-bound method calls, and `new` with a
  typed Gleam list of opaque arguments. Mutating operations return the same
  object handle.
- **Errors:** missing values read as JavaScript `undefined`; invalid receivers,
  methods, constructors, or argument contracts throw native exceptions.
  `has` includes the prototype chain. `set` intentionally keeps normal
  JavaScript assignment semantics and does not promise `__proto__` safety.
- **Retention:** arbitrary runtime names and callable/constructor handles are
  inherently dynamic. Issue #19 minimized and named this unsafe interop surface
  instead of pretending an encoder or data-object package could replace it.
- **Coverage:** `test/glendix/js/reflect_test.gleam` covers missing/existing
  reads, same-handle mutation, deletion, own/inherited membership, method
  receiver/arguments, zero-argument calls, and construction.

### Timer handle compatibility

- **Boundary:** `src/glendix/js/timer_ffi.mjs`.
- **Inputs and outputs:** the two identity casts translate between Glendix's
  established opaque `TimerId` and Plinth's `TimerID`; all set/clear operations
  themselves delegate to `plinth/javascript/global`.
- **Errors:** callbacks and platform timer failures follow Plinth/platform
  behavior; the casts cannot fail at runtime because both types hold the same
  JavaScript handle.
- **Retention:** issue #17 adopted Plinth without breaking Glendix's public
  timer-handle type. The residual FFI is a zero-cost type compatibility bridge.
- **Coverage:** `test/glendix/js/timer_test.gleam` covers one-shot execution,
  timeout cancellation, repeating callbacks, interval cancellation, and handle
  presence.

### Lustre, React, and Mendix rendering

- **Boundary:** `src/glendix/lustre_ffi.mjs`.
- **Inputs and outputs:** Lustre VDOM nodes and attributes become React elements;
  events decode and dispatch typed messages; TEA/simple helpers run React hooks;
  `embed` carries a React element through Lustre; `host` renders fresh Mendix
  props inside a React keyed host.
- **Errors and fallback:** supported Lustre node kinds preserve keys,
  properties, styles, events, debounce/throttle, and unsafe HTML. Null values
  stay null and unknown node kinds render null. Decoder, view, update, React, or
  host errors propagate through their native runtime boundaries.
- **Retention:** this is the product-specific interoperability layer among
  Lustre's internal VDOM representation, React hooks/elements, Redraw, and the
  Mendix widget host. No ecosystem package provides that four-way contract.
  Issue #6 added the typed keyed host without replacing the bridge.
- **Coverage:** Lustre tests in `test/glendix_test.gleam` cover foreign
  constructor rendering, keyed remount/preservation, nested embedding, props,
  and lifecycle ordering.

## Removed or package-owned boundaries

These replacements explain where handwritten externals went; they are not rows
in the live mapping because no current `@external` declaration remains for
those operations.

| Former responsibility | Current owner | Tracking issue |
| --- | --- | --- |
| List/JavaScript array conversion | `gleam/javascript/array` | #11 |
| Promise resolve/map/await/all/race | `gleam/javascript/promise` | #12 |
| JSON serialization and typed parsing | `gleam_json` | #13 |
| Widget-definition filesystem and package JSON | `simplifile` and `gleam_json` | #14 |
| `gleam.toml` parsing | `tom` plus `simplifile` | #15 |
| Mendix widget XML parsing/serialization | `xmlm` plus pure Gleam | #16 |
| DOM focus/blur/rectangle/query and timer operations | `plinth` | #17 |
| Terminal size | `term_size` | #18 |
| Generic synchronous command execution | `shellout` | #20 |
| Browser file open/read and object-URL lifecycle | `plinth` and `gossamer` | #8 |

## Test-only FFI

Test externals create isolated runtime fixtures, inspect opaque JavaScript
values, stub browser/process state, and drive lifecycle scenarios that Gleam
cannot observe directly. They are compiled only with the test source tree and
are not part of the package's production API. The mapping below marks every one
as `Test only`; CI verifies that no production declaration receives that
classification.

## Exact declaration mapping

The first two columns are machine-checked. Each declaration identifier is the
Gleam source path plus private function name; each implementation identifier is
the resolved JavaScript path plus export name. Do not hand-edit an identifier
without changing the corresponding source declaration.

| Gleam declaration | JavaScript export | Classification | Replacement or retention reason |
| --- | --- | --- | --- |
| `src/glendix/binding.gleam#module_raw` | `src/glendix/binding_ffi.mjs#get_module` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#resolve_raw` | `src/glendix/binding_ffi.mjs#resolve` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#module_name_raw` | `src/glendix/binding_ffi.mjs#module_name` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#initialization_export_name_raw` | `src/glendix/binding_ffi.mjs#initialization_export_name` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#initialization_retry_policy_raw` | `src/glendix/binding_ffi.mjs#initialization_retry_policy` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#initialize_module_raw` | `src/glendix/binding_ffi.mjs#initialize_module` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#element_raw` | `src/glendix/binding_ffi.mjs#component_element` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#element_without_attributes_raw` | `src/glendix/binding_ffi.mjs#component_element_without_attributes` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#void_element_raw` | `src/glendix/binding_ffi.mjs#void_component_element` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#raw_binding_error_message` | `src/glendix/binding_ffi.mjs#binding_error_message` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/binding.gleam#promise_rejection_message_raw` | `src/glendix/binding_ffi.mjs#binding_error_message` | Retained | Generated npm/React host retained after #7. |
| `src/glendix/cmd.gleam#file_exists` | `src/glendix/cmd_ffi.mjs#file_exists` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#run_with_bridge` | `src/glendix/cmd_ffi.mjs#run_with_bridge` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#run_dev_with_bridge` | `src/glendix/cmd_ffi.mjs#run_dev_with_bridge` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#generate_bindings_raw` | `src/glendix/cmd_ffi.mjs#generate_bindings` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#render_binding_source_raw` | `src/glendix/cmd_ffi.mjs#render_binding_source` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#run_experimental_native_raw` | `src/glendix/cmd_ffi.mjs#run_experimental_native` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#run_experimental_native_with_bridge_raw` | `src/glendix/cmd_ffi.mjs#run_experimental_native_with_bridge` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#run_experimental_native_dev_with_bridge_raw` | `src/glendix/cmd_ffi.mjs#run_experimental_native_dev_with_bridge` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#raw_command_error_message` | `src/glendix/cmd_ffi.mjs#command_error_message` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/cmd.gleam#fail_process` | `src/glendix/cmd_ffi.mjs#fail_process` | Retained | Glendix bridge, watcher, native, Rollup, and WASM tooling retained after #20. |
| `src/glendix/command.gleam#is_windows` | `src/glendix/command_ffi.mjs#is_windows` | Package adapter | `shellout`-backed command path with platform and filtered-runner gaps from #20. |
| `src/glendix/command.gleam#windows_shell` | `src/glendix/command_ffi.mjs#windows_shell` | Package adapter | `shellout`-backed command path with platform and filtered-runner gaps from #20. |
| `src/glendix/command.gleam#capture_sigint_listeners` | `src/glendix/command_ffi.mjs#capture_sigint_listeners` | Package adapter | `shellout`-backed command path with platform and filtered-runner gaps from #20. |
| `src/glendix/command.gleam#restore_sigint_listeners` | `src/glendix/command_ffi.mjs#restore_sigint_listeners` | Package adapter | `shellout`-backed command path with platform and filtered-runner gaps from #20. |
| `src/glendix/command.gleam#run_filtered_raw` | `src/glendix/command_ffi.mjs#run_filtered` | Package adapter | `shellout`-backed command path with platform and filtered-runner gaps from #20. |
| `src/glendix/command.gleam#raw_error_message` | `src/glendix/command_ffi.mjs#error_message` | Package adapter | `shellout`-backed command path with platform and filtered-runner gaps from #20. |
| `src/glendix/editor_config.gleam#hide_property_raw` | `src/glendix/editor_config_ffi.mjs#hide_property_in` | Package adapter | Typed adapter for the Mendix editor-config npm helpers. |
| `src/glendix/editor_config.gleam#hide_properties_raw` | `src/glendix/editor_config_ffi.mjs#hide_properties_in` | Package adapter | Typed adapter for the Mendix editor-config npm helpers. |
| `src/glendix/editor_config.gleam#hide_nested_property_raw` | `src/glendix/editor_config_ffi.mjs#hide_nested_property_in` | Package adapter | Typed adapter for the Mendix editor-config npm helpers. |
| `src/glendix/editor_config.gleam#hide_nested_properties_raw` | `src/glendix/editor_config_ffi.mjs#hide_nested_properties_in` | Package adapter | Typed adapter for the Mendix editor-config npm helpers. |
| `src/glendix/editor_config.gleam#transform_groups_into_tabs_raw` | `src/glendix/editor_config_ffi.mjs#transform_groups_into_tabs` | Package adapter | Typed adapter for the Mendix editor-config npm helpers. |
| `src/glendix/editor_config.gleam#move_property_raw` | `src/glendix/editor_config_ffi.mjs#move_property` | Package adapter | Typed adapter for the Mendix editor-config npm helpers. |
| `src/glendix/internal/define/terminal_control.gleam#is_tty_ffi` | `src/glendix/internal/define/terminal_control_ffi.mjs#is_tty` | Retained | Raw terminal capability and input residue retained by #18. |
| `src/glendix/internal/define/terminal_control.gleam#set_terminal_raw_mode` | `src/glendix/internal/define/terminal_control_ffi.mjs#set_terminal_raw_mode` | Retained | Raw terminal capability and input residue retained by #18. |
| `src/glendix/internal/define/terminal_control.gleam#terminal_mode_error_message` | `src/glendix/internal/define/terminal_control_ffi.mjs#terminal_mode_error_message` | Retained | Raw terminal capability and input residue retained by #18. |
| `src/glendix/internal/define/terminal_control.gleam#poll_key_raw_ffi` | `src/glendix/internal/define/terminal_control_ffi.mjs#poll_key_raw` | Retained | Raw terminal capability and input residue retained by #18. |
| `src/glendix/internal/define/terminal_control.gleam#decode_key_ffi` | `src/glendix/internal/define/terminal_control_ffi.mjs#decode_key` | Retained | Raw terminal capability and input residue retained by #18. |
| `src/glendix/js/dom.gleam#to_plinth_element` | `src/glendix/js/dom_ffi.mjs#identity` | Package adapter | Plinth-backed DOM API with handle casts and uncovered operations from #17. |
| `src/glendix/js/dom.gleam#from_plinth_element` | `src/glendix/js/dom_ffi.mjs#identity` | Package adapter | Plinth-backed DOM API with handle casts and uncovered operations from #17. |
| `src/glendix/js/dom.gleam#from_plinth_dom_rect` | `src/glendix/js/dom_ffi.mjs#identity` | Package adapter | Plinth-backed DOM API with handle casts and uncovered operations from #17. |
| `src/glendix/js/dom.gleam#click_raw` | `src/glendix/js/dom_ffi.mjs#dom_click` | Package adapter | Plinth-backed DOM API with handle casts and uncovered operations from #17. |
| `src/glendix/js/dom.gleam#scroll_into_view_raw` | `src/glendix/js/dom_ffi.mjs#dom_scroll_into_view` | Package adapter | Plinth-backed DOM API with handle casts and uncovered operations from #17. |
| `src/glendix/js/environment.gleam#match_media_is_available_raw` | `src/glendix/js/environment_ffi.mjs#match_media_is_available` | Retained | `matchMedia` capability adapter retained by #9. |
| `src/glendix/js/environment.gleam#prefers_dark_raw` | `src/glendix/js/environment_ffi.mjs#prefers_dark` | Retained | `matchMedia` capability adapter retained by #9. |
| `src/glendix/js/environment.gleam#prefers_light_raw` | `src/glendix/js/environment_ffi.mjs#prefers_light` | Retained | `matchMedia` capability adapter retained by #9. |
| `src/glendix/js/file.gleam#modern_picker_is_available_raw` | `src/glendix/js/file_ffi.mjs#modern_picker_is_available` | Package adapter | Plinth picker capability predicate retained by #8. |
| `src/glendix/js/object.gleam#string_raw` | `src/glendix/js/object_ffi.mjs#identity` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/object.gleam#int_raw` | `src/glendix/js/object_ffi.mjs#identity` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/object.gleam#float_raw` | `src/glendix/js/object_ffi.mjs#identity` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/object.gleam#bool_raw` | `src/glendix/js/object_ffi.mjs#identity` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/object.gleam#object_value_raw` | `src/glendix/js/object_ffi.mjs#identity` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/object.gleam#create_object_raw` | `src/glendix/js/object_ffi.mjs#create_object` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/object.gleam#empty_object_raw` | `src/glendix/js/object_ffi.mjs#empty_object` | Retained | Prototype-safe live object construction retained by #19. |
| `src/glendix/js/promise.gleam#reject_raw` | `src/glendix/js/promise_ffi.mjs#promise_reject` | Package adapter | `gleam_javascript` Promise gaps retained by #12. |
| `src/glendix/js/promise.gleam#catch_raw` | `src/glendix/js/promise_ffi.mjs#promise_catch` | Package adapter | `gleam_javascript` Promise gaps retained by #12. |
| `src/glendix/js/reflect.gleam#get_property_raw` | `src/glendix/js/reflect_ffi.mjs#get_property` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/reflect.gleam#set_property_raw` | `src/glendix/js/reflect_ffi.mjs#set_property` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/reflect.gleam#delete_property_raw` | `src/glendix/js/reflect_ffi.mjs#delete_property` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/reflect.gleam#has_property_raw` | `src/glendix/js/reflect_ffi.mjs#has_property` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/reflect.gleam#call_method_raw` | `src/glendix/js/reflect_ffi.mjs#call_method` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/reflect.gleam#call_method_without_arguments_raw` | `src/glendix/js/reflect_ffi.mjs#call_method_0` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/reflect.gleam#new_instance_raw` | `src/glendix/js/reflect_ffi.mjs#new_instance` | Retained | Dynamic reflection residue isolated by #19. |
| `src/glendix/js/timer.gleam#from_plinth_timer` | `src/glendix/js/timer_ffi.mjs#identity` | Package adapter | Plinth timer-handle identity adapter retained by #17. |
| `src/glendix/js/timer.gleam#to_plinth_timer` | `src/glendix/js/timer_ffi.mjs#identity` | Package adapter | Plinth timer-handle identity adapter retained by #17. |
| `src/glendix/lustre.gleam#render_raw` | `src/glendix/lustre_ffi.mjs#render` | Retained | Lustre/React/Mendix render and hook bridge retained; keyed host added by #6. |
| `src/glendix/lustre.gleam#use_tea_raw` | `src/glendix/lustre_ffi.mjs#use_tea` | Retained | Lustre/React/Mendix render and hook bridge retained; keyed host added by #6. |
| `src/glendix/lustre.gleam#use_simple_raw` | `src/glendix/lustre_ffi.mjs#use_simple` | Retained | Lustre/React/Mendix render and hook bridge retained; keyed host added by #6. |
| `src/glendix/lustre.gleam#embed_raw` | `src/glendix/lustre_ffi.mjs#embed` | Retained | Lustre/React/Mendix render and hook bridge retained; keyed host added by #6. |
| `src/glendix/lustre.gleam#host_raw` | `src/glendix/lustre_ffi.mjs#host` | Retained | Lustre/React/Mendix render and hook bridge retained; keyed host added by #6. |
| `test/file_boundary_test.gleam#in_temporary_directory` | `test/file_boundary_test_ffi.mjs#in_temporary_directory` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/file_boundary_test.gleam#write_invalid_utf8` | `test/file_boundary_test_ffi.mjs#write_invalid_utf8` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/command_test.gleam#sigint_listener_count` | `test/glendix/command_test_ffi.mjs#sigint_listener_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/internal/define/terminal_control_test.gleam#set_raw_mode_without_support` | `test/glendix/internal/define/terminal_control_test_ffi.mjs#set_raw_mode_without_support` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/internal/define/terminal_control_test.gleam#set_raw_mode_with_exception` | `test/glendix/internal/define/terminal_control_test_ffi.mjs#set_raw_mode_with_exception` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/internal/define/terminal_control_test.gleam#raw_mode_lifecycle` | `test/glendix/internal/define/terminal_control_test_ffi.mjs#raw_mode_lifecycle` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/internal/define/terminal_control_test.gleam#poll_key_sequence` | `test/glendix/internal/define/terminal_control_test_ffi.mjs#poll_key_sequence` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#new_element_fixture` | `test/glendix/js/dom_test_ffi.mjs#new_element_fixture` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#operation_count` | `test/glendix/js/dom_test_ffi.mjs#operation_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#scroll_argument_count` | `test/glendix/js/dom_test_ffi.mjs#scroll_argument_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#is_fixture_child` | `test/glendix/js/dom_test_ffi.mjs#is_fixture_child` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#rectangle_x` | `test/glendix/js/dom_test_ffi.mjs#rectangle_x` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#rectangle_y` | `test/glendix/js/dom_test_ffi.mjs#rectangle_y` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#rectangle_width` | `test/glendix/js/dom_test_ffi.mjs#rectangle_width` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/dom_test.gleam#rectangle_height` | `test/glendix/js/dom_test_ffi.mjs#rectangle_height` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/file_test.gleam#observe_object_url_lifetime` | `test/glendix/js/file_test_ffi.mjs#observe_object_url_lifetime` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/file_test.gleam#install_picker_scenario` | `test/glendix/js/file_test_ffi.mjs#install_picker_scenario` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/file_test.gleam#picker_invocation_count` | `test/glendix/js/file_test_ffi.mjs#picker_invocation_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/file_test.gleam#picker_read_count` | `test/glendix/js/file_test_ffi.mjs#picker_read_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/object_test.gleam#object_json` | `test/glendix/js/object_test_ffi.mjs#object_json` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/object_test.gleam#proto_key_is_safe_data` | `test/glendix/js/object_test_ffi.mjs#proto_key_is_safe_data` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/object_test.gleam#has_default_prototype` | `test/glendix/js/object_test_ffi.mjs#has_default_prototype` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/reflect_test.gleam#value_to_string` | `test/glendix/js/reflect_test_ffi.mjs#value_to_string` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/reflect_test.gleam#value_is_undefined` | `test/glendix/js/reflect_test_ffi.mjs#value_is_undefined` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/reflect_test.gleam#method_object` | `test/glendix/js/reflect_test_ffi.mjs#method_object` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/reflect_test.gleam#point_constructor` | `test/glendix/js/reflect_test_ffi.mjs#point_constructor` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/reflect_test.gleam#same_object` | `test/glendix/js/reflect_test_ffi.mjs#same_object` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/reflect_test.gleam#point_summary` | `test/glendix/js/reflect_test_ffi.mjs#point_summary` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/timer_test.gleam#new_counter` | `test/glendix/js/timer_test_ffi.mjs#new_counter` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/timer_test.gleam#increment_counter` | `test/glendix/js/timer_test_ffi.mjs#increment_counter` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/timer_test.gleam#counter_value` | `test/glendix/js/timer_test_ffi.mjs#counter_value` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix/js/timer_test.gleam#timer_handle_is_defined` | `test/glendix/js/timer_test_ffi.mjs#timer_handle_is_defined` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#clone_lustre_tree` | `test/glendix_test_ffi.mjs#clone_lustre_tree` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#rendered_tree_summary` | `test/glendix_test_ffi.mjs#rendered_tree_summary` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#test_component` | `test/glendix_test_ffi.mjs#test_component` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#test_initialization_module` | `test/glendix_test_ffi.mjs#test_initialization_module` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#initialization_attempt_count` | `test/glendix_test_ffi.mjs#initialization_attempt_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#resolve_initialization` | `test/glendix_test_ffi.mjs#resolve_initialization` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#initialization_promises_are_same` | `test/glendix_test_ffi.mjs#initialization_promises_are_same` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#non_react_module_value` | `test/glendix_test_ffi.mjs#non_react_module_value` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#generated_rollup_config_source` | `test/glendix_test_ffi.mjs#generated_rollup_config_source` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#wasm_asset_es_transform_summary` | `test/glendix_test_ffi.mjs#wasm_asset_es_transform_summary` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#wasm_asset_amd_transform_summary` | `test/glendix_test_ffi.mjs#wasm_asset_amd_transform_summary` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#wasm_asset_noop_contract` | `test/glendix_test_ffi.mjs#wasm_asset_noop_contract` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#wasm_asset_missing_error` | `test/glendix_test_ffi.mjs#wasm_asset_missing_error` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#process_exit_code` | `test/glendix_test_ffi.mjs#process_exit_code` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#reset_process_exit_code` | `test/glendix_test_ffi.mjs#reset_process_exit_code` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#stub_prefers_dark` | `test/glendix_test_ffi.mjs#stub_prefers_dark` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#stub_prefers_light` | `test/glendix_test_ffi.mjs#stub_prefers_light` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#stub_prefers_none` | `test/glendix_test_ffi.mjs#stub_prefers_none` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#clear_match_media` | `test/glendix_test_ffi.mjs#clear_match_media` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#element_prop_json` | `test/glendix_test_ffi.mjs#element_prop_json` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#element_prop_is` | `test/glendix_test_ffi.mjs#element_prop_is` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#new_promise_callback_counter` | `test/glendix_test_ffi.mjs#new_promise_callback_counter` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#increment_promise_callback_counter` | `test/glendix_test_ffi.mjs#increment_promise_callback_counter` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#promise_callback_count` | `test/glendix_test_ffi.mjs#promise_callback_count` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#promise_rejection_is_error` | `test/glendix_test_ffi.mjs#promise_rejection_is_error` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#promise_rejection_message` | `test/glendix_test_ffi.mjs#promise_rejection_message` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#keyed_host_lifecycle_summary` | `test/glendix_test_ffi.mjs#keyed_host_lifecycle_summary` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#keyed_host_nested_summary` | `test/glendix_test_ffi.mjs#keyed_host_nested_summary` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#record_keyed_host_props` | `test/glendix_test_ffi.mjs#record_keyed_host_props` | Test only | Runtime fixture for contract tests; not shipped as a production API. |
| `test/glendix_test.gleam#track_keyed_host_lifecycle` | `test/glendix_test_ffi.mjs#track_keyed_host_lifecycle` | Test only | Runtime fixture for contract tests; not shipped as a production API. |

The live inventory contains **132 declarations**: **70 production** and **62 test-only**.
