// FFI adapter for the Mendix widget property TUI editor.
import { Ok, Error as GleamError } from "../gleam.mjs";
export function is_tty() {
  return !!process.stdin.isTTY;
}
export function exit_process() {
  process.exit(0);
}
export function terminal_size() {
  const cols = process.stdout.columns || 80;
  const rows = process.stdout.rows || 24;
  return [cols, rows];
}
export function set_terminal_raw_mode(enabled) {
  try {
    if (typeof process.stdin.setRawMode !== "function") {
      return new GleamError("stdin does not support raw mode");
    }
    process.stdin.setRawMode(enabled);
    if (enabled) {
      process.stdin.resume();
    }
    return new Ok(undefined);
  } catch (error) {
    const reason = error instanceof globalThis.Error
      ? error.message
      : String(error);
    return new GleamError(reason);
  }
}
export function terminal_mode_error_message(error) {
  return error;
}
let stdinActive = false;
let keyQueue = [];
let keyResolver = null;
let keyTimer = null;
function ensureStdin() {
  if (stdinActive) return;
  stdinActive = true;
  process.stdin.on("data", onStdinData);
  process.stdin.resume();
}
function onStdinData(data) {
  const buf = Buffer.isBuffer(data) ? data : Buffer.from(String(data), "utf8");
  const key = parseKeyBuf(buf);
  if (keyResolver) {
    if (keyTimer) { clearTimeout(keyTimer); keyTimer = null; }
    const r = keyResolver;
    keyResolver = null;
    r(key);
  } else {
    keyQueue.push(key);
  }
}
function parseKeyBuf(buf) {
  if (buf.length === 0) return [0, ""];
  const b = buf[0];
  if (b === 0x1b) {
    if (buf.length >= 3 && buf[1] === 0x5b) {
      if (buf[2] === 65) return [1, ""];  // Up
      if (buf[2] === 66) return [2, ""];  // Down
      if (buf[2] === 67) return [3, ""];  // Right
      if (buf[2] === 68) return [4, ""];  // Left
      if (buf[2] === 72) return [10, ""]; // Home
      if (buf[2] === 70) return [11, ""]; // End
      if (buf.length >= 4 && buf[3] === 0x7e) {
        if (buf[2] === 53) return [12, ""]; // PageUp
        if (buf[2] === 54) return [13, ""]; // PageDown
      }
    }
    return [6, ""];  // Escape
  }
  if (b === 0x0d || b === 0x0a) return [5, ""];  // Enter
  if (b === 0x7f || b === 0x08) return [7, ""];   // Backspace
  if (b === 0x03) return [8, ""];                  // Ctrl+C
  if (b === 0x09) return [14, ""];                 // Tab has a distinct key code.
  // UTF-8
  let totalBytes = 1;
  if (b >= 0xc0 && b < 0xe0) totalBytes = 2;
  else if (b >= 0xe0 && b < 0xf0) totalBytes = 3;
  else if (b >= 0xf0) totalBytes = 4;
  return [9, buf.slice(0, totalBytes).toString("utf-8")];
}
export function poll_key_raw(timeout_ms) {
  ensureStdin();
  if (keyQueue.length > 0) return Promise.resolve(keyQueue.shift());
  return new Promise(resolve => {
    if (timeout_ms > 0) {
      keyTimer = setTimeout(() => {
        keyResolver = null;
        keyTimer = null;
        resolve([0, ""]);
      }, timeout_ms);
    }
    keyResolver = resolve;
  });
}
