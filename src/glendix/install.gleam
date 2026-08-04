//// Installs JavaScript dependencies and generates Glendix project bindings.
////
//// Package acquisition is intentionally not performed here. Run mxpak first
//// when the project declares `[tools.mxpak.widgets.*]`, then this command asks
//// Mendraw to generate bindings from the installed assets.

import gleam/result
import glendix/cmd
import mendraw/cmd as mendraw_cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  install()
  |> cmd.report
}

fn install() -> Result(Nil, cmd.CommandError) {
  use install_command <- result.try(cmd.detect_install_command())
  use _ <- result.try(cmd.exec(install_command))
  use _ <- result.try(
    mendraw_cmd.generate_widget_bindings()
    |> result.map_error(map_mendraw_error),
  )
  cmd.generate_bindings()
}

fn map_mendraw_error(error: mendraw_cmd.CommandError) -> cmd.CommandError {
  let mendraw_cmd.CommandFailed(operation, reason) = error
  cmd.CommandFailed(operation: "Mendraw " <> operation, reason: reason)
}
