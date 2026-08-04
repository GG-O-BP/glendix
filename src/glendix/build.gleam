//// Provides build operations for Glendix.
////

import glendix/cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  cmd.run_tool_with_bridge("build:web")
  |> cmd.report
}
