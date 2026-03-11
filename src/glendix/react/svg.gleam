// SVG 요소 편의 함수 - 순수 Gleam, FFI 없음
// react.element / react.void_element 래퍼

import glendix/react.{type ReactElement}
import glendix/react/attribute.{type Attribute}

// === 컨테이너 ===

pub fn svg(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("svg", attrs, children)
}

pub fn g(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("g", attrs, children)
}

pub fn defs(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("defs", attrs, children)
}

pub fn symbol(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("symbol", attrs, children)
}

pub fn use_(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("use", attrs, children)
}

pub fn marker(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("marker", attrs, children)
}

// === 도형 ===

pub fn circle(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("circle", attrs, children)
}

pub fn ellipse(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("ellipse", attrs, children)
}

pub fn line(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("line", attrs, children)
}

pub fn path(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("path", attrs, children)
}

pub fn polygon(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("polygon", attrs, children)
}

pub fn polyline(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("polyline", attrs, children)
}

pub fn rect(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("rect", attrs, children)
}

// === 텍스트 ===

pub fn text(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("text", attrs, children)
}

pub fn tspan(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("tspan", attrs, children)
}

pub fn text_path(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("textPath", attrs, children)
}

// === 그래디언트/패턴 ===

pub fn linear_gradient(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("linearGradient", attrs, children)
}

pub fn radial_gradient(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("radialGradient", attrs, children)
}

pub fn stop(attrs: List(Attribute)) -> ReactElement {
  react.void_element("stop", attrs)
}

pub fn pattern(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("pattern", attrs, children)
}

// === 필터 ===

pub fn filter(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("filter", attrs, children)
}

pub fn fe_color_matrix(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feColorMatrix", attrs, children)
}

pub fn fe_composite(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feComposite", attrs, children)
}

pub fn fe_flood(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feFlood", attrs)
}

pub fn fe_gaussian_blur(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feGaussianBlur", attrs)
}

pub fn fe_merge(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feMerge", attrs, children)
}

pub fn fe_merge_node(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feMergeNode", attrs)
}

pub fn fe_offset(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feOffset", attrs)
}

pub fn fe_blend(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feBlend", attrs)
}

pub fn fe_drop_shadow(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feDropShadow", attrs)
}

// === 클리핑/마스킹 ===

pub fn clip_path(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("clipPath", attrs, children)
}

pub fn mask(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("mask", attrs, children)
}

// === 기타 ===

pub fn foreign_object(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("foreignObject", attrs, children)
}

pub fn image(attrs: List(Attribute)) -> ReactElement {
  react.void_element("image", attrs)
}

pub fn animate(attrs: List(Attribute)) -> ReactElement {
  react.void_element("animate", attrs)
}

pub fn animate_transform(attrs: List(Attribute)) -> ReactElement {
  react.void_element("animateTransform", attrs)
}

pub fn title(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("title", attrs, children)
}

pub fn desc(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("desc", attrs, children)
}

// === 필터 프리미티브 (추가) ===

pub fn fe_convolve_matrix(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feConvolveMatrix", attrs, children)
}

pub fn fe_diffuse_lighting(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feDiffuseLighting", attrs, children)
}

pub fn fe_displacement_map(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feDisplacementMap", attrs)
}

pub fn fe_distant_light(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feDistantLight", attrs)
}

pub fn fe_image(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feImage", attrs)
}

pub fn fe_morphology(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feMorphology", attrs)
}

pub fn fe_point_light(attrs: List(Attribute)) -> ReactElement {
  react.void_element("fePointLight", attrs)
}

pub fn fe_specular_lighting(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feSpecularLighting", attrs, children)
}

pub fn fe_spot_light(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feSpotLight", attrs)
}

pub fn fe_tile(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feTile", attrs, children)
}

pub fn fe_turbulence(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feTurbulence", attrs)
}

pub fn fe_func_r(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feFuncR", attrs)
}

pub fn fe_func_g(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feFuncG", attrs)
}

pub fn fe_func_b(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feFuncB", attrs)
}

pub fn fe_func_a(attrs: List(Attribute)) -> ReactElement {
  react.void_element("feFuncA", attrs)
}

pub fn fe_component_transfer(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("feComponentTransfer", attrs, children)
}

// === 기타 SVG 요소 (추가) ===

/// SVG set (애니메이션 속성 설정)
pub fn set(attrs: List(Attribute)) -> ReactElement {
  react.void_element("set", attrs)
}

/// SVG mpath (모션 경로)
pub fn mpath(attrs: List(Attribute)) -> ReactElement {
  react.void_element("mpath", attrs)
}

/// SVG switch (조건부 렌더링, switch → Gleam 예약어 회피)
pub fn switch_(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("switch", attrs, children)
}
