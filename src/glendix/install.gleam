// npm 의존성 설치 (패키지 매니저 자동 감지) + 바인딩 생성

import glendix/cmd

pub fn main() {
  cmd.exec(cmd.detect_install_command())
  cmd.generate_bindings()
}
