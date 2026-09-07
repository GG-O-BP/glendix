import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export function in_temporary_directory(action) {
  const previous_directory = process.cwd();
  const directory = mkdtempSync(join(tmpdir(), "glendix-file-boundary-test-"));
  process.chdir(directory);
  try {
    return action(directory);
  } finally {
    process.chdir(previous_directory);
    rmSync(directory, { recursive: true, force: true });
  }
}

export function write_invalid_utf8(path) {
  writeFileSync(path, Uint8Array.from([0xff]));
}
