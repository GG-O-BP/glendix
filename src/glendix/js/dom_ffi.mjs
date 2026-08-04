import { Some, None } from "../../../gleam_stdlib/gleam/option.mjs";
export function dom_focus(element) {
  element.focus();
}
export function dom_blur(element) {
  element.blur();
}
export function dom_click(element) {
  element.click();
}
export function dom_scroll_into_view(element) {
  element.scrollIntoView();
}
export function dom_get_bounding_client_rect(element) {
  return element.getBoundingClientRect();
}
export function dom_query_selector(element, selector) {
  const result = element.querySelector(selector);
  return result !== null ? new Some(result) : new None();
}
