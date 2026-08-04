//// Runs the Glendix widget lint command.
////

import glendix/cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  cmd.run_tool("lint")
  |> cmd.report
}
