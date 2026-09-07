//// Parses and serializes Mendix widget definition XML.
////

import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glendix/define/model
import xmlm

/// Describes a widget definition XML parsing failure.
@internal
pub type WidgetXmlError {
  /// The input is not a well-formed XML document.
  MalformedWidgetXml(reason: String)
  /// The XML document root is not a Mendix widget element.
  WidgetRootWasExpected(actual: String)
}

/// Parses one complete Mendix widget definition document.
///
/// Malformed XML and documents whose root is not `widget` return a descriptive
/// error rather than a partial widget model.
@internal
pub fn parse(
  source source: String,
) -> Result(#(model.WidgetMeta, List(model.PropertyGroup)), WidgetXmlError) {
  use #(_, root, input) <- result.try(
    xmlm.from_string(source)
    |> xmlm.document_tree(
      element_callback: xml_node,
      data_callback: fn(data: String) -> XmlNode { XmlText(data) },
    )
    |> result.map_error(xml_error),
  )
  use #(at_end, _) <- result.try(xmlm.eoi(input) |> result.map_error(xml_error))

  case at_end {
    False -> Error(MalformedWidgetXml(reason: "unexpected trailing XML data"))
    True -> parse_widget_root(root)
  }
}

/// Returns a human-readable explanation of a widget XML parsing failure.
@internal
pub fn error_message(error error: WidgetXmlError) -> String {
  case error {
    MalformedWidgetXml(reason) -> "Unable to parse widget XML: " <> reason
    WidgetRootWasExpected(actual) ->
      "Unable to parse widget XML: expected <widget> root, found <"
      <> actual
      <> ">."
  }
}

/// Serializes a widget definition using the stable Glendix XML layout.
@internal
pub fn serialize(
  meta meta: model.WidgetMeta,
  groups groups: List(model.PropertyGroup),
) -> String {
  let attributes = [
    xml_attribute("id", meta.id),
    bool_attribute("pluginWidget", meta.plugin_widget),
    bool_attribute("needsEntityContext", meta.needs_entity_context),
    bool_attribute("offlineCapable", meta.offline_capable),
    xml_attribute("supportedPlatform", meta.supported_platform),
    xml_attribute("xmlns", mendix_widget_namespace),
    xml_attribute("xmlns:xsi", xml_schema_instance_namespace),
    xml_attribute("xsi:schemaLocation", schema_location),
  ]
  let lines = [
    "<?xml version=\"1.0\" encoding=\"utf-8\" ?>",
    "<widget " <> string.join(attributes, " ") <> ">",
    "    <name>" <> escape_xml(meta.name) <> "</name>",
    "    <description>" <> escape_xml(meta.description) <> "</description>",
  ]
  let lines = case meta.icon {
    "" -> lines
    icon -> list.append(lines, ["    <icon>" <> icon <> "</icon>"])
  }
  let lines =
    append_optional_element(
      lines,
      "studioProCategory",
      meta.studio_pro_category,
    )
  let lines = append_optional_element(lines, "helpUrl", meta.help_url)
  let lines = append_optional_element(lines, "prompt", meta.prompt)
  let lines = list.append(lines, ["    <properties>"])
  let lines =
    list.append(lines, list.map(groups, serialize_group(_, "        ")))
  let lines = list.append(lines, ["    </properties>", "</widget>"])

  string.join(lines, "\n") <> "\n"
}

const mendix_widget_namespace = "http://www.mendix.com/widget/1.0/"

const xml_schema_instance_namespace = "http://www.w3.org/2001/XMLSchema-instance"

const schema_location = "http://www.mendix.com/widget/1.0/ ../node_modules/mendix/custom_widget.xsd"

type XmlAttribute {
  XmlAttribute(local_name: String, value: String)
}

type XmlNode {
  XmlElement(
    namespace_uri: String,
    local_name: String,
    attributes: List(XmlAttribute),
    children: List(XmlNode),
  )
  XmlText(String)
}

fn xml_node(tag: xmlm.Tag, children: List(XmlNode)) -> XmlNode {
  let xmlm.Tag(name, attributes) = tag
  let xmlm.Name(namespace_uri, local_name) = name
  XmlElement(
    namespace_uri: namespace_uri,
    local_name: local_name,
    attributes: list.map(attributes, fn(attribute: xmlm.Attribute) {
      let xmlm.Attribute(name, value) = attribute
      let xmlm.Name(_, local_name) = name
      XmlAttribute(local_name: local_name, value: value)
    }),
    children: children,
  )
}

fn xml_error(error: xmlm.InputError) -> WidgetXmlError {
  MalformedWidgetXml(reason: xmlm.input_error_to_string(error))
}

fn parse_widget_root(
  root: XmlNode,
) -> Result(#(model.WidgetMeta, List(model.PropertyGroup)), WidgetXmlError) {
  case root {
    XmlText(_) -> Error(WidgetRootWasExpected(actual: "text"))
    XmlElement(_, "widget", attributes, children) -> {
      let studio_pro_category = case child_text(children, "studioProCategory") {
        option.Some(value) -> option.Some(value)
        option.None -> child_text(children, "studioCategory")
      }
      let meta =
        model.WidgetMeta(
          id: attribute_or(attributes, "id", ""),
          plugin_widget: bool_attribute_or(attributes, "pluginWidget", False),
          offline_capable: bool_attribute_or(
            attributes,
            "offlineCapable",
            False,
          ),
          supported_platform: attribute_or(
            attributes,
            "supportedPlatform",
            "Web",
          ),
          needs_entity_context: bool_attribute_or(
            attributes,
            "needsEntityContext",
            False,
          ),
          name: child_text_or(children, "name", "Unknown"),
          description: child_text_or(children, "description", "")
            |> string.trim,
          studio_pro_category: studio_pro_category,
          help_url: child_text(children, "helpUrl"),
          icon: child_text_or(children, "icon", ""),
          prompt: child_text(children, "prompt") |> option.map(string.trim),
        )
      let groups = case child_element(children, "properties") {
        option.Some(XmlElement(_, _, _, property_children)) ->
          parse_groups(property_children)
        option.Some(XmlText(_)) | option.None -> []
      }
      Ok(#(meta, groups))
    }
    XmlElement(_, actual, _, _) -> Error(WidgetRootWasExpected(actual: actual))
  }
}

fn parse_groups(children: List(XmlNode)) -> List(model.PropertyGroup) {
  children
  |> list.filter_map(fn(node: XmlNode) -> Result(model.PropertyGroup, Nil) {
    case node {
      XmlElement(_, "propertyGroup", attributes, group_children) ->
        Ok(model.PropertyGroup(
          caption: attribute_or(attributes, "caption", ""),
          items: parse_items(group_children),
        ))
      XmlElement(_, _, _, _) | XmlText(_) -> Error(Nil)
    }
  })
}

fn parse_items(children: List(XmlNode)) -> List(model.PropertyItem) {
  children
  |> list.filter_map(fn(node: XmlNode) -> Result(model.PropertyItem, Nil) {
    case node {
      XmlElement(_, "property", attributes, property_children) ->
        Ok(model.PropItem(parse_property(attributes, property_children)))
      XmlElement(_, "systemProperty", attributes, _) ->
        Ok(
          model.SysPropItem(
            model.SystemProperty(key: attribute_or(attributes, "key", "")),
          ),
        )
      XmlElement(_, _, _, _) | XmlText(_) -> Error(Nil)
    }
  })
}

fn parse_property(
  attributes: List(XmlAttribute),
  children: List(XmlNode),
) -> model.Property {
  let key = attribute_or(attributes, "key", "")
  let property_type =
    attribute_or(attributes, "type", "string")
    |> model.string_to_type
    |> result.unwrap(model.TypeString)
  let return_type = case child_element(children, "returnType") {
    option.Some(XmlElement(_, _, return_attributes, _)) ->
      option.Some(model.ReturnType(
        type_name: attribute_or(return_attributes, "type", ""),
        assignable_to: attribute(return_attributes, "assignableTo"),
      ))
    option.Some(XmlText(_)) | option.None -> option.None
  }

  model.Property(
    key: key,
    type_: property_type,
    caption: child_text_or(children, "caption", key),
    description: child_text_or(children, "description", ""),
    required: optional_bool_attribute(attributes, "required"),
    default_value: attribute(attributes, "defaultValue"),
    multiline: optional_bool_attribute(attributes, "multiline"),
    is_list: optional_bool_attribute(attributes, "isList"),
    data_source: attribute(attributes, "dataSource"),
    allow_upload: optional_bool_attribute(attributes, "allowUpload"),
    on_change: attribute(attributes, "onChange"),
    set_label: optional_bool_attribute(attributes, "setLabel"),
    return_type: return_type,
    enumeration_values: parse_enumeration_values(children),
    attribute_types: parse_named_types(
      children,
      container_name: "attributeTypes",
      item_name: "attributeType",
    ),
    association_types: parse_named_types(
      children,
      container_name: "associationTypes",
      item_name: "associationType",
    ),
    selection_types: parse_named_types(
      children,
      container_name: "selectionTypes",
      item_name: "selectionType",
    ),
    default_type: attribute(attributes, "defaultType"),
    selectable_objects: attribute(attributes, "selectableObjects"),
    sub_properties: case child_element(children, "properties") {
      option.Some(XmlElement(_, _, _, property_children)) ->
        parse_groups(property_children)
      option.Some(XmlText(_)) | option.None -> []
    },
  )
}

fn parse_enumeration_values(children: List(XmlNode)) -> List(model.EnumValue) {
  case child_element(children, "enumerationValues") {
    option.Some(XmlElement(_, _, _, enumeration_children)) ->
      enumeration_children
      |> list.filter_map(fn(node: XmlNode) -> Result(model.EnumValue, Nil) {
        case node {
          XmlElement(_, "enumerationValue", attributes, _) ->
            Ok(model.EnumValue(
              key: attribute_or(attributes, "key", ""),
              caption: node_text(node),
            ))
          XmlElement(_, _, _, _) | XmlText(_) -> Error(Nil)
        }
      })
    option.Some(XmlText(_)) | option.None -> []
  }
}

fn parse_named_types(
  children: List(XmlNode),
  container_name container_name: String,
  item_name item_name: String,
) -> List(String) {
  case child_element(children, container_name) {
    option.Some(XmlElement(_, _, _, type_children)) ->
      type_children
      |> list.filter_map(fn(node: XmlNode) -> Result(String, Nil) {
        case node {
          XmlElement(_, local_name, attributes, _) if local_name == item_name ->
            Ok(attribute_or(attributes, "name", ""))
          XmlElement(_, _, _, _) | XmlText(_) -> Error(Nil)
        }
      })
    option.Some(XmlText(_)) | option.None -> []
  }
}

fn child_element(
  children: List(XmlNode),
  local_name: String,
) -> option.Option(XmlNode) {
  case children {
    [] -> option.None
    [child, ..rest] ->
      case child {
        XmlElement(_, child_name, _, _) if child_name == local_name ->
          option.Some(child)
        XmlElement(_, _, _, _) | XmlText(_) -> child_element(rest, local_name)
      }
  }
}

fn child_text(
  children: List(XmlNode),
  local_name: String,
) -> option.Option(String) {
  child_element(children, local_name)
  |> option.map(node_text)
}

fn child_text_or(
  children: List(XmlNode),
  local_name: String,
  default: String,
) -> String {
  case child_text(children, local_name) {
    option.Some(value) -> value
    option.None -> default
  }
}

fn node_text(node: XmlNode) -> String {
  case node {
    XmlText(data) -> data
    XmlElement(_, _, _, children) ->
      children
      |> list.map(node_text)
      |> string.concat
  }
}

fn attribute(
  attributes: List(XmlAttribute),
  local_name: String,
) -> option.Option(String) {
  case attributes {
    [] -> option.None
    [XmlAttribute(attribute_name, value), ..rest] ->
      case attribute_name == local_name {
        True -> option.Some(value)
        False -> attribute(rest, local_name)
      }
  }
}

fn attribute_or(
  attributes: List(XmlAttribute),
  local_name: String,
  default: String,
) -> String {
  case attribute(attributes, local_name) {
    option.Some(value) -> value
    option.None -> default
  }
}

fn bool_attribute_or(
  attributes: List(XmlAttribute),
  local_name: String,
  default: Bool,
) -> Bool {
  case attribute(attributes, local_name) {
    option.Some("true") -> True
    option.Some(_) -> False
    option.None -> default
  }
}

fn optional_bool_attribute(
  attributes: List(XmlAttribute),
  local_name: String,
) -> option.Option(Bool) {
  case attribute(attributes, local_name) {
    option.Some("true") -> option.Some(True)
    option.Some(_) -> option.Some(False)
    option.None -> option.None
  }
}

fn append_optional_element(
  lines: List(String),
  name: String,
  value: option.Option(String),
) -> List(String) {
  case value {
    option.Some(content) ->
      list.append(lines, [
        "    <" <> name <> ">" <> escape_xml(content) <> "</" <> name <> ">",
      ])
    option.None -> lines
  }
}

fn serialize_group(group: model.PropertyGroup, indent: String) -> String {
  let child_indent = indent <> "    "
  let lines = [
    indent <> "<propertyGroup caption=\"" <> escape_xml(group.caption) <> "\">",
  ]
  let lines =
    list.append(
      lines,
      list.map(group.items, fn(item: model.PropertyItem) -> String {
        case item {
          model.SysPropItem(property) ->
            child_indent
            <> "<systemProperty key=\""
            <> escape_xml(property.key)
            <> "\" />"
          model.PropItem(property) -> serialize_property(property, child_indent)
        }
      }),
    )
  let lines = list.append(lines, [indent <> "</propertyGroup>"])
  string.join(lines, "\n")
}

fn serialize_property(property: model.Property, indent: String) -> String {
  let child_indent = indent <> "    "
  let attributes = [
    xml_attribute("key", property.key),
    xml_attribute("type", model.type_to_string(property.type_)),
  ]
  let attributes =
    append_optional_bool_attribute(attributes, "required", property.required)
  let attributes =
    append_optional_attribute(
      attributes,
      "defaultValue",
      property.default_value,
    )
  let attributes =
    append_optional_bool_attribute(attributes, "multiline", property.multiline)
  let attributes =
    append_optional_bool_attribute(attributes, "isList", property.is_list)
  let attributes =
    append_optional_attribute(attributes, "dataSource", property.data_source)
  let attributes =
    append_optional_bool_attribute(
      attributes,
      "allowUpload",
      property.allow_upload,
    )
  let attributes =
    append_optional_attribute(attributes, "onChange", property.on_change)
  let attributes =
    append_optional_bool_attribute(attributes, "setLabel", property.set_label)
  let attributes =
    append_optional_attribute(attributes, "defaultType", property.default_type)
  let attributes =
    append_optional_attribute(
      attributes,
      "selectableObjects",
      property.selectable_objects,
    )
  let lines = [
    indent <> "<property " <> string.join(attributes, " ") <> ">",
    child_indent <> "<caption>" <> escape_xml(property.caption) <> "</caption>",
    child_indent
      <> "<description>"
      <> escape_xml(property.description)
      <> "</description>",
  ]
  let lines = case property.return_type {
    option.Some(return_type) -> {
      let attributes = [xml_attribute("type", return_type.type_name)]
      let attributes =
        append_optional_attribute(
          attributes,
          "assignableTo",
          return_type.assignable_to,
        )
      list.append(lines, [
        child_indent <> "<returnType " <> string.join(attributes, " ") <> " />",
      ])
    }
    option.None -> lines
  }
  let lines =
    append_value_container(
      lines,
      child_indent,
      container_name: "enumerationValues",
      values: list.map(property.enumeration_values, serialize_enumeration_value),
    )
  let lines =
    append_value_container(
      lines,
      child_indent,
      container_name: "attributeTypes",
      values: list.map(property.attribute_types, serialize_named_type(
        _,
        "attributeType",
      )),
    )
  let lines =
    append_value_container(
      lines,
      child_indent,
      container_name: "associationTypes",
      values: list.map(property.association_types, serialize_named_type(
        _,
        "associationType",
      )),
    )
  let lines =
    append_value_container(
      lines,
      child_indent,
      container_name: "selectionTypes",
      values: list.map(property.selection_types, serialize_named_type(
        _,
        "selectionType",
      )),
    )
  let lines = case property.sub_properties {
    [] -> lines
    sub_properties -> {
      let nested_groups =
        list.map(sub_properties, serialize_group(_, child_indent <> "    "))
      let nested_lines = [child_indent <> "<properties>", ..nested_groups]
      let nested_lines =
        list.append(nested_lines, [child_indent <> "</properties>"])
      list.append(lines, nested_lines)
    }
  }
  let lines = list.append(lines, [indent <> "</property>"])
  string.join(lines, "\n")
}

fn serialize_enumeration_value(value: model.EnumValue) -> String {
  "<enumerationValue key=\""
  <> escape_xml(value.key)
  <> "\">"
  <> escape_xml(value.caption)
  <> "</enumerationValue>"
}

fn serialize_named_type(value: String, name: String) -> String {
  "<" <> name <> " name=\"" <> escape_xml(value) <> "\" />"
}

fn append_value_container(
  lines: List(String),
  indent: String,
  container_name container_name: String,
  values values: List(String),
) -> List(String) {
  case values {
    [] -> lines
    values -> {
      let value_lines =
        list.map(values, fn(value: String) -> String {
          indent <> "    " <> value
        })
      let container_lines = [
        indent <> "<" <> container_name <> ">",
        ..value_lines
      ]
      let container_lines =
        list.append(container_lines, [
          indent <> "</" <> container_name <> ">",
        ])
      list.append(lines, container_lines)
    }
  }
}

fn append_optional_attribute(
  attributes: List(String),
  name: String,
  value: option.Option(String),
) -> List(String) {
  case value {
    option.Some(content) ->
      list.append(attributes, [xml_attribute(name, content)])
    option.None -> attributes
  }
}

fn append_optional_bool_attribute(
  attributes: List(String),
  name: String,
  value: option.Option(Bool),
) -> List(String) {
  case value {
    option.Some(content) ->
      list.append(attributes, [bool_attribute(name, content)])
    option.None -> attributes
  }
}

fn xml_attribute(name: String, value: String) -> String {
  name <> "=\"" <> escape_xml(value) <> "\""
}

fn bool_attribute(name: String, value: Bool) -> String {
  xml_attribute(name, bool_to_xml(value))
}

fn bool_to_xml(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}

fn escape_xml(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
}
