//// Starts the Glendix widget development runtime.
////

import glendix/cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  cmd.run_tool_with_bridge("start:server")
  |> cmd.report
}
