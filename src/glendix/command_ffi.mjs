import { spawnSync } from "node:child_process";
import process from "node:process";
import { Ok, Error as GleamError } from "../gleam.mjs";

function filterErlangWarnings(stderr) {
  const lines = stderr.split(/\r?\n/);
  const result = [];
  let skip = false;
  let skipNextEmpty = false;
  for (let index = 0; index < lines.length; index += 1) {
    if (!skip && lines[index] === "warning: Unused value") {
      if (
        index + 1 < lines.length
        && lines[index + 1].includes("gleam_erlang")
      ) {
        skip = true;
        continue;
      }
    }
    if (skip) {
      if (lines[index].includes("not needed")) {
        skip = false;
        skipNextEmpty = true;
      }
      continue;
    }
    if (skipNextEmpty) {
      skipNextEmpty = false;
      if (lines[index].trim() === "") continue;
    }
    result.push(lines[index]);
  }
  return result.join("\n").replace(/\n{3,}/g, "\n\n").trim();
}

function runFilteredCommandOrThrow(command) {
  const result = spawnSync(command, {
    shell: true,
    stdio: ["inherit", "pipe", "pipe"],
  });
  if (result.stdout && result.stdout.length > 0) {
    process.stdout.write(result.stdout);
  }
  if (result.stderr && result.stderr.length > 0) {
    const filtered = filterErlangWarnings(result.stderr.toString());
    if (filtered) process.stderr.write(filtered + "\n");
  }
  if (result.status !== 0) {
    const error = new Error("Command failed: " + command);
    error.status = result.status;
    throw error;
  }
}

export { runFilteredCommandOrThrow };

export function is_windows() {
  return globalThis.Deno?.build?.os === "windows" || process.platform === "win32";
}

export function windows_shell() {
  return process.env.ComSpec ?? process.env.COMSPEC ?? "cmd.exe";
}

export function capture_sigint_listeners() {
  return process.rawListeners("SIGINT");
}

export function restore_sigint_listeners(listeners) {
  const retained = new Set(listeners);
  for (const listener of process.rawListeners("SIGINT")) {
    if (!retained.has(listener)) process.removeListener("SIGINT", listener);
  }
}

export function run_filtered(command) {
  try {
    runFilteredCommandOrThrow(command);
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(error);
  }
}

export function error_message(error) {
  return error instanceof globalThis.Error ? error.message : String(error);
}
