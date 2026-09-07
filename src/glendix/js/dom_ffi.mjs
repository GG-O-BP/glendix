// Glendix keeps its established public handles while Plinth owns the platform
// operations. JavaScript uses the same object for both typed views.
export function identity(value) {
  return value;
}

export function dom_click(element) {
  element.click();
}
export function dom_scroll_into_view(element) {
  element.scrollIntoView();
}
