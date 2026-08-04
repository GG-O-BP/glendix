import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { Ok, Error as GleamError } from "../../gleam.mjs";

const WIDGET_NAME_WAS_NOT_DECLARED = 1;
const WIDGET_XML_WAS_NOT_FOUND = 2;
const FILE_COULD_NOT_BE_READ = 3;
const FILE_COULD_NOT_BE_WRITTEN = 4;

function errorReason(error) {
  return error instanceof globalThis.Error ? error.message : String(error);
}

function fileError(kind, path, reason) {
  return { kind, path, reason };
}

export function find_widget_xml() {
  const packagePath = "package.json";
  let packageConfiguration;
  try {
    packageConfiguration = JSON.parse(readFileSync(packagePath, "utf-8"));
  } catch (error) {
    return new GleamError(
      fileError(FILE_COULD_NOT_BE_READ, packagePath, errorReason(error)),
    );
  }

  const widgetName = packageConfiguration.widgetName;
  if (typeof widgetName !== "string" || widgetName.trim() === "") {
    return new GleamError(
      fileError(
        WIDGET_NAME_WAS_NOT_DECLARED,
        packagePath,
        "package.json does not contain a non-empty widgetName",
      ),
    );
  }

  const widgetPath = `src/${widgetName}.xml`;
  if (!existsSync(widgetPath)) {
    return new GleamError(
      fileError(
        WIDGET_XML_WAS_NOT_FOUND,
        widgetPath,
        "the declared widget XML file does not exist",
      ),
    );
  }

  return new Ok(widgetPath);
}

export function read_file(path) {
  try {
    return new Ok(readFileSync(path, "utf-8"));
  } catch (error) {
    return new GleamError(
      fileError(FILE_COULD_NOT_BE_READ, path, errorReason(error)),
    );
  }
}

export function write_file(path, content) {
  try {
    writeFileSync(path, content, "utf-8");
    return new Ok(undefined);
  } catch (error) {
    return new GleamError(
      fileError(FILE_COULD_NOT_BE_WRITTEN, path, errorReason(error)),
    );
  }
}

export function file_error_kind(error) {
  return error.kind;
}

export function file_error_path(error) {
  return error.path;
}

export function file_error_reason(error) {
  return error.reason;
}
