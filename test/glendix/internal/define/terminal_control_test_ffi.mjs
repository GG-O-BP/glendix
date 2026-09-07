import {
  poll_key_raw,
  set_terminal_raw_mode,
} from "./terminal_control_ffi.mjs";

function with_stdin_methods(setRawMode, resume, action) {
  const setRawModeDescriptor = Object.getOwnPropertyDescriptor(
    process.stdin,
    "setRawMode",
  );
  const resumeDescriptor = Object.getOwnPropertyDescriptor(
    process.stdin,
    "resume",
  );
  Object.defineProperty(process.stdin, "setRawMode", {
    configurable: true,
    value: setRawMode,
    writable: true,
  });
  Object.defineProperty(process.stdin, "resume", {
    configurable: true,
    value: resume,
    writable: true,
  });
  try {
    return action();
  } finally {
    if (setRawModeDescriptor) {
      Object.defineProperty(process.stdin, "setRawMode", setRawModeDescriptor);
    } else {
      delete process.stdin.setRawMode;
    }
    if (resumeDescriptor) {
      Object.defineProperty(process.stdin, "resume", resumeDescriptor);
    } else {
      delete process.stdin.resume;
    }
  }
}

export function set_raw_mode_without_support() {
  return with_stdin_methods(
    undefined,
    () => undefined,
    () => set_terminal_raw_mode(true),
  );
}

export function set_raw_mode_with_exception() {
  return with_stdin_methods(
    () => {
      throw new Error("raw mode exploded");
    },
    () => undefined,
    () => set_terminal_raw_mode(true),
  );
}

export function raw_mode_lifecycle() {
  let enabledArgument = false;
  let enabledResumeCalled = false;
  const enabledResult = with_stdin_methods(
    (enabled) => {
      enabledArgument = enabled;
    },
    () => {
      enabledResumeCalled = true;
    },
    () => set_terminal_raw_mode(true),
  );

  let disabledArgument = true;
  let disabledResumeCalled = false;
  const disabledResult = with_stdin_methods(
    (enabled) => {
      disabledArgument = enabled;
    },
    () => {
      disabledResumeCalled = true;
    },
    () => set_terminal_raw_mode(false),
  );

  return [
    enabledResult.constructor.name === "Ok" && enabledArgument,
    enabledResumeCalled,
    disabledResult.constructor.name === "Ok" && !disabledArgument,
    disabledResumeCalled,
  ];
}

export async function poll_key_sequence() {
  const pending = poll_key_raw(1000);
  process.stdin.emit("data", Buffer.from("\u001b[A", "utf8"));
  const pendingResult = await pending;

  process.stdin.emit("data", Buffer.from("q", "utf8"));
  const queuedResult = await poll_key_raw(1000);
  const timeoutResult = await poll_key_raw(1);

  return [pendingResult, queuedResult, timeoutResult];
}
