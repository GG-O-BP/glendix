// JSON FFI
import { Ok, Error as GleamError } from "../../gleam.mjs";
export function json_stringify(value) {
  return JSON.stringify(value);
}
export function json_parse(json) {
  try {
    return new Ok(JSON.parse(json));
  } catch (e) {
    const reason = e instanceof globalThis.Error ? e.message : String(e);
    return new GleamError(reason);
  }
}
export function json_error_message(error) {
  return error;
}
