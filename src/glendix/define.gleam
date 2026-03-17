// Mendix Widget Property TUI 에디터 — 메인 모듈

import etch/command
import etch/stdout
import etch/style
import etch/terminal
import glendix/define/types.{
  type EnumValue, type Property, type PropertyGroup, type PropertyItem,
  type WidgetMeta, EnumValue, PropItem, Property, PropertyGroup,
  SysPropItem, SystemProperty,
}
import glendix/define/ui.{
  type EditField, BoolField, ListField, ReadOnlyField, TextField,
}
import gleam/int
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

// ── 키 입력 ──

type KeyInput {
  KeyNone
  KeyUp
  KeyDown
  KeyRight
  KeyLeft
  KeyEnter
  KeyEscape
  KeyBackspace
  KeyCtrlC
  KeyChar(String)
  KeyHome
  KeyEnd
  KeyPageUp
  KeyPageDown
  KeyTab
}

fn parse_key(raw: #(Int, String)) -> KeyInput {
  case raw.0 {
    1 -> KeyUp
    2 -> KeyDown
    3 -> KeyRight
    4 -> KeyLeft
    5 -> KeyEnter
    6 -> KeyEscape
    7 -> KeyBackspace
    8 -> KeyCtrlC
    9 -> KeyChar(raw.1)
    10 -> KeyHome
    11 -> KeyEnd
    12 -> KeyPageUp
    13 -> KeyPageDown
    14 -> KeyTab
    _ -> KeyNone
  }
}

// ── 텍스트 입력 대상 ──

type InputTarget {
  GroupNameInput
  PropertyKeyInput
  EditFieldInput(field_index: Int)
  EnumKeyInput(enum_index: Int)
  EnumCaptionInput(enum_index: Int)
  NewEnumKeyInput
  NewEnumCaptionInput(key: String)
}

// ── 뷰 모드 ──

type ViewMode {
  TreeView
  SelectType(cursor: Int)
  InputText(target: InputTarget, buffer: String, buf_cursor: Int)
  EditProperty(
    original: Property,
    fields: List(EditField),
    cursor: Int,
    editing: Bool,
    edit_buffer: String,
    edit_buf_cursor: Int,
  )
  EditEnum(
    values: List(EnumValue),
    cursor: Int,
  )
  EditMeta(
    original: WidgetMeta,
    fields: List(EditField),
    cursor: Int,
    editing: Bool,
    edit_buffer: String,
    edit_buf_cursor: Int,
  )
  SelectSystemProp(cursor: Int, options: List(String))
  ConfirmDelete(target_label: String, group_idx: Int, item_idx: Option(Int))
  ConfirmQuit
}

// ── 문자열 커서 조작 ──

/// 커서 위치에 문자를 삽입한다.
fn buf_insert(buffer: String, pos: Int, ch: String) -> String {
  string.slice(buffer, 0, pos) <> ch <> string.drop_start(buffer, pos)
}

/// 커서 앞의 문자를 삭제한다.
fn buf_delete(buffer: String, pos: Int) -> String {
  case pos > 0 {
    True ->
      string.slice(buffer, 0, pos - 1) <> string.drop_start(buffer, pos)
    False -> buffer
  }
}

// ── 상태 ──

type DefineState {
  DefineState(
    xml_path: String,
    widget_meta: WidgetMeta,
    groups: List(PropertyGroup),
    cursor: Int,
    collapsed: List(Int),
    view_mode: ViewMode,
    dirty: Bool,
    status_msg: Option(String),
    scroll_offset: Int,
    add_target_group: Int,
    selected_type_idx: Int,
    edit_group_idx: Int,
    edit_item_idx: Int,
  )
}

// ── FFI 선언 ──

@external(javascript, "./define_ffi.mjs", "find_widget_xml")
fn find_widget_xml() -> Option(String)

@external(javascript, "./define_ffi.mjs", "read_file")
fn read_file(path: String) -> Option(String)

@external(javascript, "./define_ffi.mjs", "write_file")
fn write_file(path: String, content: String) -> Bool

@external(javascript, "./define_ffi.mjs", "is_tty")
fn is_tty() -> Bool

@external(javascript, "./define_ffi.mjs", "exit_process")
fn exit_process() -> Nil

@external(javascript, "./define_ffi.mjs", "terminal_size")
fn terminal_size() -> #(Int, Int)

@external(javascript, "./define_ffi.mjs", "parse_widget_xml")
fn parse_widget_xml(xml: String) -> #(WidgetMeta, List(PropertyGroup))

@external(javascript, "./define_ffi.mjs", "serialize_widget_xml")
fn serialize_widget_xml(
  meta: WidgetMeta,
  groups: List(PropertyGroup),
) -> String

@external(javascript, "./define_ffi.mjs", "poll_key_raw")
fn poll_key_raw(timeout_ms: Int) -> Promise(#(Int, String))

// ── TUI 제어 ──

fn enter_tui() -> Nil {
  let _ = terminal.enter_raw()
  stdout.execute([command.EnterAlternateScreen, command.HideCursor])
}

fn exit_tui() -> Nil {
  stdout.execute([command.ShowCursor, command.LeaveAlternateScreen])
  let _ = terminal.exit_raw()
  Nil
}

fn render(state: DefineState) -> Nil {
  let #(_, term_rows) = terminal_size()
  let screen = case state.view_mode {
    TreeView ->
      ui.render_tree_screen(
        state.widget_meta.name,
        state.groups,
        state.cursor,
        state.collapsed,
        state.dirty,
        state.status_msg,
        state.scroll_offset,
        term_rows,
      )
    SelectType(cursor) -> ui.render_type_select_screen(cursor)
    InputText(target, buffer, buf_cursor) -> {
      let title = case target {
        GroupNameInput -> "그룹명 입력"
        PropertyKeyInput -> "속성 Key 입력"
        EditFieldInput(_) -> "값 입력"
        EnumKeyInput(_) -> "열거형 Key 입력"
        EnumCaptionInput(_) -> "열거형 Caption 입력"
        NewEnumKeyInput -> "새 열거형 Key"
        NewEnumCaptionInput(_) -> "새 열거형 Caption"
      }
      ui.render_input_screen(title, buffer, buf_cursor)
    }
    EditProperty(_, fields, cursor, editing, edit_buffer, edit_buf_cursor) -> {
      let prop_key = case fields {
        [ReadOnlyField(_, k), ..] -> k
        _ -> "?"
      }
      let prop_type = case fields {
        [_, ReadOnlyField(_, t), ..] -> t
        _ -> "?"
      }
      ui.render_edit_screen(
        prop_key,
        prop_type,
        fields,
        cursor,
        editing,
        edit_buffer,
        edit_buf_cursor,
      )
    }
    EditMeta(original, fields, cursor, editing, edit_buffer, edit_buf_cursor) ->
      ui.render_edit_screen(
        original.name,
        "위젯 정보",
        fields,
        cursor,
        editing,
        edit_buffer,
        edit_buf_cursor,
      )
    EditEnum(values, cursor) ->
      ui.render_enum_edit_screen(values, cursor, state.status_msg)
    SelectSystemProp(cursor, options) ->
      ui.render_sys_prop_screen(options, cursor)
    ConfirmDelete(label, _, _) ->
      ui.render_confirm_delete_screen(label)
    ConfirmQuit -> ui.render_confirm_quit_screen()
  }
  stdout.execute([
    command.Clear(terminal.All),
    command.MoveTo(0, 0),
    command.Print(screen),
  ])
}

// ── 메인 ──

pub fn main() {
  case find_widget_xml() {
    None -> {
      io.println(
        "\n  "
        <> style.red(
          "위젯 XML 파일을 찾을 수 없습니다.\n"
          <> "  package.json에 widgetName이 정의되어 있고,\n"
          <> "  src/{widgetName}.xml 파일이 존재하는지 확인하세요.",
        ),
      )
      Nil
    }
    Some(xml_path) -> {
      case read_file(xml_path) {
        None -> {
          io.println(
            "\n  " <> style.red("파일을 읽을 수 없습니다: " <> xml_path),
          )
          Nil
        }
        Some(xml_content) -> {
          let #(meta, groups) = parse_widget_xml(xml_content)
          let state =
            DefineState(
              xml_path: xml_path,
              widget_meta: meta,
              groups: groups,
              cursor: 0,
              collapsed: [],
              view_mode: TreeView,
              dirty: False,
              status_msg: None,
              scroll_offset: 0,
              add_target_group: 0,
              selected_type_idx: 0,
              edit_group_idx: 0,
              edit_item_idx: 0,
            )
          case is_tty() {
            True -> {
              enter_tui()
              {
                use _final <- promise.await(tui_loop(state))
                exit_tui()
                exit_process()
                promise.resolve(Nil)
              }
              Nil
            }
            False -> {
              io.println(
                "\n  "
                <> style.yellow(
                  "TTY가 아닙니다. 대화형 모드가 필요합니다.",
                ),
              )
              Nil
            }
          }
        }
      }
    }
  }
}

// ── TUI 이벤트 루프 ──

fn tui_loop(state: DefineState) -> Promise(DefineState) {
  render(state)
  use raw <- promise.await(poll_key_raw(0))
  let key = parse_key(raw)
  case key {
    KeyNone -> tui_loop(state)
    _ ->
      case state.view_mode {
        TreeView -> handle_tree_key(state, key)
        SelectType(_) -> handle_type_select_key(state, key)
        InputText(_, _, _) -> handle_input_key(state, key)
        EditProperty(_, _, _, _, _, _) -> handle_edit_key(state, key)
        EditMeta(_, _, _, _, _, _) -> handle_meta_key(state, key)
        EditEnum(_, _) -> handle_enum_key(state, key)
        SelectSystemProp(_, _) -> handle_sys_prop_key(state, key)
        ConfirmDelete(_, _, _) -> handle_delete_confirm_key(state, key)
        ConfirmQuit -> handle_quit_confirm_key(state, key)
      }
  }
}

// ── 트리뷰 행 수 ──

fn total_rows(state: DefineState) -> Int {
  let rows =
    ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  list.length(rows)
}

// ── TreeView 키 처리 ──

fn handle_tree_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  let state = DefineState(..state, status_msg: None)
  case key {
    KeyCtrlC -> promise.resolve(state)
    KeyChar("q") -> {
      case state.dirty {
        True ->
          tui_loop(DefineState(..state, view_mode: ConfirmQuit))
        False -> promise.resolve(state)
      }
    }
    KeyEscape -> {
      case state.dirty {
        True ->
          tui_loop(DefineState(..state, view_mode: ConfirmQuit))
        False -> promise.resolve(state)
      }
    }
    KeyUp -> tui_loop(move_cursor(state, -1))
    KeyDown -> tui_loop(move_cursor(state, 1))
    KeyHome -> tui_loop(DefineState(..state, cursor: 0, scroll_offset: 0))
    KeyEnd -> {
      let max = int.max(0, total_rows(state) - 1)
      tui_loop(DefineState(..state, cursor: max))
    }
    KeyPageUp -> tui_loop(move_cursor(state, -10))
    KeyPageDown -> tui_loop(move_cursor(state, 10))
    KeyTab -> tui_loop(toggle_collapse(state))
    KeyEnter -> tui_loop(enter_edit(state))
    KeyChar("a") -> {
      // 현재 커서가 속한 그룹 찾기
      let gi = cursor_group_index(state)
      case list.length(state.groups) {
        0 ->
          tui_loop(
            DefineState(
              ..state,
              status_msg: Some(
                style.yellow("먼저 g로 그룹을 추가하세요."),
              ),
            ),
          )
        _ ->
          tui_loop(
            DefineState(
              ..state,
              add_target_group: gi,
              view_mode: SelectType(0),
            ),
          )
      }
    }
    KeyChar("g") ->
      tui_loop(
        DefineState(
          ..state,
          view_mode: InputText(GroupNameInput, "", 0),
        ),
      )
    KeyChar("p") -> {
      case list.length(state.groups) {
        0 ->
          tui_loop(
            DefineState(
              ..state,
              status_msg: Some(
                style.yellow("먼저 g로 그룹을 추가하세요."),
              ),
            ),
          )
        _ -> {
          let gi = cursor_group_index(state)
          tui_loop(
            DefineState(
              ..state,
              add_target_group: gi,
              view_mode: SelectSystemProp(
                0,
                types.all_system_keys(),
              ),
            ),
          )
        }
      }
    }
    KeyChar("d") -> tui_loop(start_delete(state))
    KeyChar("w") -> {
      let fields = ui.widget_meta_to_fields(state.widget_meta)
      tui_loop(
        DefineState(
          ..state,
          view_mode: EditMeta(state.widget_meta, fields, 0, False, "", 0),
        ),
      )
    }
    KeyChar("s") -> tui_loop(save_xml(state))
    _ -> tui_loop(state)
  }
}

// ── 커서 이동 ──

fn move_cursor(state: DefineState, delta: Int) -> DefineState {
  let max = total_rows(state)
  case max {
    0 -> state
    _ -> {
      let new_cursor = int.clamp(state.cursor + delta, 0, max - 1)
      let #(_, term_rows) = terminal_size()
      let visible = case term_rows > 6 {
        True -> term_rows - 6
        False -> 10
      }
      let scroll = adjust_scroll(new_cursor, state.scroll_offset, visible)
      DefineState(..state, cursor: new_cursor, scroll_offset: scroll)
    }
  }
}

fn adjust_scroll(cursor: Int, scroll: Int, visible: Int) -> Int {
  case cursor < scroll {
    True -> cursor
    False ->
      case cursor >= scroll + visible {
        True -> cursor - visible + 1
        False -> scroll
      }
  }
}

// ── 그룹 접기/펼치기 ──

fn toggle_collapse(state: DefineState) -> DefineState {
  let rows =
    ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, _, _, is_collapsed)) -> {
      let new_collapsed = case is_collapsed {
        True -> list.filter(state.collapsed, fn(i) { i != gi })
        False -> [gi, ..state.collapsed]
      }
      DefineState(..state, collapsed: new_collapsed)
    }
    _ -> state
  }
}

// ── 현재 커서가 속한 그룹 인덱스 ──

fn cursor_group_index(state: DefineState) -> Int {
  let rows =
    ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, _, _, _)) -> gi
    Ok(ui.PropertyRow(_, gi, _, _)) -> gi
    Ok(ui.SystemRow(_, gi, _, _)) -> gi
    Error(_) -> 0
  }
}

// ── 편집 진입 ──

fn enter_edit(state: DefineState) -> DefineState {
  let rows =
    ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, caption, _, _)) ->
      DefineState(
        ..state,
        edit_group_idx: gi,
        view_mode: InputText(GroupNameInput, caption, string.length(caption)),
      )
    Ok(ui.PropertyRow(_, gi, ii, prop)) -> {
      let fields = ui.property_to_fields(prop)
      DefineState(
        ..state,
        edit_group_idx: gi,
        edit_item_idx: ii,
        view_mode: EditProperty(prop, fields, 0, False, "", 0),
      )
    }
    Ok(ui.SystemRow(_, _, _, _)) ->
      DefineState(
        ..state,
        status_msg: Some(style.dim("시스템 속성은 편집할 수 없습니다.")),
      )
    Error(_) -> state
  }
}

// ── 타입 선택 키 처리 ──

fn handle_type_select_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    SelectType(cursor) ->
      case key {
        KeyCtrlC | KeyEscape ->
          tui_loop(DefineState(..state, view_mode: TreeView))
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(DefineState(..state, view_mode: SelectType(new_c)))
        }
        KeyDown -> {
          let max = list.length(types.all_types()) - 1
          let new_c = int.min(max, cursor + 1)
          tui_loop(DefineState(..state, view_mode: SelectType(new_c)))
        }
        KeyEnter -> {
          // 선택된 타입의 인덱스를 보존하고 key 입력으로 전환
          case list.drop(types.all_types(), cursor) |> list.first {
            Ok(_) ->
              tui_loop(
                DefineState(
                  ..state,
                  selected_type_idx: cursor,
                  view_mode: InputText(PropertyKeyInput, "", 0),
                ),
              )
            Error(_) ->
              tui_loop(DefineState(..state, view_mode: TreeView))
          }
        }
        _ -> tui_loop(state)
      }
    _ -> tui_loop(state)
  }
}

// ── 텍스트 입력 키 처리 ──

fn handle_input_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    InputText(target, buffer, bc) ->
      case key {
        KeyCtrlC | KeyEscape ->
          case target {
            NewEnumCaptionInput(_) | NewEnumKeyInput ->
              tui_loop(restore_enum_view(state))
            _ ->
              tui_loop(DefineState(..state, view_mode: TreeView))
          }
        KeyEnter ->
          case target {
            GroupNameInput -> tui_loop(apply_group_name(state, buffer))
            PropertyKeyInput ->
              tui_loop(apply_new_property_key(state, buffer))
            EditFieldInput(fi) ->
              tui_loop(apply_edit_field_text(state, fi, buffer))
            EnumKeyInput(ei) -> {
              let cap = get_enum_caption(state, ei)
              let cap_len = string.length(cap)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(
                    EnumCaptionInput(ei),
                    cap,
                    cap_len,
                  ),
                ),
              )
            }
            EnumCaptionInput(ei) ->
              tui_loop(apply_enum_edit(state, ei, buffer))
            NewEnumKeyInput ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(
                    NewEnumCaptionInput(buffer),
                    "",
                    0,
                  ),
                ),
              )
            NewEnumCaptionInput(enum_key) ->
              tui_loop(apply_new_enum(state, enum_key, buffer))
          }
        KeyLeft ->
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(target, buffer, int.max(0, bc - 1)),
            ),
          )
        KeyRight ->
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(
                target,
                buffer,
                int.min(string.length(buffer), bc + 1),
              ),
            ),
          )
        KeyHome ->
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(target, buffer, 0),
            ),
          )
        KeyEnd ->
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(
                target,
                buffer,
                string.length(buffer),
              ),
            ),
          )
        KeyBackspace -> {
          case bc > 0 {
            True -> {
              let new_buf = buf_delete(buffer, bc)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(target, new_buf, bc - 1),
                ),
              )
            }
            False -> tui_loop(state)
          }
        }
        KeyChar(c) -> {
          let new_buf = buf_insert(buffer, bc, c)
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(target, new_buf, bc + 1),
            ),
          )
        }
        _ -> tui_loop(state)
      }
    _ -> tui_loop(state)
  }
}

// ── 속성 편집 키 처리 ──

fn handle_edit_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    EditProperty(original, fields, cursor, editing, edit_buffer, ebc) ->
      case editing {
        True ->
          case key {
            KeyEscape ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, cursor, False, "", 0,
                  ),
                ),
              )
            KeyEnter -> {
              let new_fields =
                update_field_text(fields, cursor, edit_buffer)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, new_fields, cursor, False, "", 0,
                  ),
                ),
              )
            }
            KeyLeft ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, cursor, True,
                    edit_buffer, int.max(0, ebc - 1),
                  ),
                ),
              )
            KeyRight ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, cursor, True,
                    edit_buffer,
                    int.min(string.length(edit_buffer), ebc + 1),
                  ),
                ),
              )
            KeyHome ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, cursor, True, edit_buffer, 0,
                  ),
                ),
              )
            KeyEnd ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, cursor, True,
                    edit_buffer, string.length(edit_buffer),
                  ),
                ),
              )
            KeyBackspace ->
              case ebc > 0 {
                True -> {
                  let new_buf = buf_delete(edit_buffer, ebc)
                  tui_loop(
                    DefineState(
                      ..state,
                      view_mode: EditProperty(
                        original, fields, cursor, True,
                        new_buf, ebc - 1,
                      ),
                    ),
                  )
                }
                False -> tui_loop(state)
              }
            KeyChar(c) -> {
              let new_buf = buf_insert(edit_buffer, ebc, c)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, cursor, True,
                    new_buf, ebc + 1,
                  ),
                ),
              )
            }
            _ -> tui_loop(state)
          }
        False ->
          case key {
            KeyEscape | KeyCtrlC -> {
              // 편집 완료 — 필드에서 Property 재구성
              let updated = ui.fields_to_property(original, fields)
              let new_groups =
                update_property(
                  state.groups,
                  state.edit_group_idx,
                  state.edit_item_idx,
                  updated,
                )
              let changed = updated != original
              tui_loop(
                DefineState(
                  ..state,
                  groups: new_groups,
                  dirty: state.dirty || changed,
                  view_mode: TreeView,
                  status_msg: case changed {
                    True -> Some(style.green("속성 수정됨"))
                    False -> None
                  },
                ),
              )
            }
            KeyUp -> {
              let new_c = int.max(0, cursor - 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, new_c, False, "", 0,
                  ),
                ),
              )
            }
            KeyDown -> {
              let max = int.max(0, list.length(fields) - 1)
              let new_c = int.min(max, cursor + 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, fields, new_c, False, "", 0,
                  ),
                ),
              )
            }
            KeyEnter -> {
              // 현재 필드가 TextField → 편집 모드 진입 (커서를 끝에 배치)
              case list.drop(fields, cursor) |> list.first {
                Ok(TextField(_, v)) ->
                  tui_loop(
                    DefineState(
                      ..state,
                      view_mode: EditProperty(
                        original, fields, cursor, True,
                        v, string.length(v),
                      ),
                    ),
                  )
                Ok(ListField(label, _)) ->
                  case label {
                    "EnumValues:" ->
                      tui_loop(
                        DefineState(
                          ..state,
                          view_mode: EditEnum(
                            original.enumeration_values, 0,
                          ),
                        ),
                      )
                    _ -> tui_loop(state)
                  }
                _ -> tui_loop(state)
              }
            }
            KeyLeft | KeyRight -> {
              // Bool 필드 토글
              let new_fields = toggle_bool_field(fields, cursor)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original, new_fields, cursor, False, "", 0,
                  ),
                ),
              )
            }
            _ -> tui_loop(state)
          }
      }
    _ -> tui_loop(state)
  }
}

// ── 위젯 메타 편집 키 처리 ──

fn handle_meta_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    EditMeta(original, fields, cursor, editing, edit_buffer, ebc) ->
      case editing {
        True ->
          case key {
            KeyEscape ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, cursor, False, "", 0,
                  ),
                ),
              )
            KeyEnter -> {
              let new_fields =
                update_field_text(fields, cursor, edit_buffer)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, new_fields, cursor, False, "", 0,
                  ),
                ),
              )
            }
            KeyLeft ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, cursor, True,
                    edit_buffer, int.max(0, ebc - 1),
                  ),
                ),
              )
            KeyRight ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, cursor, True,
                    edit_buffer,
                    int.min(string.length(edit_buffer), ebc + 1),
                  ),
                ),
              )
            KeyHome ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, cursor, True, edit_buffer, 0,
                  ),
                ),
              )
            KeyEnd ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, cursor, True,
                    edit_buffer, string.length(edit_buffer),
                  ),
                ),
              )
            KeyBackspace ->
              case ebc > 0 {
                True -> {
                  let new_buf = buf_delete(edit_buffer, ebc)
                  tui_loop(
                    DefineState(
                      ..state,
                      view_mode: EditMeta(
                        original, fields, cursor, True,
                        new_buf, ebc - 1,
                      ),
                    ),
                  )
                }
                False -> tui_loop(state)
              }
            KeyChar(c) -> {
              let new_buf = buf_insert(edit_buffer, ebc, c)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, cursor, True,
                    new_buf, ebc + 1,
                  ),
                ),
              )
            }
            _ -> tui_loop(state)
          }
        False ->
          case key {
            KeyEscape | KeyCtrlC -> {
              // 편집 완료 — 필드에서 WidgetMeta 재구성
              let updated = ui.fields_to_widget_meta(original, fields)
              let changed = updated != original
              tui_loop(
                DefineState(
                  ..state,
                  widget_meta: updated,
                  dirty: state.dirty || changed,
                  view_mode: TreeView,
                  status_msg: case changed {
                    True -> Some(style.green("위젯 정보 수정됨"))
                    False -> None
                  },
                ),
              )
            }
            KeyUp -> {
              let new_c = int.max(0, cursor - 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, new_c, False, "", 0,
                  ),
                ),
              )
            }
            KeyDown -> {
              let max = int.max(0, list.length(fields) - 1)
              let new_c = int.min(max, cursor + 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, fields, new_c, False, "", 0,
                  ),
                ),
              )
            }
            KeyEnter -> {
              // 현재 필드가 TextField → 편집 모드 진입
              case list.drop(fields, cursor) |> list.first {
                Ok(TextField(_, v)) ->
                  tui_loop(
                    DefineState(
                      ..state,
                      view_mode: EditMeta(
                        original, fields, cursor, True,
                        v, string.length(v),
                      ),
                    ),
                  )
                _ -> tui_loop(state)
              }
            }
            KeyLeft | KeyRight -> {
              // Bool 필드 토글
              let new_fields = toggle_bool_field(fields, cursor)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original, new_fields, cursor, False, "", 0,
                  ),
                ),
              )
            }
            _ -> tui_loop(state)
          }
      }
    _ -> tui_loop(state)
  }
}

// ── 열거형 편집 키 처리 ──

fn handle_enum_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    EditEnum(values, cursor) ->
      case key {
        KeyEscape | KeyCtrlC -> {
          // 편집 완료 — EditProperty로 복귀
          tui_loop(return_from_enum(state, values))
        }
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(
            DefineState(..state, view_mode: EditEnum(values, new_c)),
          )
        }
        KeyDown -> {
          let max = int.max(0, list.length(values) - 1)
          let new_c = int.min(max, cursor + 1)
          tui_loop(
            DefineState(..state, view_mode: EditEnum(values, new_c)),
          )
        }
        KeyEnter -> {
          // 현재 값 편집
          case list.drop(values, cursor) |> list.first {
            Ok(ev) ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(EnumKeyInput(cursor), ev.key, string.length(ev.key)),
                ),
              )
            Error(_) -> tui_loop(state)
          }
        }
        KeyChar("a") ->
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(NewEnumKeyInput, "", 0),
            ),
          )
        KeyChar("d") -> {
          let new_values =
            list.index_map(values, fn(v, i) { #(i, v) })
            |> list.filter(fn(pair) { pair.0 != cursor })
            |> list.map(fn(pair) { pair.1 })
          let new_c = int.min(cursor, int.max(0, list.length(new_values) - 1))
          tui_loop(
            DefineState(
              ..state,
              view_mode: EditEnum(new_values, new_c),
              status_msg: Some(style.green("열거형 값 삭제됨")),
            ),
          )
        }
        _ -> tui_loop(state)
      }
    _ -> tui_loop(state)
  }
}

// ── 시스템 속성 선택 키 처리 ──

fn handle_sys_prop_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    SelectSystemProp(cursor, options) ->
      case key {
        KeyCtrlC | KeyEscape ->
          tui_loop(DefineState(..state, view_mode: TreeView))
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(
            DefineState(
              ..state,
              view_mode: SelectSystemProp(new_c, options),
            ),
          )
        }
        KeyDown -> {
          let max = int.max(0, list.length(options) - 1)
          let new_c = int.min(max, cursor + 1)
          tui_loop(
            DefineState(
              ..state,
              view_mode: SelectSystemProp(new_c, options),
            ),
          )
        }
        KeyEnter -> {
          case list.drop(options, cursor) |> list.first {
            Ok(sys_key) -> {
              let item =
                SysPropItem(SystemProperty(sys_key))
              let new_groups =
                add_item_to_group(
                  state.groups,
                  state.add_target_group,
                  item,
                )
              tui_loop(
                DefineState(
                  ..state,
                  groups: new_groups,
                  dirty: True,
                  view_mode: TreeView,
                  status_msg: Some(
                    style.green(
                      "시스템 속성 추가됨: " <> sys_key,
                    ),
                  ),
                ),
              )
            }
            Error(_) ->
              tui_loop(DefineState(..state, view_mode: TreeView))
          }
        }
        _ -> tui_loop(state)
      }
    _ -> tui_loop(state)
  }
}

// ── 삭제 확인 키 처리 ──

fn handle_delete_confirm_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case state.view_mode {
    ConfirmDelete(_, group_idx, item_idx) ->
      case key {
        KeyChar("y") -> {
          let new_groups = case item_idx {
            None -> delete_group(state.groups, group_idx)
            Some(ii) ->
              delete_item_from_group(state.groups, group_idx, ii)
          }
          let new_cursor = int.max(0, state.cursor - 1)
          tui_loop(
            DefineState(
              ..state,
              groups: new_groups,
              cursor: new_cursor,
              dirty: True,
              view_mode: TreeView,
              status_msg: Some(style.green("삭제됨")),
            ),
          )
        }
        KeyChar("n") | KeyEscape | KeyCtrlC ->
          tui_loop(DefineState(..state, view_mode: TreeView))
        _ -> tui_loop(state)
      }
    _ -> tui_loop(state)
  }
}

// ── 종료 확인 키 처리 ──

fn handle_quit_confirm_key(
  state: DefineState,
  key: KeyInput,
) -> Promise(DefineState) {
  case key {
    KeyChar("y") -> promise.resolve(state)
    KeyChar("s") -> {
      let saved = save_xml(state)
      promise.resolve(saved)
    }
    KeyChar("n") | KeyEscape | KeyCtrlC ->
      tui_loop(DefineState(..state, view_mode: TreeView))
    _ -> tui_loop(state)
  }
}

// ── 삭제 시작 ──

fn start_delete(state: DefineState) -> DefineState {
  let rows =
    ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, caption, _, _)) ->
      DefineState(
        ..state,
        view_mode: ConfirmDelete(
          "그룹 [" <> caption <> "]",
          gi,
          None,
        ),
      )
    Ok(ui.PropertyRow(_, gi, ii, prop)) ->
      DefineState(
        ..state,
        view_mode: ConfirmDelete(
          "속성 " <> prop.key,
          gi,
          Some(ii),
        ),
      )
    Ok(ui.SystemRow(_, gi, ii, key)) ->
      DefineState(
        ..state,
        view_mode: ConfirmDelete(
          "시스템 속성 " <> key,
          gi,
          Some(ii),
        ),
      )
    Error(_) -> state
  }
}

// ── 그룹/속성 추가 ──

fn apply_group_name(state: DefineState, name: String) -> DefineState {
  case string.trim(name) {
    "" -> DefineState(..state, view_mode: TreeView)
    trimmed -> {
      // 기존 그룹 이름 편집인지 확인
      let rows =
        ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
      let is_rename =
        case list.drop(rows, state.cursor) |> list.first {
          Ok(ui.GroupRow(_, _, _, _, _)) -> True
          _ -> False
        }
      case is_rename {
        True -> {
          let gi = cursor_group_index(state)
          let new_groups =
            rename_group(state.groups, gi, trimmed)
          DefineState(
            ..state,
            groups: new_groups,
            dirty: True,
            view_mode: TreeView,
            status_msg: Some(style.green("그룹명 변경됨")),
          )
        }
        False -> {
          let new_group = PropertyGroup(trimmed, [])
          let new_groups =
            list.append(state.groups, [new_group])
          DefineState(
            ..state,
            groups: new_groups,
            dirty: True,
            view_mode: TreeView,
            status_msg: Some(
              style.green("그룹 추가됨: " <> trimmed),
            ),
          )
        }
      }
    }
  }
}

fn apply_new_property_key(state: DefineState, key: String) -> DefineState {
  case string.trim(key) {
    "" -> DefineState(..state, view_mode: TreeView)
    trimmed -> {
      let selected_type =
        case
          list.drop(types.all_types(), state.selected_type_idx)
          |> list.first
        {
          Ok(t) -> t
          Error(_) -> types.TypeString
        }
      let prop = types.default_property(trimmed, selected_type)
      let item = PropItem(prop)
      let new_groups =
        add_item_to_group(
          state.groups,
          state.add_target_group,
          item,
        )
      DefineState(
        ..state,
        groups: new_groups,
        dirty: True,
        view_mode: TreeView,
        status_msg: Some(
          style.green("속성 추가됨: " <> trimmed),
        ),
      )
    }
  }
}

// ── 필드 수정 ──

fn update_field_text(
  fields: List(EditField),
  index: Int,
  value: String,
) -> List(EditField) {
  list.index_map(fields, fn(field, i) {
    case i == index {
      True ->
        case field {
          TextField(label, _) -> TextField(label, value)
          _ -> field
        }
      False -> field
    }
  })
}

fn toggle_bool_field(
  fields: List(EditField),
  index: Int,
) -> List(EditField) {
  list.index_map(fields, fn(field, i) {
    case i == index {
      True ->
        case field {
          BoolField(label, v) -> BoolField(label, !v)
          _ -> field
        }
      False -> field
    }
  })
}

fn apply_edit_field_text(
  state: DefineState,
  field_index: Int,
  value: String,
) -> DefineState {
  // EditProperty 모드의 필드 갱신
  case state.view_mode {
    EditProperty(original, fields, _, _, _, _) -> {
      let new_fields = update_field_text(fields, field_index, value)
      DefineState(
        ..state,
        view_mode: EditProperty(original, new_fields, field_index, False, "", 0),
      )
    }
    _ -> DefineState(..state, view_mode: TreeView)
  }
}

// ── 열거형 관련 ──

fn get_enum_caption(state: DefineState, index: Int) -> String {
  case state.view_mode {
    EditEnum(values, _) ->
      case list.drop(values, index) |> list.first {
        Ok(ev) -> ev.caption
        Error(_) -> ""
      }
    _ -> ""
  }
}

fn apply_enum_edit(
  state: DefineState,
  index: Int,
  caption: String,
) -> DefineState {
  case state.view_mode {
    InputText(EnumCaptionInput(_), _, _) -> {
      // EnumKeyInput에서 입력받은 key를 가져와야 함
      // 현재 흐름: EnumKeyInput → Enter → EnumCaptionInput으로 전환
      // EnumKeyInput에서 buffer가 key였으므로, 여기서는 직접 접근 불가
      // 우회: state에서 enum values 찾기
      let values = get_current_enum_values(state)
      let new_key = case list.drop(values, index) |> list.first {
        Ok(ev) -> ev.key
        Error(_) -> ""
      }
      let new_values =
        list.index_map(values, fn(v, i) {
          case i == index {
            True -> EnumValue(new_key, caption)
            False -> v
          }
        })
      DefineState(
        ..state,
        view_mode: EditEnum(new_values, index),
      )
    }
    _ -> DefineState(..state, view_mode: TreeView)
  }
}

fn apply_new_enum(
  state: DefineState,
  key: String,
  caption: String,
) -> DefineState {
  let values = get_current_enum_values(state)
  let new_values =
    list.append(values, [EnumValue(key, caption)])
  DefineState(
    ..state,
    view_mode: EditEnum(new_values, list.length(new_values) - 1),
    status_msg: Some(style.green("열거형 값 추가됨")),
  )
}

fn get_current_enum_values(state: DefineState) -> List(EnumValue) {
  // 이전 ViewMode를 추적할 수 없으므로, groups에서 현재 편집 중인 속성의 values 반환
  let gi = state.edit_group_idx
  let ii = state.edit_item_idx
  case list.drop(state.groups, gi) |> list.first {
    Ok(group) ->
      case list.drop(group.items, ii) |> list.first {
        Ok(PropItem(prop)) -> prop.enumeration_values
        _ -> []
      }
    Error(_) -> []
  }
}

fn restore_enum_view(state: DefineState) -> DefineState {
  let values = get_current_enum_values(state)
  DefineState(..state, view_mode: EditEnum(values, 0))
}

fn return_from_enum(
  state: DefineState,
  values: List(EnumValue),
) -> DefineState {
  // groups에서 속성 업데이트
  let gi = state.edit_group_idx
  let ii = state.edit_item_idx
  let new_groups =
    update_property_enum_values(state.groups, gi, ii, values)
  let prop = get_property(new_groups, gi, ii)
  case prop {
    Some(p) -> {
      let fields = ui.property_to_fields(p)
      DefineState(
        ..state,
        groups: new_groups,
        dirty: True,
        view_mode: EditProperty(p, fields, 0, False, "", 0),
      )
    }
    None ->
      DefineState(
        ..state,
        groups: new_groups,
        dirty: True,
        view_mode: TreeView,
      )
  }
}

// ── 그룹/속성 데이터 조작 ──

fn add_item_to_group(
  groups: List(PropertyGroup),
  group_index: Int,
  item: PropertyItem,
) -> List(PropertyGroup) {
  list.index_map(groups, fn(group, i) {
    case i == group_index {
      True ->
        PropertyGroup(
          ..group,
          items: list.append(group.items, [item]),
        )
      False -> group
    }
  })
}

fn delete_group(
  groups: List(PropertyGroup),
  group_index: Int,
) -> List(PropertyGroup) {
  list.index_map(groups, fn(g, i) { #(i, g) })
  |> list.filter(fn(pair) { pair.0 != group_index })
  |> list.map(fn(pair) { pair.1 })
}

fn delete_item_from_group(
  groups: List(PropertyGroup),
  group_index: Int,
  item_index: Int,
) -> List(PropertyGroup) {
  list.index_map(groups, fn(group, gi) {
    case gi == group_index {
      True -> {
        let new_items =
          list.index_map(group.items, fn(item, ii) { #(ii, item) })
          |> list.filter(fn(pair) { pair.0 != item_index })
          |> list.map(fn(pair) { pair.1 })
        PropertyGroup(..group, items: new_items)
      }
      False -> group
    }
  })
}

fn rename_group(
  groups: List(PropertyGroup),
  group_index: Int,
  name: String,
) -> List(PropertyGroup) {
  list.index_map(groups, fn(group, i) {
    case i == group_index {
      True -> PropertyGroup(..group, caption: name)
      False -> group
    }
  })
}

fn update_property(
  groups: List(PropertyGroup),
  group_index: Int,
  item_index: Int,
  prop: Property,
) -> List(PropertyGroup) {
  list.index_map(groups, fn(group, gi) {
    case gi == group_index {
      True -> {
        let new_items =
          list.index_map(group.items, fn(item, ii) {
            case ii == item_index {
              True -> PropItem(prop)
              False -> item
            }
          })
        PropertyGroup(..group, items: new_items)
      }
      False -> group
    }
  })
}

fn update_property_enum_values(
  groups: List(PropertyGroup),
  group_index: Int,
  item_index: Int,
  values: List(EnumValue),
) -> List(PropertyGroup) {
  list.index_map(groups, fn(group, gi) {
    case gi == group_index {
      True -> {
        let new_items =
          list.index_map(group.items, fn(item, ii) {
            case ii == item_index {
              True ->
                case item {
                  PropItem(prop) ->
                    PropItem(
                      Property(..prop, enumeration_values: values),
                    )
                  other -> other
                }
              False -> item
            }
          })
        PropertyGroup(..group, items: new_items)
      }
      False -> group
    }
  })
}

fn get_property(
  groups: List(PropertyGroup),
  group_index: Int,
  item_index: Int,
) -> Option(Property) {
  case list.drop(groups, group_index) |> list.first {
    Ok(group) ->
      case list.drop(group.items, item_index) |> list.first {
        Ok(PropItem(prop)) -> Some(prop)
        _ -> None
      }
    Error(_) -> None
  }
}

// ── XML 저장 ──

fn save_xml(state: DefineState) -> DefineState {
  let xml =
    serialize_widget_xml(state.widget_meta, state.groups)
  case write_file(state.xml_path, xml) {
    True ->
      DefineState(
        ..state,
        dirty: False,
        status_msg: Some(
          style.green("저장됨: " <> state.xml_path),
        ),
      )
    False ->
      DefineState(
        ..state,
        status_msg: Some(style.red("저장 실패!")),
      )
  }
}
