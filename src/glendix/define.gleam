//// Runs the interactive Mendix widget definition editor.
////

import etch/command
import etch/stdout
import etch/style
import etch/terminal
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glendix/define/document
import glendix/define/file_boundary
import glendix/define/model
import glendix/define/ui

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  case file_boundary.find_widget_xml() {
    Error(error) -> {
      io.println("\n  " <> style.red(file_error_message(error)))
      Nil
    }
    Ok(xml_path) -> {
      case file_boundary.read(xml_path) {
        Error(error) -> {
          io.println("\n  " <> style.red(file_error_message(error)))
          Nil
        }
        Ok(xml_content) ->
          case document.parse(xml_content) {
            Error(error) -> {
              io.println("\n  " <> style.red(document.error_message(error)))
              Nil
            }
            Ok(#(meta, groups)) -> {
              let state =
                DefineState(
                  xml_path: xml_path,
                  widget_meta: meta,
                  groups: groups,
                  cursor: 0,
                  collapsed: [],
                  view_mode: TreeView,
                  dirty: False,
                  status_msg: option.None,
                  scroll_offset: 0,
                  add_target_group: 0,
                  selected_type_idx: 0,
                  edit_group_idx: 0,
                  edit_item_idx: 0,
                )
              case is_tty() {
                True -> {
                  case enter_tui() {
                    Error(error) -> {
                      io.println(
                        "\n  "
                        <> style.red(
                          "Unable to enable terminal raw mode: "
                          <> string.inspect(error),
                        ),
                      )
                      Nil
                    }
                    Ok(Nil) -> {
                      {
                        use _final <- promise.await(tui_loop(state))
                        case exit_tui() {
                          Ok(Nil) -> Nil
                          Error(error) ->
                            io.println(
                              "\n  "
                              <> style.red(
                                "Unable to restore terminal mode: "
                                <> string.inspect(error),
                              ),
                            )
                        }
                        exit_process()
                        promise.resolve(Nil)
                      }
                      Nil
                    }
                  }
                }
                False -> {
                  io.println(
                    "\n  " <> style.yellow("TTY가 아닙니다. 대화형 모드가 필요합니다."),
                  )
                  Nil
                }
              }
            }
          }
      }
    }
  }
}

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

type InputTarget {
  GroupNameInput
  PropertyKeyInput
  EditFieldInput(field_index: Int)
  EnumKeyInput(enum_index: Int)
  EnumCaptionInput(enum_index: Int, new_key: String)
  NewEnumKeyInput
  NewEnumCaptionInput(key: String)
}

type ViewMode {
  TreeView
  SelectType(cursor: Int)
  InputText(target: InputTarget, buffer: String, buf_cursor: Int)
  EditProperty(
    original: model.Property,
    fields: List(ui.EditField),
    cursor: Int,
    editing: Bool,
    edit_buffer: String,
    edit_buf_cursor: Int,
  )
  EditEnum(values: List(model.EnumValue), cursor: Int)
  EditMeta(
    original: model.WidgetMeta,
    fields: List(ui.EditField),
    cursor: Int,
    editing: Bool,
    edit_buffer: String,
    edit_buf_cursor: Int,
  )
  SelectSystemProp(cursor: Int, options: List(String))
  SelectTypeForEdit(cursor: Int)
  EditMultiSelect(
    field_label: String,
    options: List(String),
    selected: List(String),
    cursor: Int,
  )
  ConfirmDelete(
    target_label: String,
    group_idx: Int,
    item_idx: option.Option(Int),
  )
  ConfirmQuit
}

type DefineState {
  DefineState(
    xml_path: String,
    widget_meta: model.WidgetMeta,
    groups: List(model.PropertyGroup),
    cursor: Int,
    collapsed: List(Int),
    view_mode: ViewMode,
    dirty: Bool,
    status_msg: option.Option(String),
    scroll_offset: Int,
    add_target_group: Int,
    selected_type_idx: Int,
    edit_group_idx: Int,
    edit_item_idx: Int,
  )
}

type TerminalControlError {
  RawModeCouldNotBeEnabled(reason: String)
  RawModeCouldNotBeDisabled(reason: String)
}

type RawTerminalModeError

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

fn buf_insert(buffer: String, pos: Int, ch: String) -> String {
  string.slice(buffer, 0, pos) <> ch <> string.drop_start(buffer, pos)
}

fn buf_delete(buffer: String, pos: Int) -> String {
  case pos > 0 {
    True -> string.slice(buffer, 0, pos - 1) <> string.drop_start(buffer, pos)
    False -> buffer
  }
}

fn enter_tui() -> Result(Nil, TerminalControlError) {
  use _ <- result.try(
    set_terminal_raw_mode(True)
    |> result.map_error(fn(error) {
      RawModeCouldNotBeEnabled(raw_terminal_mode_error_message(error))
    }),
  )
  stdout.execute([command.EnterAlternateScreen, command.HideCursor])
  Ok(Nil)
}

fn exit_tui() -> Result(Nil, TerminalControlError) {
  stdout.execute([command.ShowCursor, command.LeaveAlternateScreen])
  set_terminal_raw_mode(False)
  |> result.map_error(fn(error) {
    RawModeCouldNotBeDisabled(raw_terminal_mode_error_message(error))
  })
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
        case state.dirty {
          True -> ui.Modified
          False -> ui.Saved
        },
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
        EnumCaptionInput(_, _) -> "열거형 Caption 입력"
        NewEnumKeyInput -> "새 열거형 Key"
        NewEnumCaptionInput(_) -> "새 열거형 Caption"
      }
      ui.render_input_screen(title, buffer, buf_cursor)
    }
    EditProperty(_, fields, cursor, editing, edit_buffer, edit_buf_cursor) -> {
      let prop_key = case fields {
        [ui.TextField(_, k), ..] -> k
        []
        | [ui.BoolField(..), ..]
        | [ui.ReadOnlyField(..), ..]
        | [ui.ListField(..), ..]
        | [ui.SelectField(..), ..] -> "?"
      }
      let prop_type = case fields {
        [_, ui.SelectField(_, t), ..] -> t
        [] | [_] -> "?"
        [_, second, ..] ->
          case second {
            ui.SelectField(_, t) -> t
            ui.TextField(..)
            | ui.BoolField(..)
            | ui.ReadOnlyField(..)
            | ui.ListField(..) -> "?"
          }
      }
      ui.render_edit_screen(
        prop_key,
        prop_type,
        fields,
        cursor,
        case editing {
          True -> ui.Editing
          False -> ui.Viewing
        },
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
        case editing {
          True -> ui.Editing
          False -> ui.Viewing
        },
        edit_buffer,
        edit_buf_cursor,
      )
    EditEnum(values, cursor) ->
      ui.render_enum_edit_screen(values, cursor, state.status_msg)
    SelectSystemProp(cursor, options) ->
      ui.render_sys_prop_screen(options, cursor)
    SelectTypeForEdit(cursor) -> ui.render_type_select_screen(cursor)
    EditMultiSelect(label, options, selected, cursor) -> {
      let title = case label {
        "AttrTypes:" -> "속성 타입 선택"
        "AssocTypes:" -> "연관 타입 선택"
        "SelTypes:" -> "선택 타입 선택"
        _ -> "항목 선택"
      }
      ui.render_multi_select_screen(title, options, selected, cursor)
    }
    ConfirmDelete(label, _, _) -> ui.render_confirm_delete_screen(label)
    ConfirmQuit -> ui.render_confirm_quit_screen()
  }
  stdout.execute([
    command.Clear(terminal.All),
    command.MoveTo(0, 0),
    command.Print(screen),
  ])
}

fn tui_loop(state: DefineState) -> promise.Promise(DefineState) {
  render(state)
  use raw <- promise.await(poll_key_raw(0))
  let key = parse_key(raw)
  case key {
    KeyNone -> tui_loop(state)
    KeyUp
    | KeyDown
    | KeyRight
    | KeyLeft
    | KeyEnter
    | KeyEscape
    | KeyBackspace
    | KeyCtrlC
    | KeyChar(_)
    | KeyHome
    | KeyEnd
    | KeyPageUp
    | KeyPageDown
    | KeyTab ->
      case state.view_mode {
        TreeView -> handle_tree_key(state, key)
        SelectType(_) -> handle_type_select_key(state, key)
        InputText(_, _, _) -> handle_input_key(state, key)
        EditProperty(_, _, _, _, _, _) -> handle_edit_key(state, key)
        EditMeta(_, _, _, _, _, _) -> handle_meta_key(state, key)
        EditEnum(_, _) -> handle_enum_key(state, key)
        SelectSystemProp(_, _) -> handle_sys_prop_key(state, key)
        SelectTypeForEdit(_) -> handle_type_edit_key(state, key)
        EditMultiSelect(_, _, _, _) -> handle_multi_select_key(state, key)
        ConfirmDelete(_, _, _) -> handle_delete_confirm_key(state, key)
        ConfirmQuit -> handle_quit_confirm_key(state, key)
      }
  }
}

fn total_rows(state: DefineState) -> Int {
  let rows = ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  list.length(rows)
}

fn handle_tree_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  let state = DefineState(..state, status_msg: option.None)
  case key {
    KeyCtrlC -> promise.resolve(state)
    KeyChar("q") -> {
      case state.dirty {
        True -> tui_loop(DefineState(..state, view_mode: ConfirmQuit))
        False -> promise.resolve(state)
      }
    }
    KeyEscape -> {
      case state.dirty {
        True -> tui_loop(DefineState(..state, view_mode: ConfirmQuit))
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
      let gi = cursor_group_index(state)
      case list.length(state.groups) {
        0 ->
          tui_loop(
            DefineState(
              ..state,
              status_msg: option.Some(style.yellow("먼저 g로 그룹을 추가하세요.")),
            ),
          )
        _ ->
          tui_loop(
            DefineState(..state, add_target_group: gi, view_mode: SelectType(0)),
          )
      }
    }
    KeyChar("g") ->
      tui_loop(
        DefineState(..state, view_mode: InputText(GroupNameInput, "", 0)),
      )
    KeyChar("p") -> {
      case list.length(state.groups) {
        0 ->
          tui_loop(
            DefineState(
              ..state,
              status_msg: option.Some(style.yellow("먼저 g로 그룹을 추가하세요.")),
            ),
          )
        _ -> {
          let gi = cursor_group_index(state)
          tui_loop(
            DefineState(
              ..state,
              add_target_group: gi,
              view_mode: SelectSystemProp(0, model.all_system_keys()),
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
    KeyNone | KeyRight | KeyLeft | KeyBackspace | KeyChar(_) -> tui_loop(state)
  }
}

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

fn toggle_collapse(state: DefineState) -> DefineState {
  let rows = ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, _, _, is_collapsed)) -> {
      let new_collapsed = case is_collapsed {
        True -> list.filter(state.collapsed, fn(i) { i != gi })
        False -> [gi, ..state.collapsed]
      }
      DefineState(..state, collapsed: new_collapsed)
    }
    Ok(ui.PropertyRow(..)) | Ok(ui.SystemRow(..)) | Error(_) -> state
  }
}

fn cursor_group_index(state: DefineState) -> Int {
  let rows = ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, _, _, _)) -> gi
    Ok(ui.PropertyRow(_, gi, _, _)) -> gi
    Ok(ui.SystemRow(_, gi, _, _)) -> gi
    Error(_) -> 0
  }
}

fn enter_edit(state: DefineState) -> DefineState {
  let rows = ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
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
        status_msg: option.Some(style.dim("시스템 속성은 편집할 수 없습니다.")),
      )
    Error(_) -> state
  }
}

fn handle_type_select_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
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
          let max = list.length(model.all_types()) - 1
          let new_c = int.min(max, cursor + 1)
          tui_loop(DefineState(..state, view_mode: SelectType(new_c)))
        }
        KeyEnter -> {
          case list.drop(model.all_types(), cursor) |> list.first {
            Ok(_) ->
              tui_loop(
                DefineState(
                  ..state,
                  selected_type_idx: cursor,
                  view_mode: InputText(PropertyKeyInput, "", 0),
                ),
              )
            Error(_) -> tui_loop(DefineState(..state, view_mode: TreeView))
          }
        }
        KeyNone
        | KeyRight
        | KeyLeft
        | KeyBackspace
        | KeyChar(_)
        | KeyHome
        | KeyEnd
        | KeyPageUp
        | KeyPageDown
        | KeyTab -> tui_loop(state)
      }
    TreeView
    | InputText(..)
    | EditProperty(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_input_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    InputText(target, buffer, bc) ->
      case key {
        KeyCtrlC | KeyEscape ->
          case target {
            NewEnumCaptionInput(_)
            | NewEnumKeyInput
            | EnumCaptionInput(_, _)
            | EnumKeyInput(_) -> tui_loop(restore_enum_view(state))
            GroupNameInput | PropertyKeyInput | EditFieldInput(_) ->
              tui_loop(DefineState(..state, view_mode: TreeView))
          }
        KeyEnter ->
          case target {
            GroupNameInput -> tui_loop(apply_group_name(state, buffer))
            PropertyKeyInput -> tui_loop(apply_new_property_key(state, buffer))
            EditFieldInput(fi) ->
              tui_loop(apply_edit_field_text(state, fi, buffer))
            EnumKeyInput(ei) -> {
              let cap = get_enum_caption(state, ei)
              let cap_len = string.length(cap)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(
                    EnumCaptionInput(ei, buffer),
                    cap,
                    cap_len,
                  ),
                ),
              )
            }
            EnumCaptionInput(ei, new_key) ->
              tui_loop(apply_enum_edit(state, ei, new_key, buffer))
            NewEnumKeyInput ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(NewEnumCaptionInput(buffer), "", 0),
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
            DefineState(..state, view_mode: InputText(target, buffer, 0)),
          )
        KeyEnd ->
          tui_loop(
            DefineState(
              ..state,
              view_mode: InputText(target, buffer, string.length(buffer)),
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
            DefineState(..state, view_mode: InputText(target, new_buf, bc + 1)),
          )
        }
        KeyNone | KeyUp | KeyDown | KeyPageUp | KeyPageDown | KeyTab ->
          tui_loop(state)
      }
    TreeView
    | SelectType(..)
    | EditProperty(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_edit_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
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
                    original,
                    fields,
                    cursor,
                    False,
                    "",
                    0,
                  ),
                ),
              )
            KeyEnter -> {
              let new_fields = update_field_text(fields, cursor, edit_buffer)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original,
                    new_fields,
                    cursor,
                    False,
                    "",
                    0,
                  ),
                ),
              )
            }
            KeyLeft ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original,
                    fields,
                    cursor,
                    True,
                    edit_buffer,
                    int.max(0, ebc - 1),
                  ),
                ),
              )
            KeyRight ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original,
                    fields,
                    cursor,
                    True,
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
                    original,
                    fields,
                    cursor,
                    True,
                    edit_buffer,
                    0,
                  ),
                ),
              )
            KeyEnd ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original,
                    fields,
                    cursor,
                    True,
                    edit_buffer,
                    string.length(edit_buffer),
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
                        original,
                        fields,
                        cursor,
                        True,
                        new_buf,
                        ebc - 1,
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
                    original,
                    fields,
                    cursor,
                    True,
                    new_buf,
                    ebc + 1,
                  ),
                ),
              )
            }
            KeyNone
            | KeyUp
            | KeyDown
            | KeyCtrlC
            | KeyPageUp
            | KeyPageDown
            | KeyTab -> tui_loop(state)
          }
        False ->
          case key {
            KeyEscape | KeyCtrlC -> {
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
                    True -> option.Some(style.green("속성 수정됨"))
                    False -> option.None
                  },
                ),
              )
            }
            KeyUp -> {
              let new_c = int.max(0, cursor - 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(original, fields, new_c, False, "", 0),
                ),
              )
            }
            KeyDown -> {
              let max = int.max(0, list.length(fields) - 1)
              let new_c = int.min(max, cursor + 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(original, fields, new_c, False, "", 0),
                ),
              )
            }
            KeyEnter -> {
              case list.drop(fields, cursor) |> list.first {
                Ok(ui.TextField(_, v)) ->
                  tui_loop(
                    DefineState(
                      ..state,
                      view_mode: EditProperty(
                        original,
                        fields,
                        cursor,
                        True,
                        v,
                        string.length(v),
                      ),
                    ),
                  )
                Ok(ui.SelectField(label, _)) ->
                  case label {
                    "Type:" -> {
                      let current_prop = ui.fields_to_property(original, fields)
                      let new_groups =
                        update_property(
                          state.groups,
                          state.edit_group_idx,
                          state.edit_item_idx,
                          current_prop,
                        )
                      let type_cursor = model.type_index(current_prop.type_)
                      tui_loop(
                        DefineState(
                          ..state,
                          groups: new_groups,
                          dirty: state.dirty || current_prop != original,
                          view_mode: SelectTypeForEdit(type_cursor),
                        ),
                      )
                    }
                    _ -> tui_loop(state)
                  }
                Ok(ui.ListField(label, _)) -> {
                  let current_prop = ui.fields_to_property(original, fields)
                  let new_groups =
                    update_property(
                      state.groups,
                      state.edit_group_idx,
                      state.edit_item_idx,
                      current_prop,
                    )
                  let has_changes = current_prop != original
                  case label {
                    "EnumValues:" ->
                      tui_loop(
                        DefineState(
                          ..state,
                          groups: new_groups,
                          dirty: state.dirty || has_changes,
                          view_mode: EditEnum(
                            current_prop.enumeration_values,
                            0,
                          ),
                        ),
                      )
                    "AttrTypes:" ->
                      tui_loop(
                        DefineState(
                          ..state,
                          groups: new_groups,
                          dirty: state.dirty || has_changes,
                          view_mode: EditMultiSelect(
                            "AttrTypes:",
                            model.all_attribute_types(),
                            current_prop.attribute_types,
                            0,
                          ),
                        ),
                      )
                    "AssocTypes:" ->
                      tui_loop(
                        DefineState(
                          ..state,
                          groups: new_groups,
                          dirty: state.dirty || has_changes,
                          view_mode: EditMultiSelect(
                            "AssocTypes:",
                            model.all_association_types(),
                            current_prop.association_types,
                            0,
                          ),
                        ),
                      )
                    "SelTypes:" ->
                      tui_loop(
                        DefineState(
                          ..state,
                          groups: new_groups,
                          dirty: state.dirty || has_changes,
                          view_mode: EditMultiSelect(
                            "SelTypes:",
                            model.all_selection_types(),
                            current_prop.selection_types,
                            0,
                          ),
                        ),
                      )
                    _ -> tui_loop(state)
                  }
                }
                Ok(ui.BoolField(..)) | Ok(ui.ReadOnlyField(..)) | Error(_) ->
                  tui_loop(state)
              }
            }
            KeyLeft | KeyRight -> {
              let new_fields = toggle_bool_field(fields, cursor)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(
                    original,
                    new_fields,
                    cursor,
                    False,
                    "",
                    0,
                  ),
                ),
              )
            }
            KeyNone
            | KeyHome
            | KeyEnd
            | KeyPageUp
            | KeyPageDown
            | KeyTab
            | KeyBackspace
            | KeyChar(_) -> tui_loop(state)
          }
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_meta_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    EditMeta(original, fields, cursor, editing, edit_buffer, ebc) ->
      case editing {
        True ->
          case key {
            KeyEscape ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(original, fields, cursor, False, "", 0),
                ),
              )
            KeyEnter -> {
              let new_fields = update_field_text(fields, cursor, edit_buffer)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original,
                    new_fields,
                    cursor,
                    False,
                    "",
                    0,
                  ),
                ),
              )
            }
            KeyLeft ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original,
                    fields,
                    cursor,
                    True,
                    edit_buffer,
                    int.max(0, ebc - 1),
                  ),
                ),
              )
            KeyRight ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original,
                    fields,
                    cursor,
                    True,
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
                    original,
                    fields,
                    cursor,
                    True,
                    edit_buffer,
                    0,
                  ),
                ),
              )
            KeyEnd ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original,
                    fields,
                    cursor,
                    True,
                    edit_buffer,
                    string.length(edit_buffer),
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
                        original,
                        fields,
                        cursor,
                        True,
                        new_buf,
                        ebc - 1,
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
                    original,
                    fields,
                    cursor,
                    True,
                    new_buf,
                    ebc + 1,
                  ),
                ),
              )
            }
            KeyNone
            | KeyUp
            | KeyDown
            | KeyCtrlC
            | KeyPageUp
            | KeyPageDown
            | KeyTab -> tui_loop(state)
          }
        False ->
          case key {
            KeyEscape | KeyCtrlC -> {
              let updated = ui.fields_to_widget_meta(original, fields)
              let changed = updated != original
              tui_loop(
                DefineState(
                  ..state,
                  widget_meta: updated,
                  dirty: state.dirty || changed,
                  view_mode: TreeView,
                  status_msg: case changed {
                    True -> option.Some(style.green("위젯 정보 수정됨"))
                    False -> option.None
                  },
                ),
              )
            }
            KeyUp -> {
              let new_c = int.max(0, cursor - 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(original, fields, new_c, False, "", 0),
                ),
              )
            }
            KeyDown -> {
              let max = int.max(0, list.length(fields) - 1)
              let new_c = int.min(max, cursor + 1)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(original, fields, new_c, False, "", 0),
                ),
              )
            }
            KeyEnter -> {
              case list.drop(fields, cursor) |> list.first {
                Ok(ui.TextField(_, v)) ->
                  tui_loop(
                    DefineState(
                      ..state,
                      view_mode: EditMeta(
                        original,
                        fields,
                        cursor,
                        True,
                        v,
                        string.length(v),
                      ),
                    ),
                  )
                Ok(ui.BoolField(..))
                | Ok(ui.ReadOnlyField(..))
                | Ok(ui.ListField(..))
                | Ok(ui.SelectField(..))
                | Error(_) -> tui_loop(state)
              }
            }
            KeyLeft | KeyRight -> {
              let new_fields = toggle_bool_field(fields, cursor)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMeta(
                    original,
                    new_fields,
                    cursor,
                    False,
                    "",
                    0,
                  ),
                ),
              )
            }
            KeyNone
            | KeyHome
            | KeyEnd
            | KeyPageUp
            | KeyPageDown
            | KeyTab
            | KeyBackspace
            | KeyChar(_) -> tui_loop(state)
          }
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditEnum(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_enum_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    EditEnum(values, cursor) ->
      case key {
        KeyEscape | KeyCtrlC -> {
          tui_loop(return_from_enum(state, values))
        }
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(DefineState(..state, view_mode: EditEnum(values, new_c)))
        }
        KeyDown -> {
          let max = int.max(0, list.length(values) - 1)
          let new_c = int.min(max, cursor + 1)
          tui_loop(DefineState(..state, view_mode: EditEnum(values, new_c)))
        }
        KeyEnter -> {
          case list.drop(values, cursor) |> list.first {
            Ok(ev) ->
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: InputText(
                    EnumKeyInput(cursor),
                    ev.key,
                    string.length(ev.key),
                  ),
                ),
              )
            Error(_) -> tui_loop(state)
          }
        }
        KeyChar("a") ->
          tui_loop(
            DefineState(..state, view_mode: InputText(NewEnumKeyInput, "", 0)),
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
              status_msg: option.Some(style.green("열거형 값 삭제됨")),
            ),
          )
        }
        KeyNone
        | KeyRight
        | KeyLeft
        | KeyBackspace
        | KeyChar(_)
        | KeyHome
        | KeyEnd
        | KeyPageUp
        | KeyPageDown
        | KeyTab -> tui_loop(state)
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_sys_prop_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    SelectSystemProp(cursor, options) ->
      case key {
        KeyCtrlC | KeyEscape ->
          tui_loop(DefineState(..state, view_mode: TreeView))
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(
            DefineState(..state, view_mode: SelectSystemProp(new_c, options)),
          )
        }
        KeyDown -> {
          let max = int.max(0, list.length(options) - 1)
          let new_c = int.min(max, cursor + 1)
          tui_loop(
            DefineState(..state, view_mode: SelectSystemProp(new_c, options)),
          )
        }
        KeyEnter -> {
          case list.drop(options, cursor) |> list.first {
            Ok(sys_key) -> {
              let item = model.SysPropItem(model.SystemProperty(sys_key))
              let new_groups =
                add_item_to_group(state.groups, state.add_target_group, item)
              tui_loop(
                DefineState(
                  ..state,
                  groups: new_groups,
                  dirty: True,
                  view_mode: TreeView,
                  status_msg: option.Some(style.green("시스템 속성 추가됨: " <> sys_key)),
                ),
              )
            }
            Error(_) -> tui_loop(DefineState(..state, view_mode: TreeView))
          }
        }
        KeyNone
        | KeyRight
        | KeyLeft
        | KeyBackspace
        | KeyChar(_)
        | KeyHome
        | KeyEnd
        | KeyPageUp
        | KeyPageDown
        | KeyTab -> tui_loop(state)
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_delete_confirm_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    ConfirmDelete(_, group_idx, item_idx) ->
      case key {
        KeyChar("y") -> {
          let new_groups = case item_idx {
            option.None -> delete_group(state.groups, group_idx)
            option.Some(ii) ->
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
              status_msg: option.Some(style.green("삭제됨")),
            ),
          )
        }
        KeyChar("n") | KeyEscape | KeyCtrlC ->
          tui_loop(DefineState(..state, view_mode: TreeView))
        _ -> tui_loop(state)
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_quit_confirm_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
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

fn start_delete(state: DefineState) -> DefineState {
  let rows = ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
  case list.drop(rows, state.cursor) |> list.first {
    Ok(ui.GroupRow(_, gi, caption, _, _)) ->
      DefineState(
        ..state,
        view_mode: ConfirmDelete("그룹 [" <> caption <> "]", gi, option.None),
      )
    Ok(ui.PropertyRow(_, gi, ii, prop)) ->
      DefineState(
        ..state,
        view_mode: ConfirmDelete("속성 " <> prop.key, gi, option.Some(ii)),
      )
    Ok(ui.SystemRow(_, gi, ii, key)) ->
      DefineState(
        ..state,
        view_mode: ConfirmDelete("시스템 속성 " <> key, gi, option.Some(ii)),
      )
    Error(_) -> state
  }
}

fn apply_group_name(state: DefineState, name: String) -> DefineState {
  case string.trim(name) {
    "" -> DefineState(..state, view_mode: TreeView)
    trimmed -> {
      let rows = ui.build_tree_rows(state.groups, state.collapsed, 0, 0)
      let is_rename = case list.drop(rows, state.cursor) |> list.first {
        Ok(ui.GroupRow(_, _, _, _, _)) -> True
        Ok(ui.PropertyRow(..)) | Ok(ui.SystemRow(..)) | Error(_) -> False
      }
      case is_rename {
        True -> {
          let gi = cursor_group_index(state)
          let new_groups = rename_group(state.groups, gi, trimmed)
          DefineState(
            ..state,
            groups: new_groups,
            dirty: True,
            view_mode: TreeView,
            status_msg: option.Some(style.green("그룹명 변경됨")),
          )
        }
        False -> {
          let new_group = model.PropertyGroup(trimmed, [])
          let new_groups = list.append(state.groups, [new_group])
          DefineState(
            ..state,
            groups: new_groups,
            dirty: True,
            view_mode: TreeView,
            status_msg: option.Some(style.green("그룹 추가됨: " <> trimmed)),
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
      let selected_type = case
        list.drop(model.all_types(), state.selected_type_idx)
        |> list.first
      {
        Ok(t) -> t
        Error(_) -> model.TypeString
      }
      let prop = model.default_property(trimmed, selected_type)
      let item = model.PropItem(prop)
      let new_groups =
        add_item_to_group(state.groups, state.add_target_group, item)
      DefineState(
        ..state,
        groups: new_groups,
        dirty: True,
        view_mode: TreeView,
        status_msg: option.Some(style.green("속성 추가됨: " <> trimmed)),
      )
    }
  }
}

fn update_field_text(
  fields: List(ui.EditField),
  index: Int,
  value: String,
) -> List(ui.EditField) {
  list.index_map(fields, fn(field, i) {
    case i == index {
      True ->
        case field {
          ui.TextField(label, _) -> ui.TextField(label, value)
          ui.BoolField(..)
          | ui.ReadOnlyField(..)
          | ui.ListField(..)
          | ui.SelectField(..) -> field
        }
      False -> field
    }
  })
}

fn toggle_bool_field(
  fields: List(ui.EditField),
  index: Int,
) -> List(ui.EditField) {
  list.index_map(fields, fn(field, i) {
    case i == index {
      True ->
        case field {
          ui.BoolField(label, v) -> ui.BoolField(label, !v)
          ui.TextField(..)
          | ui.ReadOnlyField(..)
          | ui.ListField(..)
          | ui.SelectField(..) -> field
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
  case state.view_mode {
    EditProperty(original, fields, _, _, _, _) -> {
      let new_fields = update_field_text(fields, field_index, value)
      DefineState(
        ..state,
        view_mode: EditProperty(original, new_fields, field_index, False, "", 0),
      )
    }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> DefineState(..state, view_mode: TreeView)
  }
}

fn get_enum_caption(state: DefineState, index: Int) -> String {
  case state.view_mode {
    EditEnum(values, _) ->
      case list.drop(values, index) |> list.first {
        Ok(ev) -> ev.caption
        Error(_) -> ""
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> ""
  }
}

fn apply_enum_edit(
  state: DefineState,
  index: Int,
  new_key: String,
  caption: String,
) -> DefineState {
  let values = get_current_enum_values(state)
  let new_values =
    list.index_map(values, fn(v, i) {
      case i == index {
        True -> model.EnumValue(new_key, caption)
        False -> v
      }
    })
  DefineState(..state, view_mode: EditEnum(new_values, index))
}

fn apply_new_enum(
  state: DefineState,
  key: String,
  caption: String,
) -> DefineState {
  let values = get_current_enum_values(state)
  let new_values = list.append(values, [model.EnumValue(key, caption)])
  DefineState(
    ..state,
    view_mode: EditEnum(new_values, list.length(new_values) - 1),
    status_msg: option.Some(style.green("열거형 값 추가됨")),
  )
}

fn get_current_enum_values(state: DefineState) -> List(model.EnumValue) {
  let gi = state.edit_group_idx
  let ii = state.edit_item_idx
  case list.drop(state.groups, gi) |> list.first {
    Ok(group) ->
      case list.drop(group.items, ii) |> list.first {
        Ok(model.PropItem(prop)) -> prop.enumeration_values
        Ok(model.SysPropItem(_)) | Error(_) -> []
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
  values: List(model.EnumValue),
) -> DefineState {
  let gi = state.edit_group_idx
  let ii = state.edit_item_idx
  let new_groups = update_property_enum_values(state.groups, gi, ii, values)
  let prop = get_property(new_groups, gi, ii)
  case prop {
    option.Some(p) -> {
      let fields = ui.property_to_fields(p)
      DefineState(
        ..state,
        groups: new_groups,
        dirty: True,
        view_mode: EditProperty(p, fields, 0, False, "", 0),
      )
    }
    option.None ->
      DefineState(..state, groups: new_groups, dirty: True, view_mode: TreeView)
  }
}

fn add_item_to_group(
  groups: List(model.PropertyGroup),
  group_index: Int,
  item: model.PropertyItem,
) -> List(model.PropertyGroup) {
  list.index_map(groups, fn(group, i) {
    case i == group_index {
      True ->
        model.PropertyGroup(..group, items: list.append(group.items, [item]))
      False -> group
    }
  })
}

fn delete_group(
  groups: List(model.PropertyGroup),
  group_index: Int,
) -> List(model.PropertyGroup) {
  list.index_map(groups, fn(g, i) { #(i, g) })
  |> list.filter(fn(pair) { pair.0 != group_index })
  |> list.map(fn(pair) { pair.1 })
}

fn delete_item_from_group(
  groups: List(model.PropertyGroup),
  group_index: Int,
  item_index: Int,
) -> List(model.PropertyGroup) {
  list.index_map(groups, fn(group, gi) {
    case gi == group_index {
      True -> {
        let new_items =
          list.index_map(group.items, fn(item, ii) { #(ii, item) })
          |> list.filter(fn(pair) { pair.0 != item_index })
          |> list.map(fn(pair) { pair.1 })
        model.PropertyGroup(..group, items: new_items)
      }
      False -> group
    }
  })
}

fn rename_group(
  groups: List(model.PropertyGroup),
  group_index: Int,
  name: String,
) -> List(model.PropertyGroup) {
  list.index_map(groups, fn(group, i) {
    case i == group_index {
      True -> model.PropertyGroup(..group, caption: name)
      False -> group
    }
  })
}

fn update_property(
  groups: List(model.PropertyGroup),
  group_index: Int,
  item_index: Int,
  prop: model.Property,
) -> List(model.PropertyGroup) {
  list.index_map(groups, fn(group, gi) {
    case gi == group_index {
      True -> {
        let new_items =
          list.index_map(group.items, fn(item, ii) {
            case ii == item_index {
              True -> model.PropItem(prop)
              False -> item
            }
          })
        model.PropertyGroup(..group, items: new_items)
      }
      False -> group
    }
  })
}

fn update_property_enum_values(
  groups: List(model.PropertyGroup),
  group_index: Int,
  item_index: Int,
  values: List(model.EnumValue),
) -> List(model.PropertyGroup) {
  list.index_map(groups, fn(group, gi) {
    case gi == group_index {
      True -> {
        let new_items =
          list.index_map(group.items, fn(item, ii) {
            case ii == item_index {
              True ->
                case item {
                  model.PropItem(prop) ->
                    model.PropItem(
                      model.Property(..prop, enumeration_values: values),
                    )
                  model.SysPropItem(system_property) ->
                    model.SysPropItem(system_property)
                }
              False -> item
            }
          })
        model.PropertyGroup(..group, items: new_items)
      }
      False -> group
    }
  })
}

fn get_property(
  groups: List(model.PropertyGroup),
  group_index: Int,
  item_index: Int,
) -> option.Option(model.Property) {
  case list.drop(groups, group_index) |> list.first {
    Ok(group) ->
      case list.drop(group.items, item_index) |> list.first {
        Ok(model.PropItem(prop)) -> option.Some(prop)
        Ok(model.SysPropItem(_)) | Error(_) -> option.None
      }
    Error(_) -> option.None
  }
}

fn handle_type_edit_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    SelectTypeForEdit(cursor) ->
      case key {
        KeyCtrlC | KeyEscape -> {
          let prop =
            get_property(
              state.groups,
              state.edit_group_idx,
              state.edit_item_idx,
            )
          case prop {
            option.Some(p) -> {
              let fields = ui.property_to_fields(p)
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditProperty(p, fields, 0, False, "", 0),
                ),
              )
            }
            option.None -> tui_loop(DefineState(..state, view_mode: TreeView))
          }
        }
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(DefineState(..state, view_mode: SelectTypeForEdit(new_c)))
        }
        KeyDown -> {
          let max = list.length(model.all_types()) - 1
          let new_c = int.min(max, cursor + 1)
          tui_loop(DefineState(..state, view_mode: SelectTypeForEdit(new_c)))
        }
        KeyEnter -> {
          case list.drop(model.all_types(), cursor) |> list.first {
            Ok(new_type) -> {
              let gi = state.edit_group_idx
              let ii = state.edit_item_idx
              case get_property(state.groups, gi, ii) {
                option.Some(prop) -> {
                  let new_prop = model.change_property_type(prop, new_type)
                  let new_groups =
                    update_property(state.groups, gi, ii, new_prop)
                  let new_fields = ui.property_to_fields(new_prop)
                  tui_loop(
                    DefineState(
                      ..state,
                      groups: new_groups,
                      dirty: True,
                      view_mode: EditProperty(
                        new_prop,
                        new_fields,
                        0,
                        False,
                        "",
                        0,
                      ),
                    ),
                  )
                }
                option.None ->
                  tui_loop(DefineState(..state, view_mode: TreeView))
              }
            }
            Error(_) -> tui_loop(state)
          }
        }
        KeyNone
        | KeyRight
        | KeyLeft
        | KeyBackspace
        | KeyChar(_)
        | KeyHome
        | KeyEnd
        | KeyPageUp
        | KeyPageDown
        | KeyTab -> tui_loop(state)
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | EditMultiSelect(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn handle_multi_select_key(
  state: DefineState,
  key: KeyInput,
) -> promise.Promise(DefineState) {
  case state.view_mode {
    EditMultiSelect(label, options, selected, cursor) ->
      case key {
        KeyEscape | KeyCtrlC -> {
          tui_loop(return_from_multi_select(state, label, selected))
        }
        KeyUp -> {
          let new_c = int.max(0, cursor - 1)
          tui_loop(
            DefineState(
              ..state,
              view_mode: EditMultiSelect(label, options, selected, new_c),
            ),
          )
        }
        KeyDown -> {
          let max = int.max(0, list.length(options) - 1)
          let new_c = int.min(max, cursor + 1)
          tui_loop(
            DefineState(
              ..state,
              view_mode: EditMultiSelect(label, options, selected, new_c),
            ),
          )
        }
        KeyEnter -> {
          case list.drop(options, cursor) |> list.first {
            Ok(opt) -> {
              let new_selected = case list.contains(selected, opt) {
                True -> list.filter(selected, fn(s) { s != opt })
                False -> list.append(selected, [opt])
              }
              tui_loop(
                DefineState(
                  ..state,
                  view_mode: EditMultiSelect(
                    label,
                    options,
                    new_selected,
                    cursor,
                  ),
                ),
              )
            }
            Error(_) -> tui_loop(state)
          }
        }
        KeyNone
        | KeyRight
        | KeyLeft
        | KeyBackspace
        | KeyChar(_)
        | KeyHome
        | KeyEnd
        | KeyPageUp
        | KeyPageDown
        | KeyTab -> tui_loop(state)
      }
    TreeView
    | SelectType(..)
    | InputText(..)
    | EditProperty(..)
    | EditEnum(..)
    | EditMeta(..)
    | SelectSystemProp(..)
    | SelectTypeForEdit(..)
    | ConfirmDelete(..)
    | ConfirmQuit -> tui_loop(state)
  }
}

fn return_from_multi_select(
  state: DefineState,
  field_label: String,
  selected: List(String),
) -> DefineState {
  let gi = state.edit_group_idx
  let ii = state.edit_item_idx
  case get_property(state.groups, gi, ii) {
    option.Some(prop) -> {
      let new_prop = case field_label {
        "AttrTypes:" -> model.Property(..prop, attribute_types: selected)
        "AssocTypes:" -> model.Property(..prop, association_types: selected)
        "SelTypes:" -> model.Property(..prop, selection_types: selected)
        _ -> prop
      }
      let new_groups = update_property(state.groups, gi, ii, new_prop)
      let new_fields = ui.property_to_fields(new_prop)
      DefineState(
        ..state,
        groups: new_groups,
        dirty: True,
        view_mode: EditProperty(new_prop, new_fields, 0, False, "", 0),
      )
    }
    option.None -> DefineState(..state, view_mode: TreeView)
  }
}

fn save_xml(state: DefineState) -> DefineState {
  let xml = document.serialize(state.widget_meta, state.groups)
  case file_boundary.write(state.xml_path, xml) {
    Ok(Nil) ->
      DefineState(
        ..state,
        dirty: False,
        status_msg: option.Some(style.green("저장됨: " <> state.xml_path)),
      )
    Error(error) ->
      DefineState(
        ..state,
        status_msg: option.Some(style.red(file_error_message(error))),
      )
  }
}

fn file_error_message(error: file_boundary.FileError) -> String {
  case error {
    file_boundary.WidgetNameWasNotDeclared(path) ->
      "No widgetName is declared in " <> path <> "."
    file_boundary.WidgetXmlWasNotFound(path) ->
      "The widget XML file does not exist: " <> path
    file_boundary.FileCouldNotBeRead(path, reason) ->
      "Unable to read " <> path <> ": " <> reason
    file_boundary.FileCouldNotBeWritten(path, reason) ->
      "Unable to write " <> path <> ": " <> reason
  }
}

// -- FFI --
@external(javascript, "./define_ffi.mjs", "is_tty")
fn is_tty() -> Bool

@external(javascript, "./define_ffi.mjs", "exit_process")
fn exit_process() -> Nil

@external(javascript, "./define_ffi.mjs", "terminal_size")
fn terminal_size() -> #(Int, Int)

@external(javascript, "./define_ffi.mjs", "poll_key_raw")
fn poll_key_raw(timeout_ms: Int) -> promise.Promise(#(Int, String))

@external(javascript, "./define_ffi.mjs", "set_terminal_raw_mode")
fn set_terminal_raw_mode(enabled: Bool) -> Result(Nil, RawTerminalModeError)

@external(javascript, "./define_ffi.mjs", "terminal_mode_error_message")
fn raw_terminal_mode_error_message(error: RawTerminalModeError) -> String
