// HTML 속성 → React props 변환 FFI

// 범용 속성 생성 (plain JS object)
export function make_attribute(key, content) {
  return { key, content };
}

// List(#(String, String)) → React style 객체 (camelCase 변환)
export function make_style_attribute(styles) {
  const style = {};
  for (const pair of styles.toArray()) {
    style[camelize(pair[0])] = pair[1];
  }
  return { key: "style", content: style };
}

function camelize(str) {
  return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

// dangerouslySetInnerHTML 속성 생성
export function make_inner_html(html) {
  return { key: "dangerouslySetInnerHTML", content: { __html: html } };
}

// List(Attribute) → React props 객체
// className 자동 병합, none_ 무시
export function to_props(attributes) {
  const props = {};
  const classNames = [];
  for (const attr of attributes.toArray()) {
    if (attr.key === "none_") continue;
    if (attr.key === "className") {
      classNames.push(attr.content);
    } else {
      props[attr.key] = attr.content;
    }
  }
  if (classNames.length > 0) props.className = classNames.join(" ");
  return props;
}
