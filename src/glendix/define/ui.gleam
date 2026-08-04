//// Renders screens for the interactive Glendix widget definition editor.
////

import etch/style
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import glendix/define/model

/// A typed `EditField` value used by the ui capability.
pub type EditField {
  /// The `TextField` variant.
  TextField(label: String, value: String)
  /// The `BoolField` variant.
  BoolField(label: String, value: Bool)
  /// The `ReadOnlyField` variant.
  ReadOnlyField(label: String, value: String)
  /// The `ListField` variant.
  ListField(label: String, count: Int)
  /// The `SelectField` variant.
  SelectField(label: String, value: String)
}

/// Represents whether the editor has unsaved changes.
pub type ChangeState {
  /// The rendered model is saved.
  Saved
  /// The rendered model contains unsaved changes.
  Modified
}

/// Represents whether a text field is actively being edited.
pub type EditMode {
  /// The field is displayed without an active text cursor.
  Viewing
  /// The field is displayed with an active text cursor.
  Editing
}

/// A typed `TreeRow` value used by the ui capability.
pub type TreeRow {
  /// The `GroupRow` variant.
  GroupRow(
    flat_index: Int,
    group_index: Int,
    caption: String,
    item_count: Int,
    is_collapsed: Bool,
  )
  /// The `PropertyRow` variant.
  PropertyRow(
    flat_index: Int,
    group_index: Int,
    item_index: Int,
    prop: model.Property,
  )
  /// The `SystemRow` variant.
  SystemRow(flat_index: Int, group_index: Int, item_index: Int, key: String)
}

/// Renders the tree screen.
pub fn render_tree_screen(
  widget_name widget_name: String,
  groups groups: List(model.PropertyGroup),
  cursor cursor: Int,
  collapsed collapsed: List(Int),
  changes changes: ChangeState,
  status_msg status_msg: option.Option(String),
  scroll_offset scroll_offset: Int,
  term_rows term_rows: Int,
) -> String {
  let dirty_mark = case changes {
    Modified -> " " <> style.yellow("● 변경사항")
    Saved -> ""
  }
  let header =
    "  "
    <> style.bold(style.cyan("── Widget Properties: " <> widget_name <> " ──"))
    <> dirty_mark
  let rows = build_tree_rows(groups, collapsed, 0, 0)
  let visible_rows = case term_rows > 6 {
    True -> term_rows - 6
    False -> 10
  }
  let display_rows =
    rows
    |> list.drop(scroll_offset)
    |> list.take(visible_rows)
  let body = case display_rows {
    [] -> "    " <> style.dim("속성이 없습니다. a로 속성을 추가하세요.")
    _ ->
      display_rows
      |> list.map(fn(row) { render_tree_row(row, row.flat_index == cursor) })
      |> string.join("\n")
  }
  let status_line = case status_msg {
    option.Some(msg) -> "\n  " <> msg
    option.None -> ""
  }
  let help =
    "\n  "
    <> style.dim(
      "↑↓ 이동 · Tab 접기 · Enter 편집 · w 위젯 정보 · a 속성 · g 그룹 · p 시스템 · d 삭제 · s 저장 · q 종료",
    )
  header <> "\n\n" <> body <> "\n" <> status_line <> help <> "\n"
}

/// Builds the tree rows.
pub fn build_tree_rows(
  groups groups: List(model.PropertyGroup),
  collapsed collapsed: List(Int),
  group_start group_start: Int,
  flat_start flat_start: Int,
) -> List(TreeRow) {
  case groups {
    [] -> []
    [group, ..rest] -> {
      let gi = group_start
      let is_collapsed = list.contains(collapsed, gi)
      let item_count = list.length(group.items)
      let group_row =
        GroupRow(flat_start, gi, group.caption, item_count, is_collapsed)
      case is_collapsed {
        True -> {
          [
            group_row,
            ..build_tree_rows(rest, collapsed, gi + 1, flat_start + 1)
          ]
        }
        False -> {
          let item_rows = build_item_rows(group.items, gi, 0, flat_start + 1)
          let next_flat = flat_start + 1 + list.length(group.items)
          [
            group_row,
            ..list.append(
              item_rows,
              build_tree_rows(rest, collapsed, gi + 1, next_flat),
            )
          ]
        }
      }
    }
  }
}

/// Renders the type select screen.
pub fn render_type_select_screen(cursor cursor: Int) -> String {
  let header = "  " <> style.bold(style.cyan("── 속성 타입 선택 ──"))
  let all = model.all_types()
  let body =
    all
    |> list.index_map(fn(t, idx) {
      let is_cur = idx == cursor
      let marker = case is_cur {
        True -> style.cyan("  ▸ ")
        False -> "    "
      }
      let type_name = model.type_to_string(t)
      let label = model.type_label(t)
      let name_styled = case is_cur {
        True -> style.bold(style.cyan(type_name |> pad_right(16)))
        False -> type_name |> pad_right(16)
      }
      let category = case idx < 5 {
        True -> style.dim("Static")
        False ->
          case idx < 9 {
            True -> style.dim("Component")
            False -> style.dim("Dynamic")
          }
      }
      let show_category = case idx {
        0 | 5 | 9 -> "  " <> category <> "\n"
        _ -> ""
      }
      show_category <> marker <> name_styled <> " — " <> style.dim(label)
    })
    |> string.join("\n")
  let help = "\n  " <> style.dim("↑↓ 이동 · Enter 선택 · Esc 취소")
  header <> "\n\n" <> body <> "\n" <> help <> "\n"
}

/// Renders the edit screen.
pub fn render_edit_screen(
  prop_key prop_key: String,
  prop_type prop_type: String,
  fields fields: List(EditField),
  cursor cursor: Int,
  mode mode: EditMode,
  edit_buffer edit_buffer: String,
  edit_cursor_pos edit_cursor_pos: Int,
) -> String {
  let header =
    "  "
    <> style.bold(style.cyan(
      "── 속성 편집: " <> prop_key <> " (" <> prop_type <> ") ──",
    ))
  let body =
    fields
    |> list.index_map(fn(field, idx) {
      let is_cur = idx == cursor
      let marker = case is_cur {
        True -> style.cyan("  ▸ ")
        False -> "    "
      }
      case field {
        ReadOnlyField(label, value) ->
          marker <> style.dim(label |> pad_right(16)) <> style.dim(value)
        TextField(label, value) -> {
          let display = case is_cur, mode {
            True, Editing -> render_text_cursor(edit_buffer, edit_cursor_pos)
            True, Viewing | False, Editing | False, Viewing -> value
          }
          marker <> label |> pad_right(16) <> display
        }
        BoolField(label, value) -> {
          let display = case value {
            True -> style.green("true")
            False -> style.red("false")
          }
          let toggle = case is_cur {
            True -> " " <> style.dim("◀▶")
            False -> ""
          }
          marker <> label |> pad_right(16) <> display <> toggle
        }
        ListField(label, count) ->
          marker
          <> label |> pad_right(16)
          <> style.dim("[" <> int.to_string(count) <> "개]")
          <> case is_cur {
            True -> " " <> style.dim("Enter 편집")
            False -> ""
          }
        SelectField(label, value) -> {
          let display = case is_cur {
            True -> style.bold(style.cyan(value))
            False -> style.cyan(value)
          }
          let hint = case is_cur {
            True -> " " <> style.dim("Enter 변경")
            False -> ""
          }
          marker <> label |> pad_right(16) <> display <> hint
        }
      }
    })
    |> string.join("\n")
  let help = "\n  " <> style.dim("↑↓ 필드 이동 · Enter 텍스트 편집 · ◀▶ 토글 · Esc 완료")
  header <> "\n\n" <> body <> "\n" <> help <> "\n"
}

/// Renders the enum edit screen.
pub fn render_enum_edit_screen(
  values values: List(model.EnumValue),
  cursor cursor: Int,
  status_msg status_msg: option.Option(String),
) -> String {
  let header = "  " <> style.bold(style.cyan("── 열거형 값 편집 ──"))
  let body = case values {
    [] -> "    " <> style.dim("값이 없습니다. a로 추가하세요.")
    _ ->
      values
      |> list.index_map(fn(v, idx) {
        let is_cur = idx == cursor
        let marker = case is_cur {
          True -> style.cyan("  ▸ ")
          False -> "    "
        }
        let key_str = case is_cur {
          True -> style.bold(style.cyan(v.key))
          False -> style.bold(v.key)
        }
        marker <> key_str <> " — " <> style.dim(v.caption)
      })
      |> string.join("\n")
  }
  let status_line = case status_msg {
    option.Some(msg) -> "\n  " <> msg
    option.None -> ""
  }
  let help = "\n  " <> style.dim("↑↓ 이동 · Enter 편집 · a 추가 · d 삭제 · Esc 완료")
  header <> "\n\n" <> body <> "\n" <> status_line <> help <> "\n"
}

/// Renders the sys prop screen.
pub fn render_sys_prop_screen(
  options options: List(String),
  cursor cursor: Int,
) -> String {
  let header = "  " <> style.bold(style.cyan("── 시스템 속성 추가 ──"))
  let body =
    options
    |> list.index_map(fn(key, idx) {
      let is_cur = idx == cursor
      let marker = case is_cur {
        True -> style.cyan("  ▸ ")
        False -> "    "
      }
      let name = case is_cur {
        True -> style.bold(style.cyan(key))
        False -> key
      }
      marker <> name
    })
    |> string.join("\n")
  let help = "\n  " <> style.dim("↑↓ 이동 · Enter 선택 · Esc 취소")
  header <> "\n\n" <> body <> "\n" <> help <> "\n"
}

/// Renders the input screen.
pub fn render_input_screen(
  title title: String,
  buffer buffer: String,
  cursor_pos cursor_pos: Int,
) -> String {
  let header = "  " <> style.bold(style.cyan("── " <> title <> " ──"))
  let input_line = "    " <> render_text_cursor(buffer, cursor_pos)
  let help = "\n  " <> style.dim("←→ 이동 · Enter 확인 · Esc 취소")
  header <> "\n\n" <> input_line <> "\n" <> help <> "\n"
}

/// Renders the confirm delete screen.
pub fn render_confirm_delete_screen(
  target_label target_label: String,
) -> String {
  let header = "  " <> style.bold(style.yellow("── 삭제 확인 ──"))
  let msg = "    " <> style.bold(target_label) <> "을(를) 삭제하시겠습니까?"
  let help = "\n  " <> style.dim("y 삭제 · n/Esc 취소")
  header <> "\n\n" <> msg <> "\n" <> help <> "\n"
}

/// Renders the confirm quit screen.
pub fn render_confirm_quit_screen() -> String {
  let header = "  " <> style.bold(style.yellow("── 저장하지 않은 변경사항 ──"))
  let msg = "    변경사항을 저장하지 않고 종료하시겠습니까?"
  let help = "\n  " <> style.dim("y 종료 · s 저장 후 종료 · n/Esc 취소")
  header <> "\n\n" <> msg <> "\n" <> help <> "\n"
}

/// Converts a property into editable form fields.
pub fn property_to_fields(prop prop: model.Property) -> List(EditField) {
  let base = [
    TextField("Key:", prop.key),
    SelectField("Type:", model.type_to_string(prop.type_)),
    TextField("Caption:", prop.caption),
    TextField("Description:", prop.description),
  ]
  let type_fields = case prop.type_ {
    model.TypeString -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
      TextField("Default:", option.unwrap(prop.default_value, "")),
      BoolField("Multiline:", option.unwrap(prop.multiline, False)),
    ]
    model.TypeBoolean -> [
      TextField("Default:", option.unwrap(prop.default_value, "false")),
    ]
    model.TypeInteger -> [
      TextField("Default:", option.unwrap(prop.default_value, "0")),
    ]
    model.TypeDecimal -> [
      TextField("Default:", option.unwrap(prop.default_value, "0")),
    ]
    model.TypeEnumeration -> [
      TextField("Default:", option.unwrap(prop.default_value, "")),
      ListField("EnumValues:", list.length(prop.enumeration_values)),
    ]
    model.TypeIcon -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
    ]
    model.TypeImage -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
      BoolField("AllowUpload:", option.unwrap(prop.allow_upload, False)),
    ]
    model.TypeWidgets -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
      TextField("DataSource:", option.unwrap(prop.data_source, "")),
    ]
    model.TypeFile -> [
      BoolField("AllowUpload:", option.unwrap(prop.allow_upload, False)),
    ]
    model.TypeExpression -> {
      let rt_type = case prop.return_type {
        option.Some(rt) -> rt.type_name
        option.None -> ""
      }
      let rt_assign = case prop.return_type {
        option.Some(rt) -> option.unwrap(rt.assignable_to, "")
        option.None -> ""
      }
      [
        BoolField("Required:", option.unwrap(prop.required, True)),
        TextField("Default:", option.unwrap(prop.default_value, "")),
        TextField("DataSource:", option.unwrap(prop.data_source, "")),
        TextField("ReturnType:", rt_type),
        TextField("AssignableTo:", rt_assign),
      ]
    }
    model.TypeTextTemplate -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
      BoolField("Multiline:", option.unwrap(prop.multiline, False)),
      TextField("DataSource:", option.unwrap(prop.data_source, "")),
    ]
    model.TypeAction -> [
      TextField("DataSource:", option.unwrap(prop.data_source, "")),
      TextField("Default:", option.unwrap(prop.default_value, "")),
      TextField("DefaultType:", option.unwrap(prop.default_type, "")),
    ]
    model.TypeAttribute -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
      TextField("OnChange:", option.unwrap(prop.on_change, "")),
      TextField("DataSource:", option.unwrap(prop.data_source, "")),
      BoolField("SetLabel:", option.unwrap(prop.set_label, False)),
      ListField("AttrTypes:", list.length(prop.attribute_types)),
    ]
    model.TypeAssociation -> [
      BoolField("Required:", option.unwrap(prop.required, True)),
      TextField("SelectObjs:", option.unwrap(prop.selectable_objects, "")),
      TextField("OnChange:", option.unwrap(prop.on_change, "")),
      TextField("DataSource:", option.unwrap(prop.data_source, "")),
      BoolField("SetLabel:", option.unwrap(prop.set_label, False)),
      ListField("AssocTypes:", list.length(prop.association_types)),
    ]
    model.TypeObject -> [
      BoolField("IsList:", option.unwrap(prop.is_list, True)),
      BoolField("Required:", option.unwrap(prop.required, True)),
    ]
    model.TypeDatasource -> [
      BoolField("IsList:", option.unwrap(prop.is_list, True)),
      BoolField("Required:", option.unwrap(prop.required, True)),
      TextField("DefaultType:", option.unwrap(prop.default_type, "")),
      TextField("Default:", option.unwrap(prop.default_value, "")),
    ]
    model.TypeSelection -> [
      TextField("DataSource:", option.unwrap(prop.data_source, "")),
      TextField("Default:", option.unwrap(prop.default_value, "")),
      TextField("OnChange:", option.unwrap(prop.on_change, "")),
      ListField("SelTypes:", list.length(prop.selection_types)),
    ]
  }
  list.append(base, type_fields)
}

/// Applies edited form fields to a property.
pub fn fields_to_property(
  original original: model.Property,
  fields fields: List(EditField),
) -> model.Property {
  let key = find_text_field(fields, "Key:", original.key)
  let caption = find_text_field(fields, "Caption:", original.caption)
  let description =
    find_text_field(fields, "Description:", original.description)
  let required = find_bool_field(fields, "Required:")
  let multiline = find_bool_field(fields, "Multiline:")
  let is_list = find_bool_field(fields, "IsList:")
  let allow_upload = find_bool_field(fields, "AllowUpload:")
  let set_label = find_bool_field(fields, "SetLabel:")
  let default_value = find_optional_text(fields, "Default:")
  let data_source = find_optional_text(fields, "DataSource:")
  let on_change = find_optional_text(fields, "OnChange:")
  let default_type = find_optional_text(fields, "DefaultType:")
  let selectable_objects = find_optional_text(fields, "SelectObjs:")
  let return_type = case find_optional_text(fields, "ReturnType:") {
    option.Some(type_name) -> {
      let assignable_to = find_optional_text(fields, "AssignableTo:")
      option.Some(model.ReturnType(type_name, assignable_to))
    }
    option.None -> option.None
  }
  model.Property(
    key: key,
    type_: original.type_,
    caption: caption,
    description: description,
    required: required,
    default_value: default_value,
    multiline: multiline,
    is_list: is_list,
    data_source: data_source,
    allow_upload: allow_upload,
    on_change: on_change,
    set_label: set_label,
    return_type: return_type,
    enumeration_values: original.enumeration_values,
    attribute_types: original.attribute_types,
    association_types: original.association_types,
    selection_types: original.selection_types,
    default_type: default_type,
    selectable_objects: selectable_objects,
    sub_properties: original.sub_properties,
  )
}

/// Converts widget metadata into editable form fields.
pub fn widget_meta_to_fields(meta meta: model.WidgetMeta) -> List(EditField) {
  let icon_display = case meta.icon {
    "" -> "(없음)"
    _ -> "(있음)"
  }
  [
    TextField("ID:", meta.id),
    ReadOnlyField("PluginWidget:", "true"),
    BoolField("OfflineCapable:", meta.offline_capable),
    BoolField("NeedsEntity:", meta.needs_entity_context),
    TextField("Platform:", meta.supported_platform),
    TextField("Name:", meta.name),
    TextField("Description:", meta.description),
    TextField("Category:", option.unwrap(meta.studio_pro_category, "")),
    TextField("HelpUrl:", option.unwrap(meta.help_url, "")),
    ReadOnlyField("Icon:", icon_display),
    TextField("Prompt:", option.unwrap(meta.prompt, "")),
  ]
}

/// Applies edited form fields to widget metadata.
pub fn fields_to_widget_meta(
  original original: model.WidgetMeta,
  fields fields: List(EditField),
) -> model.WidgetMeta {
  let id = find_text_field(fields, "ID:", original.id)
  let offline_capable = case find_bool_field(fields, "OfflineCapable:") {
    option.Some(v) -> v
    option.None -> original.offline_capable
  }
  let needs_entity_context = case find_bool_field(fields, "NeedsEntity:") {
    option.Some(v) -> v
    option.None -> original.needs_entity_context
  }
  let platform_raw =
    find_text_field(fields, "Platform:", original.supported_platform)
  let supported_platform = case platform_raw {
    "Native" -> "Native"
    _ -> "Web"
  }
  let name = find_text_field(fields, "Name:", original.name)
  let description =
    find_text_field(fields, "Description:", original.description)
  let category_raw = find_text_field(fields, "Category:", "")
  let studio_pro_category = case string.trim(category_raw) {
    "" -> option.None
    v -> option.Some(v)
  }
  let help_url_raw = find_text_field(fields, "HelpUrl:", "")
  let help_url = case string.trim(help_url_raw) {
    "" -> option.None
    v -> option.Some(v)
  }
  let prompt_raw = find_text_field(fields, "Prompt:", "")
  let prompt = case string.trim(prompt_raw) {
    "" -> option.None
    v -> option.Some(v)
  }
  model.WidgetMeta(
    id: id,
    plugin_widget: original.plugin_widget,
    offline_capable: offline_capable,
    supported_platform: supported_platform,
    needs_entity_context: needs_entity_context,
    name: name,
    description: description,
    studio_pro_category: studio_pro_category,
    help_url: help_url,
    icon: original.icon,
    prompt: prompt,
  )
}

/// Renders the multi select screen.
pub fn render_multi_select_screen(
  title title: String,
  options options: List(String),
  selected selected: List(String),
  cursor cursor: Int,
) -> String {
  let header = "  " <> style.bold(style.cyan("── " <> title <> " ──"))
  let body =
    options
    |> list.index_map(fn(opt, idx) {
      let is_cur = idx == cursor
      let is_selected = list.contains(selected, opt)
      let marker = case is_cur {
        True -> style.cyan("  ▸ ")
        False -> "    "
      }
      let check = case is_selected {
        True -> style.green("[*] ")
        False -> style.dim("[ ] ")
      }
      let name = case is_cur {
        True -> style.bold(style.cyan(opt))
        False -> opt
      }
      marker <> check <> name
    })
    |> string.join("\n")
  let help = "\n  " <> style.dim("↑↓ 이동 · Enter 토글 · Esc 완료")
  header <> "\n\n" <> body <> "\n" <> help <> "\n"
}

fn build_item_rows(
  items: List(model.PropertyItem),
  group_index: Int,
  item_start: Int,
  flat_start: Int,
) -> List(TreeRow) {
  case items {
    [] -> []
    [item, ..rest] -> {
      let row = case item {
        model.PropItem(prop) ->
          PropertyRow(flat_start, group_index, item_start, prop)
        model.SysPropItem(sys) ->
          SystemRow(flat_start, group_index, item_start, sys.key)
      }
      [
        row,
        ..build_item_rows(rest, group_index, item_start + 1, flat_start + 1)
      ]
    }
  }
}

fn render_tree_row(row: TreeRow, is_cursor: Bool) -> String {
  case row {
    GroupRow(_, _, caption, count, is_collapsed) -> {
      let marker = case is_cursor {
        True -> style.cyan("  ▸ ")
        False -> "    "
      }
      let fold_icon = case is_collapsed {
        True -> style.dim("▸ ")
        False -> style.dim("▾ ")
      }
      let name = case is_cursor {
        True -> style.bold(style.cyan("[" <> caption <> "]"))
        False -> style.bold("[" <> caption <> "]")
      }
      let suffix = case is_collapsed {
        True -> "  " <> style.dim("(접힘, " <> int.to_string(count) <> "개 항목)")
        False -> ""
      }
      marker <> fold_icon <> name <> suffix
    }
    PropertyRow(_, _, _, prop) -> {
      let marker = case is_cursor {
        True -> style.cyan("    ▸ ")
        False -> "      "
      }
      let type_str =
        style.dim(model.type_to_string(prop.type_))
        |> pad_right(16)
      let req_str = case prop.required {
        option.Some(True) -> style.yellow("*필수")
        _ -> ""
      }
      let default_str = case prop.default_value {
        option.Some(v) -> " = " <> style.dim(v)
        option.None -> ""
      }
      let key_str = case is_cursor {
        True -> style.bold(style.cyan(prop.key))
        False -> style.bold(prop.key)
      }
      marker <> key_str |> pad_right(20) <> type_str <> req_str <> default_str
    }
    SystemRow(_, _, _, key) -> {
      let marker = case is_cursor {
        True -> style.cyan("    ▸ ")
        False -> "      "
      }
      let icon = style.dim("◇ ")
      let name = case is_cursor {
        True -> style.cyan(key)
        False -> key
      }
      marker <> icon <> name <> "  " <> style.dim("(system)")
    }
  }
}

/// Renders the text cursor.
fn render_text_cursor(buffer: String, cursor_pos: Int) -> String {
  let before = string.slice(buffer, 0, cursor_pos)
  let at_cursor = string.slice(buffer, cursor_pos, 1)
  let after = string.drop_start(buffer, cursor_pos + 1)
  case at_cursor {
    "" -> style.cyan(before) <> style.dim("█")
    ch ->
      style.cyan(before) <> style.inverse(style.cyan(ch)) <> style.cyan(after)
  }
}

fn pad_right(s: String, width: Int) -> String {
  let len = string.length(s)
  case len >= width {
    True -> s
    False -> s <> string.repeat(" ", width - len)
  }
}

fn find_text_field(
  fields: List(EditField),
  label: String,
  default: String,
) -> String {
  case fields {
    [] -> default
    [TextField(l, v), ..] if l == label -> v
    [_, ..rest] -> find_text_field(rest, label, default)
  }
}

/// Finds the optional text.
fn find_optional_text(
  fields: List(EditField),
  label: String,
) -> option.Option(String) {
  case find_text_field_opt(fields, label) {
    option.Some("") -> option.None
    other -> other
  }
}

fn find_text_field_opt(
  fields: List(EditField),
  label: String,
) -> option.Option(String) {
  case fields {
    [] -> option.None
    [TextField(l, v), ..] if l == label -> option.Some(v)
    [_, ..rest] -> find_text_field_opt(rest, label)
  }
}

fn find_bool_field(
  fields: List(EditField),
  label: String,
) -> option.Option(Bool) {
  case fields {
    [] -> option.None
    [BoolField(l, v), ..] if l == label -> option.Some(v)
    [_, ..rest] -> find_bool_field(rest, label)
  }
}
