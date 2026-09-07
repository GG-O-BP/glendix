let pickerInvocationCount = 0;
let pickerReadCount = 0;

export function observe_object_url_lifetime(callback) {
  const originalCreate = URL.createObjectURL;
  const originalRevoke = URL.revokeObjectURL;
  let createCount = 0;
  let revokeCount = 0;

  URL.createObjectURL = () => {
    createCount += 1;
    return `blob:glendix-test-${createCount}`;
  };
  URL.revokeObjectURL = () => {
    revokeCount += 1;
  };

  try {
    const result = callback();
    return [result, createCount, revokeCount];
  } finally {
    URL.createObjectURL = originalCreate;
    URL.revokeObjectURL = originalRevoke;
  }
}

function bytesFile(name, type, contents) {
  return {
    name,
    type,
    size: contents.length,
    async arrayBuffer() {
      pickerReadCount += 1;
      return Uint8Array.from(contents).buffer;
    },
  };
}

function handle(name, fileOrError) {
  return {
    name,
    async getFile() {
      if (fileOrError instanceof Error) throw fileOrError;
      return fileOrError;
    },
  };
}

export function install_picker_scenario(scenario) {
  pickerInvocationCount = 0;
  pickerReadCount = 0;
  globalThis.window = globalThis;

  if (scenario === "unsupported") {
    delete globalThis.showOpenFilePicker;
    return;
  }

  globalThis.showOpenFilePicker = async () => {
    pickerInvocationCount += 1;
    switch (scenario) {
      case "cancel":
        throw new DOMException("The user aborted a request", "AbortError");
      case "no_handles":
        return [];
      case "selection_failure":
        throw new Error("permission denied");
      case "open_failure":
        return [handle("broken.ic", new Error("open failed"))];
      case "empty":
        return [handle("empty.ic", bytesFile("empty.ic", "", []))];
      case "exact":
        return [
          handle(
            "workbook.ic",
            bytesFile(
              "workbook.ic",
              "application/octet-stream",
              [100, 97, 116, 97],
            ),
          ),
        ];
      case "overflow":
        return [
          handle(
            "large.ic",
            bytesFile("large.ic", "application/octet-stream", [1, 2, 3, 4, 5]),
          ),
        ];
      case "image":
        return [
          handle(
            "pixel.png",
            bytesFile("pixel.png", "image/png", [137, 80, 78, 71]),
          ),
        ];
      case "read_failure":
        return [
          handle("unreadable.ic", {
            name: "unreadable.ic",
            type: "application/octet-stream",
            size: 4,
            async arrayBuffer() {
              pickerReadCount += 1;
              throw new Error("read failed");
            },
          }),
        ];
      case "multiple":
        return [
          handle("first.ic", bytesFile("first.ic", "", [1])),
          handle("second.ic", bytesFile("second.ic", "", [2])),
        ];
      default:
        throw new Error(`unknown picker scenario: ${scenario}`);
    }
  };
}

export function picker_invocation_count() {
  return pickerInvocationCount;
}

export function picker_read_count() {
  return pickerReadCount;
}
