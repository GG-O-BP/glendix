// Mendix Marketplace 위젯 검색 + 다운로드

import glendix/cmd

/// Marketplace API로 위젯을 검색하고 선택한 위젯을 다운로드한다.
@external(javascript, "./marketplace_ffi.mjs", "download_widgets")
fn download_widgets() -> Nil

pub fn main() {
  download_widgets()
  cmd.generate_widget_bindings()
}
