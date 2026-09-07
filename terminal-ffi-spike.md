# Terminal FFI reduction spike (issue #18)

## Goal

The widget definition TUI owned all terminal-capability and raw-input FFI in a
single `define_ffi.mjs` adapter. This spike evaluates ecosystem packages that
could replace that custom FFI and minimizes the residue to only what has no
reliable cross-runtime equivalent.

## Evaluation

| FFI function | Ecosystem replacement | Decision |
| --- | --- | --- |
| `terminal_size` | `term_size` (`term_size.get`) | Replaced |
| `is_tty` | none | Retained custom FFI |
| `exit_process` | `plinth/node/process.exit` | Replaced |
| `set_terminal_raw_mode` | none | Retained custom FFI |
| `terminal_mode_error_message` | none | Retained custom FFI |
| `poll_key_raw` (+ stdin lifecycle and key decoding) | none | Retained custom FFI |

### Replaced functions

#### `terminal_size` -> `term_size`

`term_size` (v1.x) exposes `term_size.get()`, which reads the terminal size on
every supported runtime and returns a `Result(#(rows, columns), Nil)`, so the
boundary can keep the previous 80x24 fallback without custom FFI. The `etch`
terminal package was also considered but only emits ANSI control strings; it
never queries the runtime size, so it cannot replace this function.

#### `exit_process` -> `plinth/node/process.exit`

`plinth` is already a Glendix dependency and exposes Node's typed
`process.exit(code:)` operation, so the custom zero-argument FFI export is
unnecessary. The TUI now calls `process.exit(code: 0)` directly and preserves
the previous successful exit status.

The Gleam wrapper converts the package's `#(rows, columns)` result into the
previous `#(columns, rows)` contract and preserves the `columns || 80` /
`rows || 24` fallback, including the non-positive case:

```gleam
import term_size

pub fn size() -> #(Int, Int) {
  size_from(term_size.get())
}
```

### Retained custom FFI

No evaluated package safely provides the remaining behavior:

- `is_tty` is a runtime capability probe not exposed by the evaluated
  packages.
- `set_terminal_raw_mode` must toggle raw mode, resume stdin, and report an
  exact failure reason (including "stdin does not support raw mode") through a
  `Result`.
- `poll_key_raw` provides non-blocking one-shot key polling with a buffered
  stdin lifecycle and UTF-8 aware decoding of arrow/navigation keys, Enter,
  Backspace, Ctrl+C, and Tab. Adopting a package that cannot preserve this
  non-blocking one-shot behavior is an explicit non-goal.

These stay in
`src/glendix/internal/define/terminal_control_ffi.mjs`, and each retained
external is documented as intentionally custom in `terminal_control.gleam`.

## Outcome

- Terminal capability and raw input now live in a dedicated
  internal `glendix/internal/define/terminal_control` boundary module instead
  of the general `define` module; `define_ffi.mjs` is removed without adding a
  new public package API.
- Terminal size delegates to `term_size`; the retained raw-input and lifecycle
  FFI is documented as intentional residue, and process exit delegates to
  `plinth`.
- The size fallback, the raw-mode error path, and key decoding are unchanged.
- The TUI event loop and key model are unchanged, matching the non-goals.
- `glendix -> mendraw` keeps its currently declared dependency source form.

## Verification

- `./scripts/verify.sh inner glendix`
- `./scripts/verify.sh shared glendix` when public signatures change
- `./scripts/verify.sh final` before a release or family-wide claim
