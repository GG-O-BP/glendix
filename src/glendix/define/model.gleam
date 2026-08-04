//// Defines the editable Mendix widget property model used by the Glendix TUI.
////

import gleam/option

/// Describes a property-type decoding failure.
pub type PropertyTypeError {
  /// The serialized property type is not one of the supported Mendix values.
  UnknownPropertyType(value: String)
}

/// A typed `WidgetMeta` value used by the model capability.
pub type WidgetMeta {
  /// The `WidgetMeta` variant.
  WidgetMeta(
    id: String,
    plugin_widget: Bool,
    offline_capable: Bool,
    supported_platform: String,
    needs_entity_context: Bool,
    name: String,
    description: String,
    studio_pro_category: option.Option(String),
    help_url: option.Option(String),
    icon: String,
    prompt: option.Option(String),
  )
}

/// A typed `PropertyGroup` value used by the model capability.
pub type PropertyGroup {
  /// The `PropertyGroup` variant.
  PropertyGroup(caption: String, items: List(PropertyItem))
}

/// A typed `PropertyItem` value used by the model capability.
pub type PropertyItem {
  /// The `PropItem` variant.
  PropItem(Property)
  /// The `SysPropItem` variant.
  SysPropItem(SystemProperty)
}

/// A typed `SystemProperty` value used by the model capability.
pub type SystemProperty {
  /// The `SystemProperty` variant.
  SystemProperty(key: String)
}

/// A typed `EnumValue` value used by the model capability.
pub type EnumValue {
  /// The `EnumValue` variant.
  EnumValue(key: String, caption: String)
}

/// A typed `ReturnType` value used by the model capability.
pub type ReturnType {
  /// The `ReturnType` variant.
  ReturnType(type_name: String, assignable_to: option.Option(String))
}

/// A typed `PropertyType` value used by the model capability.
pub type PropertyType {
  // Static
  /// The `TypeString` variant.
  TypeString
  /// The `TypeBoolean` variant.
  TypeBoolean
  /// The `TypeInteger` variant.
  TypeInteger
  /// The `TypeDecimal` variant.
  TypeDecimal
  /// The `TypeEnumeration` variant.
  TypeEnumeration
  // Component
  /// The `TypeIcon` variant.
  TypeIcon
  /// The `TypeImage` variant.
  TypeImage
  /// The `TypeWidgets` variant.
  TypeWidgets
  /// The `TypeFile` variant.
  TypeFile
  // Dynamic
  /// The `TypeExpression` variant.
  TypeExpression
  /// The `TypeTextTemplate` variant.
  TypeTextTemplate
  /// The `TypeAction` variant.
  TypeAction
  /// The `TypeAttribute` variant.
  TypeAttribute
  /// The `TypeAssociation` variant.
  TypeAssociation
  /// The `TypeObject` variant.
  TypeObject
  /// The `TypeDatasource` variant.
  TypeDatasource
  /// The `TypeSelection` variant.
  TypeSelection
}

/// A typed `Property` value used by the model capability.
pub type Property {
  /// The `Property` variant.
  Property(
    key: String,
    type_: PropertyType,
    caption: String,
    description: String,
    required: option.Option(Bool),
    default_value: option.Option(String),
    multiline: option.Option(Bool),
    is_list: option.Option(Bool),
    data_source: option.Option(String),
    allow_upload: option.Option(Bool),
    on_change: option.Option(String),
    set_label: option.Option(Bool),
    return_type: option.Option(ReturnType),
    enumeration_values: List(EnumValue),
    attribute_types: List(String),
    association_types: List(String),
    selection_types: List(String),
    default_type: option.Option(String),
    selectable_objects: option.Option(String),
    sub_properties: List(PropertyGroup),
  )
}

/// Returns the widget display name.
pub fn widget_meta_name(meta meta: WidgetMeta) -> String {
  meta.name
}

/// Serializes a property type for widget XML.
pub fn type_to_string(t t: PropertyType) -> String {
  case t {
    TypeString -> "string"
    TypeBoolean -> "boolean"
    TypeInteger -> "integer"
    TypeDecimal -> "decimal"
    TypeEnumeration -> "enumeration"
    TypeIcon -> "icon"
    TypeImage -> "image"
    TypeWidgets -> "widgets"
    TypeFile -> "file"
    TypeExpression -> "expression"
    TypeTextTemplate -> "textTemplate"
    TypeAction -> "action"
    TypeAttribute -> "attribute"
    TypeAssociation -> "association"
    TypeObject -> "object"
    TypeDatasource -> "datasource"
    TypeSelection -> "selection"
  }
}

/// Parses a serialized Mendix property type.
pub fn string_to_type(
  from value: String,
) -> Result(PropertyType, PropertyTypeError) {
  case value {
    "string" -> Ok(TypeString)
    "boolean" -> Ok(TypeBoolean)
    "integer" -> Ok(TypeInteger)
    "decimal" -> Ok(TypeDecimal)
    "enumeration" -> Ok(TypeEnumeration)
    "icon" -> Ok(TypeIcon)
    "image" -> Ok(TypeImage)
    "widgets" -> Ok(TypeWidgets)
    "file" -> Ok(TypeFile)
    "expression" -> Ok(TypeExpression)
    "textTemplate" -> Ok(TypeTextTemplate)
    "action" -> Ok(TypeAction)
    "attribute" -> Ok(TypeAttribute)
    "association" -> Ok(TypeAssociation)
    "object" -> Ok(TypeObject)
    "datasource" -> Ok(TypeDatasource)
    "selection" -> Ok(TypeSelection)
    _ -> Error(UnknownPropertyType(value: value))
  }
}

/// Returns the user-facing label for a property type.
pub fn type_label(t t: PropertyType) -> String {
  case t {
    TypeString -> "문자열"
    TypeBoolean -> "참/거짓"
    TypeInteger -> "정수"
    TypeDecimal -> "소수"
    TypeEnumeration -> "열거형"
    TypeIcon -> "아이콘"
    TypeImage -> "이미지"
    TypeWidgets -> "위젯 슬롯"
    TypeFile -> "파일"
    TypeExpression -> "표현식"
    TypeTextTemplate -> "텍스트 템플릿"
    TypeAction -> "액션"
    TypeAttribute -> "속성 바인딩"
    TypeAssociation -> "연관"
    TypeObject -> "객체"
    TypeDatasource -> "데이터소스"
    TypeSelection -> "선택"
  }
}

/// Creates a property with defaults for the selected type.
pub fn default_property(key key: String, t t: PropertyType) -> Property {
  Property(
    key: key,
    type_: t,
    caption: key,
    description: "",
    required: case t {
      TypeString | TypeBoolean | TypeInteger | TypeDecimal | TypeEnumeration ->
        option.Some(True)
      TypeIcon
      | TypeImage
      | TypeWidgets
      | TypeFile
      | TypeExpression
      | TypeTextTemplate
      | TypeAction
      | TypeAttribute
      | TypeAssociation
      | TypeObject
      | TypeDatasource
      | TypeSelection -> option.None
    },
    default_value: case t {
      TypeString -> option.Some("")
      TypeBoolean -> option.Some("false")
      TypeInteger
      | TypeDecimal
      | TypeEnumeration
      | TypeIcon
      | TypeImage
      | TypeWidgets
      | TypeFile
      | TypeExpression
      | TypeTextTemplate
      | TypeAction
      | TypeAttribute
      | TypeAssociation
      | TypeObject
      | TypeDatasource
      | TypeSelection -> option.None
    },
    multiline: case t {
      TypeString -> option.Some(False)
      TypeBoolean
      | TypeInteger
      | TypeDecimal
      | TypeEnumeration
      | TypeIcon
      | TypeImage
      | TypeWidgets
      | TypeFile
      | TypeExpression
      | TypeTextTemplate
      | TypeAction
      | TypeAttribute
      | TypeAssociation
      | TypeObject
      | TypeDatasource
      | TypeSelection -> option.None
    },
    is_list: case t {
      TypeDatasource | TypeObject -> option.Some(False)
      TypeString
      | TypeBoolean
      | TypeInteger
      | TypeDecimal
      | TypeEnumeration
      | TypeIcon
      | TypeImage
      | TypeWidgets
      | TypeFile
      | TypeExpression
      | TypeTextTemplate
      | TypeAction
      | TypeAttribute
      | TypeAssociation
      | TypeSelection -> option.None
    },
    data_source: option.None,
    allow_upload: case t {
      TypeImage | TypeFile -> option.Some(False)
      TypeString
      | TypeBoolean
      | TypeInteger
      | TypeDecimal
      | TypeEnumeration
      | TypeIcon
      | TypeWidgets
      | TypeExpression
      | TypeTextTemplate
      | TypeAction
      | TypeAttribute
      | TypeAssociation
      | TypeObject
      | TypeDatasource
      | TypeSelection -> option.None
    },
    on_change: option.None,
    set_label: option.None,
    return_type: option.None,
    enumeration_values: [],
    attribute_types: [],
    association_types: [],
    selection_types: [],
    default_type: option.None,
    selectable_objects: option.None,
    sub_properties: [],
  )
}

/// Returns all the types.
pub fn all_types() -> List(PropertyType) {
  [
    TypeString, TypeBoolean, TypeInteger, TypeDecimal, TypeEnumeration, TypeIcon,
    TypeImage, TypeWidgets, TypeFile, TypeExpression, TypeTextTemplate,
    TypeAction, TypeAttribute, TypeAssociation, TypeObject, TypeDatasource,
    TypeSelection,
  ]
}

/// Returns all the system keys.
pub fn all_system_keys() -> List(String) {
  ["Label", "Name", "TabIndex", "Visibility", "Editability"]
}

/// Rebuilds a property for a newly selected type.
pub fn change_property_type(
  prop prop: Property,
  new_type new_type: PropertyType,
) -> Property {
  let d = default_property(prop.key, new_type)
  Property(..d, caption: prop.caption, description: prop.description)
}

/// Returns the display order for a property type.
pub fn type_index(t t: PropertyType) -> Int {
  case t {
    TypeString -> 0
    TypeBoolean -> 1
    TypeInteger -> 2
    TypeDecimal -> 3
    TypeEnumeration -> 4
    TypeIcon -> 5
    TypeImage -> 6
    TypeWidgets -> 7
    TypeFile -> 8
    TypeExpression -> 9
    TypeTextTemplate -> 10
    TypeAction -> 11
    TypeAttribute -> 12
    TypeAssociation -> 13
    TypeObject -> 14
    TypeDatasource -> 15
    TypeSelection -> 16
  }
}

/// Returns all the attribute types.
pub fn all_attribute_types() -> List(String) {
  [
    "AutoNumber", "Binary", "Boolean", "DateTime", "Enum", "HashString",
    "Integer", "Long", "String", "Decimal",
  ]
}

/// Returns all the association types.
pub fn all_association_types() -> List(String) {
  ["Reference", "ReferenceSet"]
}

/// Returns all the selection types.
pub fn all_selection_types() -> List(String) {
  ["None", "Single", "Multi"]
}
