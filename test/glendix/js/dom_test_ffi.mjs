export function new_element_fixture() {
  const child = {
    operations: { click: 0 },
    click() {
      this.operations.click += 1;
    },
  };
  return {
    child,
    operations: {
      blur: 0,
      click: 0,
      focus: 0,
      scroll_into_view: 0,
    },
    scrollArgumentCount: -1,
    focus() {
      this.operations.focus += 1;
    },
    blur() {
      this.operations.blur += 1;
    },
    click() {
      this.operations.click += 1;
    },
    scrollIntoView(...arguments_) {
      this.operations.scroll_into_view += 1;
      this.scrollArgumentCount = arguments_.length;
    },
    getBoundingClientRect() {
      return { x: 1, y: 2, width: 30, height: 40 };
    },
    querySelector(selector) {
      return selector === ".child" ? this.child : null;
    },
  };
}

export function operation_count(element, operation) {
  return element.operations[operation];
}

export function scroll_argument_count(element) {
  return element.scrollArgumentCount;
}

export function is_fixture_child(element, candidate) {
  return element.child === candidate;
}

export function rectangle_x(rectangle) {
  return rectangle.x;
}

export function rectangle_y(rectangle) {
  return rectangle.y;
}

export function rectangle_width(rectangle) {
  return rectangle.width;
}

export function rectangle_height(rectangle) {
  return rectangle.height;
}
