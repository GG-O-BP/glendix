import { toList } from "../../gleam.mjs";
export function list_to_array(list) {
  return list.toArray();
}
export function array_to_list(array) {
  return toList(array);
}
