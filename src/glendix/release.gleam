//// Runs the Glendix widget release command.
////

import glendix/cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  cmd.run_tool_with_bridge("release:web")
  |> cmd.report
}
