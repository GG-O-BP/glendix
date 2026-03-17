// Mendix Widget Property TUI 에디터 — FFI 어댑터
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { Some, None } from "../../gleam_stdlib/gleam/option.mjs";
import { toList } from "../gleam.mjs";
import {
  PropertyGroup, PropItem, SysPropItem, SystemProperty,
  Property, EnumValue, ReturnType,
  TypeString, TypeBoolean, TypeInteger, TypeDecimal, TypeEnumeration,
  TypeIcon, TypeImage, TypeWidgets, TypeFile,
  TypeExpression, TypeTextTemplate, TypeAction, TypeAttribute,
  TypeAssociation, TypeObject, TypeDatasource, TypeSelection,
  WidgetMeta,
} from "./define/types.mjs";

// ── 위젯 XML 파일 탐색 ──

export function find_widget_xml() {
  try {
    const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
    const name = pkg.widgetName;
    if (!name) return new None();
    const p = `src/${name}.xml`;
    return existsSync(p) ? new Some(p) : new None();
  } catch {
    return new None();
  }
}

// ── 파일 I/O ──

export function read_file(path) {
  try {
    return new Some(readFileSync(path, "utf-8"));
  } catch {
    return new None();
  }
}

export function write_file(path, content) {
  try {
    writeFileSync(path, content, "utf-8");
    return true;
  } catch {
    return false;
  }
}

// ── TTY & 프로세스 ──

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

// ── XML 이스케이프 ──

function escXml(s) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function unesc(s) {
  return s
    .replace(/&quot;/g, '"')
    .replace(/&gt;/g, ">")
    .replace(/&lt;/g, "<")
    .replace(/&amp;/g, "&");
}

// ── XML 파싱 헬퍼 ──

function attr(tag, name) {
  const m = tag.match(new RegExp(`${name}="([^"]*)"`));
  return m ? m[1] : null;
}

// 태그 깊이를 추적하여 매칭하는 닫힘 태그를 찾는다
function findClose(xml, tag, from) {
  const close = `</${tag}>`;
  let depth = 1, pos = from;
  while (depth > 0 && pos < xml.length) {
    const nc = xml.indexOf(close, pos);
    if (nc === -1) return xml.length;
    // 사이에 같은 태그의 비-자기닫힘 여는 태그 개수
    const seg = xml.substring(pos, nc);
    const re = new RegExp(`<${tag}[\\s>]`, "g");
    let m;
    while ((m = re.exec(seg)) !== null) {
      const gt = seg.indexOf(">", m.index);
      if (gt !== -1 && seg[gt - 1] !== "/") depth++;
    }
    depth--;
    pos = nc + close.length;
  }
  return pos;
}

// 직접 자식 요소 추출 (깊이 추적)
function findElements(xml, tag) {
  const results = [];
  const re = new RegExp(`<${tag}(\\s[^>]*)?>`, "g");
  let m;
  while ((m = re.exec(xml)) !== null) {
    const attrs = (m[1] || "").trim();
    if (m[0].endsWith("/>")) {
      results.push({ attrs: attrs.replace(/\/$/, "").trim(), content: "", pos: m.index });
      continue;
    }
    const openEnd = m.index + m[0].length;
    const closeEnd = findClose(xml, tag, openEnd);
    const closeTag = `</${tag}>`;
    const content = xml.substring(openEnd, closeEnd - closeTag.length);
    results.push({ attrs, content, pos: m.index });
    re.lastIndex = closeEnd;
  }
  return results;
}

// ── PropertyType 매핑 ──

const TYPE_MAP = {
  string: TypeString, boolean: TypeBoolean, integer: TypeInteger,
  decimal: TypeDecimal, enumeration: TypeEnumeration,
  icon: TypeIcon, image: TypeImage, widgets: TypeWidgets, file: TypeFile,
  expression: TypeExpression, textTemplate: TypeTextTemplate,
  action: TypeAction, attribute: TypeAttribute, association: TypeAssociation,
  object: TypeObject, datasource: TypeDatasource, selection: TypeSelection,
};

function toType(s) {
  const T = TYPE_MAP[s];
  return T ? new T() : new TypeString();
}

// ── Property 파싱 ──

function parseProp(el) {
  const a = el.attrs;
  const c = el.content;
  const key = attr(a, "key") || "";
  const type_ = toType(attr(a, "type") || "string");

  const capM = c.match(/<caption>([^<]*)<\/caption>/);
  const caption = capM ? unesc(capM[1]) : key;
  const descM = c.match(/<description>([^<]*)<\/description>/);
  const description = descM ? unesc(descM[1]) : "";

  const opt = (n) => { const v = attr(a, n); return v !== null ? new Some(v) : new None(); };
  const optBool = (n) => { const v = attr(a, n); return v !== null ? new Some(v === "true") : new None(); };

  // returnType
  const rtM = c.match(/<returnType\s+type="([^"]*)"(?:\s+assignableTo="([^"]*)")?/);
  const return_type = rtM
    ? new Some(new ReturnType(rtM[1], rtM[2] ? new Some(rtM[2]) : new None()))
    : new None();

  // enumerationValues
  const enums = [];
  const evRe = /<enumerationValue\s+key="([^"]*)"[^>]*>([^<]*)<\/enumerationValue>/g;
  let ev;
  while ((ev = evRe.exec(c)) !== null) enums.push(new EnumValue(ev[1], unesc(ev[2])));

  // attributeTypes
  const attrTypes = [];
  const atRe = /<attributeType\s+name="([^"]*)"/g;
  let at;
  while ((at = atRe.exec(c)) !== null) attrTypes.push(at[1]);

  // associationTypes
  const assocTypes = [];
  const asRe = /<associationType\s+name="([^"]*)"/g;
  let as2;
  while ((as2 = asRe.exec(c)) !== null) assocTypes.push(as2[1]);

  // selectionTypes
  const selTypes = [];
  const stRe = /<selectionType\s+name="([^"]*)"/g;
  let st;
  while ((st = stRe.exec(c)) !== null) selTypes.push(st[1]);

  // 중첩 properties (object 타입)
  const subGroups = [];
  const subM = c.match(/<properties>([\s\S]*)<\/properties>/);
  if (subM) {
    for (const g of parseGroups(subM[1])) subGroups.push(g);
  }

  return new Property(
    key, type_, caption, description,
    optBool("required"), opt("defaultValue"),
    optBool("multiline"), optBool("isList"),
    opt("dataSource"), optBool("allowUpload"),
    opt("onChange"), optBool("setLabel"),
    return_type,
    toList(enums), toList(attrTypes), toList(assocTypes), toList(selTypes),
    opt("defaultType"),
    opt("selectableObjects"),
    toList(subGroups),
  );
}

// ── PropertyGroup 파싱 ──

function parseGroups(propertiesXml) {
  const groupEls = findElements(propertiesXml, "propertyGroup");
  return groupEls.map(gel => {
    const caption = unesc(attr(gel.attrs, "caption") || "");
    const items = [];

    // property와 systemProperty를 위치 순서대로 수집
    const propEls = findElements(gel.content, "property");
    const sysEls = findElements(gel.content, "systemProperty");

    const all = [
      ...propEls.map(e => ({ ...e, kind: "prop" })),
      ...sysEls.map(e => ({ ...e, kind: "sys" })),
    ].sort((a, b) => a.pos - b.pos);

    for (const el of all) {
      if (el.kind === "sys") {
        const k = attr(el.attrs, "key") || "";
        items.push(new SysPropItem(new SystemProperty(k)));
      } else {
        items.push(new PropItem(parseProp(el)));
      }
    }
    return new PropertyGroup(caption, toList(items));
  });
}

// ── parse_widget_xml ──

export function parse_widget_xml(xmlString) {
  // 위젯 태그 속성 개별 파싱
  const widgetTagM = xmlString.match(/<widget\s+([^>]*?)>/s);
  const widgetAttrs = widgetTagM ? widgetTagM[1] : "";
  const id = attr(widgetAttrs, "id") || "";
  const pluginWidget = attr(widgetAttrs, "pluginWidget") === "true";
  const offlineCapable = attr(widgetAttrs, "offlineCapable") === "true";
  const supportedPlatform = attr(widgetAttrs, "supportedPlatform") || "Web";
  const needsEntityContext = attr(widgetAttrs, "needsEntityContext") === "true";

  const nameM = xmlString.match(/<name>([^<]*)<\/name>/);
  const name = nameM ? nameM[1] : "Unknown";

  // widget 직접 자식의 description — <name> 다음에 오는 첫 번째 <description>
  const afterName = xmlString.indexOf("</name>");
  const descStart = afterName > 0 ? xmlString.indexOf("<description>", afterName) : -1;
  const descEnd = descStart > 0 ? xmlString.indexOf("</description>", descStart) : -1;
  const propsStart = xmlString.indexOf("<properties>");
  const desc = (descStart > 0 && descEnd > 0 && (propsStart < 0 || descStart < propsStart))
    ? xmlString.substring(descStart + 13, descEnd).trim()
    : "";

  const iconM = xmlString.match(/<icon>([\s\S]*?)<\/icon>/);
  const icon = iconM ? iconM[1] : "";

  const studioCatM = xmlString.match(/<studioCategory>([^<]*)<\/studioCategory>/);
  const studioProCatM = xmlString.match(/<studioProCategory>([^<]*)<\/studioProCategory>/);
  const studioProCategory = studioProCatM
    ? new Some(studioProCatM[1])
    : (studioCatM ? new Some(studioCatM[1]) : new None());

  const helpUrlM = xmlString.match(/<helpUrl>([^<]*)<\/helpUrl>/);
  const helpUrl = helpUrlM ? new Some(helpUrlM[1]) : new None();

  const promptM = xmlString.match(/<prompt>([\s\S]*?)<\/prompt>/);
  const widgetPrompt = promptM ? new Some(promptM[1].trim()) : new None();

  const meta = new WidgetMeta(
    id, pluginWidget, offlineCapable, supportedPlatform, needsEntityContext,
    name, desc, studioProCategory, helpUrl, icon, widgetPrompt,
  );

  // properties 파싱
  const propsM = xmlString.match(/<properties>([\s\S]*)<\/properties>/);
  const groups = propsM ? parseGroups(propsM[1]) : [];

  return [meta, toList(groups)];
}

// ── XML 직렬화 ──

function serializeProperty(prop, indent) {
  const i = indent;
  const i2 = indent + "    ";
  const attrs = [];
  attrs.push(`key="${escXml(prop.key)}"`);
  attrs.push(`type="${typeToStr(prop.type_)}"`);

  // 속성 태그 속성
  if (prop.required instanceof Some) attrs.push(`required="${prop.required[0]}"`);
  if (prop.default_value instanceof Some) attrs.push(`defaultValue="${escXml(prop.default_value[0])}"`);
  if (prop.multiline instanceof Some) attrs.push(`multiline="${prop.multiline[0]}"`);
  if (prop.is_list instanceof Some) attrs.push(`isList="${prop.is_list[0]}"`);
  if (prop.data_source instanceof Some) attrs.push(`dataSource="${escXml(prop.data_source[0])}"`);
  if (prop.allow_upload instanceof Some) attrs.push(`allowUpload="${prop.allow_upload[0]}"`);
  if (prop.on_change instanceof Some) attrs.push(`onChange="${escXml(prop.on_change[0])}"`);
  if (prop.set_label instanceof Some) attrs.push(`setLabel="${prop.set_label[0]}"`);
  if (prop.default_type instanceof Some) attrs.push(`defaultType="${escXml(prop.default_type[0])}"`);
  if (prop.selectable_objects instanceof Some) attrs.push(`selectableObjects="${escXml(prop.selectable_objects[0])}"`);

  const children = [];
  children.push(`${i2}<caption>${escXml(prop.caption)}</caption>`);
  children.push(`${i2}<description>${escXml(prop.description)}</description>`);

  // returnType
  if (prop.return_type instanceof Some) {
    const rt = prop.return_type[0];
    let rtTag = `${i2}<returnType type="${escXml(rt.type_name)}"`;
    if (rt.assignable_to instanceof Some) rtTag += ` assignableTo="${escXml(rt.assignable_to[0])}"`;
    rtTag += " />";
    children.push(rtTag);
  }

  // enumerationValues
  const evArr = prop.enumeration_values.toArray();
  if (evArr.length > 0) {
    children.push(`${i2}<enumerationValues>`);
    for (const ev of evArr) {
      children.push(`${i2}    <enumerationValue key="${escXml(ev.key)}">${escXml(ev.caption)}</enumerationValue>`);
    }
    children.push(`${i2}</enumerationValues>`);
  }

  // attributeTypes
  const atArr = prop.attribute_types.toArray();
  if (atArr.length > 0) {
    children.push(`${i2}<attributeTypes>`);
    for (const t of atArr) children.push(`${i2}    <attributeType name="${escXml(t)}" />`);
    children.push(`${i2}</attributeTypes>`);
  }

  // associationTypes
  const asArr = prop.association_types.toArray();
  if (asArr.length > 0) {
    children.push(`${i2}<associationTypes>`);
    for (const t of asArr) children.push(`${i2}    <associationType name="${escXml(t)}" />`);
    children.push(`${i2}</associationTypes>`);
  }

  // selectionTypes
  const stArr = prop.selection_types.toArray();
  if (stArr.length > 0) {
    children.push(`${i2}<selectionTypes>`);
    for (const t of stArr) children.push(`${i2}    <selectionType name="${escXml(t)}" />`);
    children.push(`${i2}</selectionTypes>`);
  }

  // 중첩 properties (object)
  const subArr = prop.sub_properties.toArray();
  if (subArr.length > 0) {
    children.push(`${i2}<properties>`);
    for (const g of subArr) children.push(serializeGroup(g, i2 + "    "));
    children.push(`${i2}</properties>`);
  }

  return `${i}<property ${attrs.join(" ")}>\n${children.join("\n")}\n${i}</property>`;
}

function typeToStr(t) {
  for (const [k, C] of Object.entries(TYPE_MAP)) {
    if (t instanceof C) return k;
  }
  return "string";
}

function serializeGroup(group, indent) {
  const i = indent;
  const i2 = indent + "    ";
  const lines = [`${i}<propertyGroup caption="${escXml(group.caption)}">`];

  for (const item of group.items.toArray()) {
    if (item instanceof SysPropItem) {
      lines.push(`${i2}<systemProperty key="${escXml(item[0].key)}" />`);
    } else if (item instanceof PropItem) {
      lines.push(serializeProperty(item[0], i2));
    }
  }

  lines.push(`${i}</propertyGroup>`);
  return lines.join("\n");
}

export function serialize_widget_xml(meta, groups) {
  const lines = [];
  lines.push('<?xml version="1.0" encoding="utf-8" ?>');

  // <widget> 태그 개별 필드에서 재구성
  const widgetAttrs = [
    `id="${escXml(meta.id)}"`,
    `pluginWidget="${meta.plugin_widget}"`,
    `needsEntityContext="${meta.needs_entity_context}"`,
    `offlineCapable="${meta.offline_capable}"`,
    `supportedPlatform="${escXml(meta.supported_platform)}"`,
    `xmlns="http://www.mendix.com/widget/1.0/"`,
    `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"`,
    `xsi:schemaLocation="http://www.mendix.com/widget/1.0/ ../node_modules/mendix/custom_widget.xsd"`,
  ];
  lines.push(`<widget ${widgetAttrs.join(" ")}>`);

  lines.push(`    <name>${escXml(meta.name)}</name>`);
  lines.push(`    <description>${escXml(meta.description)}</description>`);
  if (meta.icon) lines.push(`    <icon>${meta.icon}</icon>`);
  if (meta.studio_pro_category instanceof Some) {
    lines.push(`    <studioProCategory>${escXml(meta.studio_pro_category[0])}</studioProCategory>`);
  }
  if (meta.help_url instanceof Some) {
    lines.push(`    <helpUrl>${escXml(meta.help_url[0])}</helpUrl>`);
  }
  if (meta.prompt instanceof Some) {
    lines.push(`    <prompt>${escXml(meta.prompt[0])}</prompt>`);
  }

  lines.push("    <properties>");
  for (const g of groups.toArray()) {
    lines.push(serializeGroup(g, "        "));
  }
  lines.push("    </properties>");
  lines.push("</widget>");

  return lines.join("\n") + "\n";
}

// ── 비동기 키 입력 (marketplace_ffi.mjs 패턴 복제 + Tab 분리) ──

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
  if (b === 0x09) return [14, ""];                 // Tab (별도 키 코드)

  // UTF-8
  let totalBytes = 1;
  if (b >= 0xc0 && b < 0xe0) totalBytes = 2;
  else if (b >= 0xe0 && b < 0xf0) totalBytes = 3;
  else if (b >= 0xf0) totalBytes = 4;
  return [9, buf.slice(0, totalBytes).toString("utf-8")];
}

// timeout_ms: 0 = 무한 대기, >0 = 타임아웃 후 [0,""] 반환
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
