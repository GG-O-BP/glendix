import process from "node:process";

export function sigint_listener_count() {
  return process.listenerCount("SIGINT");
}
