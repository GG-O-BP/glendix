// Glendix retains its public timer handle while Plinth owns all timer
// operations. JavaScript uses the same platform handle for both typed views.
export function identity(value) {
  return value;
}
