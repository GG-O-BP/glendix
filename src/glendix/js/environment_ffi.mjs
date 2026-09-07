// Guards `window.matchMedia` so callers never touch it directly. The lookups
// read `globalThis` so browser and non-browser runtimes share one path: in a
// browser `globalThis` is `window`, and server/test runtimes without a DOM
// simply lack `matchMedia`. Tests install a stub on `globalThis.matchMedia` to
// drive each branch without a real browser.
function match_media_function() {
  const candidate = globalThis.matchMedia;
  // why: server-side rendering and older engines can omit matchMedia entirely,
  // so an unavailable environment is a first-class, non-error state.
  return typeof candidate === "function" ? candidate : null;
}

export function match_media_is_available() {
  return match_media_function() !== null;
}

function query_matches(query) {
  const matchMedia = match_media_function();
  if (matchMedia === null) return false;
  // why: call with globalThis as the receiver because matchMedia is a method of
  // the global (window) object and expects that binding.
  const result = matchMedia.call(globalThis, query);
  // why: a defensive engine could return null or omit `matches`; treat a
  // missing result as "does not match" instead of throwing.
  return Boolean(result && result.matches);
}

export function prefers_dark() {
  return query_matches("(prefers-color-scheme: dark)");
}

export function prefers_light() {
  return query_matches("(prefers-color-scheme: light)");
}
