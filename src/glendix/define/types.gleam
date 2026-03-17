// 위젯 XML 속성 정의 에디터 — 데이터 타입

import gleam/option.{type Option}

/// 위젯 XML 최상위 정보
pub type WidgetMeta {
  WidgetMeta(
    id: String,
    plugin_widget: Bool,
    offline_capable: Bool,
    supported_platform: String,
    needs_entity_context: Bool,
    name: String,
    description: String,
    studio_pro_category: Option(String),
    help_url: Option(String),
    icon: String,
    prompt: Option(String),
  )
}

/// 위젯 메타 정보의 이름을 반환한다.
pub fn widget_meta_name(meta: WidgetMeta) -> String {
  meta.name
}

/// 속성 그룹
pub type PropertyGroup {
  PropertyGroup(caption: String, items: List(PropertyItem))
}

/// 그룹 내 항목
pub type PropertyItem {
  PropItem(Property)
  SysPropItem(SystemProperty)
}

/// 시스템 속성 (Label, Name, TabIndex, Visibility, Editability)
pub type SystemProperty {
  SystemProperty(key: String)
}

/// 열거형 값
pub type EnumValue {
  EnumValue(key: String, caption: String)
}

/// returnType (expression 속성에서 사용)
pub type ReturnType {
  ReturnType(type_name: String, assignable_to: Option(String))
}

/// 속성 타입
pub type PropertyType {
  // Static
  TypeString
  TypeBoolean
  TypeInteger
  TypeDecimal
  TypeEnumeration
  // Component
  TypeIcon
  TypeImage
  TypeWidgets
  TypeFile
  // Dynamic
  TypeExpression
  TypeTextTemplate
  TypeAction
  TypeAttribute
  TypeAssociation
  TypeObject
  TypeDatasource
  TypeSelection
}

/// 속성 정의 (Option 필드 — 타입별 해당 없으면 None)
pub type Property {
  Property(
    key: String,
    type_: PropertyType,
    caption: String,
    description: String,
    required: Option(Bool),
    default_value: Option(String),
    multiline: Option(Bool),
    is_list: Option(Bool),
    data_source: Option(String),
    allow_upload: Option(Bool),
    on_change: Option(String),
    set_label: Option(Bool),
    return_type: Option(ReturnType),
    enumeration_values: List(EnumValue),
    attribute_types: List(String),
    association_types: List(String),
    selection_types: List(String),
    default_type: Option(String),
    sub_properties: List(PropertyGroup),
  )
}

/// PropertyType → XML 문자열
pub fn type_to_string(t: PropertyType) -> String {
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

/// XML 문자열 → PropertyType
pub fn string_to_type(s: String) -> Result(PropertyType, Nil) {
  case s {
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
    _ -> Error(Nil)
  }
}

/// PropertyType의 한국어 설명
pub fn type_label(t: PropertyType) -> String {
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

/// 기본 Property 생성 (타입별 기본값)
pub fn default_property(key: String, t: PropertyType) -> Property {
  Property(
    key: key,
    type_: t,
    caption: key,
    description: "",
    required: case t {
      TypeString | TypeBoolean | TypeInteger | TypeDecimal | TypeEnumeration ->
        option.Some(True)
      _ -> option.None
    },
    default_value: case t {
      TypeString -> option.Some("")
      TypeBoolean -> option.Some("false")
      _ -> option.None
    },
    multiline: case t {
      TypeString -> option.Some(False)
      _ -> option.None
    },
    is_list: case t {
      TypeDatasource | TypeObject -> option.Some(False)
      _ -> option.None
    },
    data_source: option.None,
    allow_upload: case t {
      TypeImage | TypeFile -> option.Some(False)
      _ -> option.None
    },
    on_change: option.None,
    set_label: option.None,
    return_type: option.None,
    enumeration_values: [],
    attribute_types: [],
    association_types: [],
    selection_types: [],
    default_type: option.None,
    sub_properties: [],
  )
}

/// 모든 PropertyType 목록 (타입 선택 화면에서 사용)
pub fn all_types() -> List(PropertyType) {
  [
    TypeString, TypeBoolean, TypeInteger, TypeDecimal, TypeEnumeration,
    TypeIcon, TypeImage, TypeWidgets, TypeFile,
    TypeExpression, TypeTextTemplate, TypeAction, TypeAttribute,
    TypeAssociation, TypeObject, TypeDatasource, TypeSelection,
  ]
}

/// 시스템 속성 키 목록
pub fn all_system_keys() -> List(String) {
  ["Label", "Name", "TabIndex", "Visibility", "Editability"]
}
