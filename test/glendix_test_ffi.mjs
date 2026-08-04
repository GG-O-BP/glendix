import { toList } from "./gleam.mjs";

function clone_list(list, clone) {
  return toList(list.toArray().map(clone));
}

function clone_attribute(attribute) {
  return { ...attribute };
}

function clone_node(node) {
  const cloned = { ...node };
  if (node.attributes) {
    cloned.attributes = clone_list(node.attributes, clone_attribute);
  }
  if (node.children) {
    cloned.children = clone_list(node.children, clone_node);
  }
  if (node.child) {
    cloned.child = clone_node(node.child);
  }
  if (node.view) {
    cloned.view = () => clone_node(node.view());
  }
  return cloned;
}

export function clone_lustre_tree(element) {
  return clone_node(element);
}

function collect_summary(element, parts) {
  if (element === null || element === undefined || element === false) return;
  if (typeof element === "string") {
    parts.push(element);
    return;
  }
  if (Array.isArray(element)) {
    for (const child of element) collect_summary(child, parts);
    return;
  }
  if (!element.props) return;
  if (typeof element.type === "string") {
    const id = element.props.id ? `#${element.props.id}` : "";
    parts.push(element.type + id);
  }
  collect_summary(element.props.children, parts);
}

export function rendered_tree_summary(element) {
  const parts = [];
  collect_summary(element, parts);
  return parts.join("|");
}

export function test_component() {
  return "section";
}
