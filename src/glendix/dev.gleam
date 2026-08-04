//// Runs the Glendix development server command.
////

import glendix/cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  cmd.run_tool_dev()
  |> cmd.report
}
