// 셸 명령어 실행 유틸리티 + 패키지 매니저 감지 + TOML 설정 연동

import gleam/option.{type Option, Some}

/// 셸 명령어를 실행한다. stdio는 inherit되어 실시간 출력된다.
@external(javascript, "./cmd_ffi.mjs", "exec")
pub fn exec(command: String) -> Nil

/// 파일 존재 여부를 확인한다.
@external(javascript, "./cmd_ffi.mjs", "file_exists")
fn file_exists(path: String) -> Bool

/// gleam.toml [tools.glendix].pm 오버라이드를 읽는다.
@external(javascript, "./cmd_ffi.mjs", "read_pm_override")
fn read_pm_override() -> Option(String)

/// lock 파일 기반으로 패키지 매니저 runner를 감지한다.
fn detect_runner_from_lockfile() -> String {
  case file_exists("pnpm-lock.yaml") {
    True -> "pnpm exec"
    False ->
      case file_exists("bun.lockb") || file_exists("bun.lock") {
        True -> "bunx"
        False -> "npx"
      }
  }
}

/// 패키지 매니저 runner를 감지한다. gleam.toml의 pm 오버라이드 → lock 파일 순.
pub fn detect_runner() -> String {
  case read_pm_override() {
    Some("pnpm") -> "pnpm exec"
    Some("bun") -> "bunx"
    Some("npm") -> "npx"
    _ -> detect_runner_from_lockfile()
  }
}

/// lock 파일 기반으로 패키지 매니저 install 명령어를 감지한다.
fn detect_install_from_lockfile() -> String {
  case file_exists("pnpm-lock.yaml") {
    True -> "pnpm install"
    False ->
      case file_exists("bun.lockb") || file_exists("bun.lock") {
        True -> "bun install"
        False -> "npm install"
      }
  }
}

/// install 명령어를 감지한다. gleam.toml의 pm 오버라이드 → lock 파일 순.
pub fn detect_install_command() -> String {
  case read_pm_override() {
    Some("pnpm") -> "pnpm install"
    Some("bun") -> "bun install"
    Some("npm") -> "npm install"
    _ -> detect_install_from_lockfile()
  }
}

/// pluggable-widgets-tools를 감지된 runner로 실행한다.
pub fn run_tool(args: String) -> Nil {
  exec(detect_runner() <> " pluggable-widgets-tools " <> args)
}

/// 브릿지 JS 파일을 자동 생성/삭제하며 셸 명령어를 실행한다.
@external(javascript, "./cmd_ffi.mjs", "run_with_bridge")
fn run_with_bridge(command: String) -> Nil

/// 브릿지 JS 자동 생성 후 pluggable-widgets-tools를 실행하고, 완료 후 브릿지를 삭제한다.
pub fn run_tool_with_bridge(args: String) -> Nil {
  run_with_bridge(detect_runner() <> " pluggable-widgets-tools " <> args)
}

/// 브릿지 JS 자동 생성 + .gleam 파일 변경 감지 + build:web 반복 실행
@external(javascript, "./cmd_ffi.mjs", "run_dev_with_bridge")
fn run_dev_with_bridge(build_command: String) -> Nil

/// .gleam 파일 변경 감지와 함께 개발 서버를 실행한다.
/// Rollup --watch 대신 build:web를 반복 실행한다 (Windows chokidar 오버헤드 회피).
pub fn run_tool_dev() -> Nil {
  run_dev_with_bridge(detect_runner() <> " pluggable-widgets-tools build:web")
}

/// gleam.toml [tools.glendix.bindings]에서 바인딩 코드를 생성한다.
/// glendix 빌드 경로에 binding_ffi.mjs를 생성하여
/// 사용자가 .mjs 파일을 작성하지 않아도 외부 React 컴포넌트를 사용할 수 있게 한다.
@external(javascript, "./cmd_ffi.mjs", "generate_bindings")
pub fn generate_bindings() -> Nil

