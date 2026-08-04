//// Runs the Glendix widget lint command with automatic fixes.
////

import glendix/cmd

/// Runs this module's command-line entrypoint.
pub fn main() -> Nil {
  cmd.run_tool("lint:fix")
  |> cmd.report
}
