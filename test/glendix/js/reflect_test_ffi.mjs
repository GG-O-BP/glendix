export function value_to_string(value) {
  return String(value);
}

export function value_is_undefined(value) {
  return value === undefined;
}

export function method_object() {
  return {
    total: 3,
    describe() {
      return "total:" + this.total;
    },
    add(first, second) {
      return this.total + first + second;
    },
  };
}

export function point_constructor() {
  return class ReflectPoint {
    constructor(x, y) {
      this.x = x;
      this.y = y;
    }
  };
}

export function same_object(left, right) {
  return left === right;
}

export function point_summary(point) {
  return `${point.x},${point.y}`;
}
