// SVG 전용 속성 - 순수 Gleam, FFI 없음
// attribute.attribute() 래퍼

import glendix/react/attribute.{type Attribute, attribute}

// === 공통 ===

pub fn view_box(value: String) -> Attribute {
  attribute("viewBox", value)
}

pub fn xmlns(value: String) -> Attribute {
  attribute("xmlns", value)
}

pub fn fill(value: String) -> Attribute {
  attribute("fill", value)
}

pub fn stroke(value: String) -> Attribute {
  attribute("stroke", value)
}

pub fn stroke_width(value: String) -> Attribute {
  attribute("strokeWidth", value)
}

pub fn stroke_linecap(value: String) -> Attribute {
  attribute("strokeLinecap", value)
}

pub fn stroke_linejoin(value: String) -> Attribute {
  attribute("strokeLinejoin", value)
}

pub fn stroke_dasharray(value: String) -> Attribute {
  attribute("strokeDasharray", value)
}

pub fn stroke_dashoffset(value: String) -> Attribute {
  attribute("strokeDashoffset", value)
}

pub fn stroke_opacity(value: String) -> Attribute {
  attribute("strokeOpacity", value)
}

pub fn fill_opacity(value: String) -> Attribute {
  attribute("fillOpacity", value)
}

pub fn fill_rule(value: String) -> Attribute {
  attribute("fillRule", value)
}

pub fn clip_rule(value: String) -> Attribute {
  attribute("clipRule", value)
}

pub fn opacity(value: String) -> Attribute {
  attribute("opacity", value)
}

pub fn transform(value: String) -> Attribute {
  attribute("transform", value)
}

// === 좌표 ===

pub fn x(value: String) -> Attribute {
  attribute("x", value)
}

pub fn y(value: String) -> Attribute {
  attribute("y", value)
}

pub fn x1(value: String) -> Attribute {
  attribute("x1", value)
}

pub fn y1(value: String) -> Attribute {
  attribute("y1", value)
}

pub fn x2(value: String) -> Attribute {
  attribute("x2", value)
}

pub fn y2(value: String) -> Attribute {
  attribute("y2", value)
}

pub fn cx(value: String) -> Attribute {
  attribute("cx", value)
}

pub fn cy(value: String) -> Attribute {
  attribute("cy", value)
}

pub fn r(value: String) -> Attribute {
  attribute("r", value)
}

pub fn rx(value: String) -> Attribute {
  attribute("rx", value)
}

pub fn ry(value: String) -> Attribute {
  attribute("ry", value)
}

pub fn dx(value: String) -> Attribute {
  attribute("dx", value)
}

pub fn dy(value: String) -> Attribute {
  attribute("dy", value)
}

// === 도형 ===

pub fn d(value: String) -> Attribute {
  attribute("d", value)
}

pub fn points(value: String) -> Attribute {
  attribute("points", value)
}

pub fn path_length(value: String) -> Attribute {
  attribute("pathLength", value)
}

// === 그래디언트 ===

pub fn offset(value: String) -> Attribute {
  attribute("offset", value)
}

pub fn stop_color(value: String) -> Attribute {
  attribute("stopColor", value)
}

pub fn stop_opacity(value: String) -> Attribute {
  attribute("stopOpacity", value)
}

pub fn gradient_units(value: String) -> Attribute {
  attribute("gradientUnits", value)
}

pub fn gradient_transform(value: String) -> Attribute {
  attribute("gradientTransform", value)
}

pub fn spread_method(value: String) -> Attribute {
  attribute("spreadMethod", value)
}

pub fn fx(value: String) -> Attribute {
  attribute("fx", value)
}

pub fn fy(value: String) -> Attribute {
  attribute("fy", value)
}

// === 텍스트 ===

pub fn text_anchor(value: String) -> Attribute {
  attribute("textAnchor", value)
}

pub fn dominant_baseline(value: String) -> Attribute {
  attribute("dominantBaseline", value)
}

pub fn font_size(value: String) -> Attribute {
  attribute("fontSize", value)
}

pub fn font_family(value: String) -> Attribute {
  attribute("fontFamily", value)
}

pub fn font_weight(value: String) -> Attribute {
  attribute("fontWeight", value)
}

pub fn letter_spacing(value: String) -> Attribute {
  attribute("letterSpacing", value)
}

pub fn text_decoration(value: String) -> Attribute {
  attribute("textDecoration", value)
}

// === 참조 ===

pub fn href(value: String) -> Attribute {
  attribute("href", value)
}

pub fn xlink_href(value: String) -> Attribute {
  attribute("xlinkHref", value)
}

// === 필터 ===

pub fn filter_attr(value: String) -> Attribute {
  attribute("filter", value)
}

pub fn in_(value: String) -> Attribute {
  attribute("in", value)
}

pub fn in2(value: String) -> Attribute {
  attribute("in2", value)
}

pub fn result(value: String) -> Attribute {
  attribute("result", value)
}

pub fn std_deviation(value: String) -> Attribute {
  attribute("stdDeviation", value)
}

pub fn flood_color(value: String) -> Attribute {
  attribute("floodColor", value)
}

pub fn flood_opacity(value: String) -> Attribute {
  attribute("floodOpacity", value)
}

// === 마커/패턴 ===

pub fn marker_start(value: String) -> Attribute {
  attribute("markerStart", value)
}

pub fn marker_mid(value: String) -> Attribute {
  attribute("markerMid", value)
}

pub fn marker_end(value: String) -> Attribute {
  attribute("markerEnd", value)
}

pub fn pattern_units(value: String) -> Attribute {
  attribute("patternUnits", value)
}

pub fn pattern_transform(value: String) -> Attribute {
  attribute("patternTransform", value)
}

// === 클리핑 ===

pub fn clip_path_attr(value: String) -> Attribute {
  attribute("clipPath", value)
}

pub fn mask_attr(value: String) -> Attribute {
  attribute("mask", value)
}

// === 기타 ===

pub fn preserve_aspect_ratio(value: String) -> Attribute {
  attribute("preserveAspectRatio", value)
}

pub fn overflow(value: String) -> Attribute {
  attribute("overflow", value)
}

pub fn cursor(value: String) -> Attribute {
  attribute("cursor", value)
}

pub fn visibility(value: String) -> Attribute {
  attribute("visibility", value)
}

pub fn pointer_events(value: String) -> Attribute {
  attribute("pointerEvents", value)
}

// === 텍스트 렌더링 ===

pub fn alignment_baseline(value: String) -> Attribute {
  attribute("alignmentBaseline", value)
}

pub fn baseline_shift(value: String) -> Attribute {
  attribute("baselineShift", value)
}

pub fn writing_mode(value: String) -> Attribute {
  attribute("writingMode", value)
}

pub fn text_rendering(value: String) -> Attribute {
  attribute("textRendering", value)
}

// === 렌더링 품질 ===

pub fn image_rendering(value: String) -> Attribute {
  attribute("imageRendering", value)
}

pub fn shape_rendering(value: String) -> Attribute {
  attribute("shapeRendering", value)
}

pub fn color_interpolation(value: String) -> Attribute {
  attribute("colorInterpolation", value)
}

pub fn color_interpolation_filters(value: String) -> Attribute {
  attribute("colorInterpolationFilters", value)
}

// === 마커 ===

pub fn marker_height(value: String) -> Attribute {
  attribute("markerHeight", value)
}

pub fn marker_width(value: String) -> Attribute {
  attribute("markerWidth", value)
}

pub fn ref_x(value: String) -> Attribute {
  attribute("refX", value)
}

pub fn ref_y(value: String) -> Attribute {
  attribute("refY", value)
}

pub fn orient(value: String) -> Attribute {
  attribute("orient", value)
}

// === 마스크/클리핑 단위 ===

pub fn mask_units(value: String) -> Attribute {
  attribute("maskUnits", value)
}

pub fn mask_content_units(value: String) -> Attribute {
  attribute("maskContentUnits", value)
}

pub fn clip_path_units(value: String) -> Attribute {
  attribute("clipPathUnits", value)
}

pub fn pattern_content_units(value: String) -> Attribute {
  attribute("patternContentUnits", value)
}

// === 필터 속성 ===

pub fn values(value: String) -> Attribute {
  attribute("values", value)
}

pub fn mode(value: String) -> Attribute {
  attribute("mode", value)
}

/// operator (Gleam 예약어 회피)
pub fn operator_(value: String) -> Attribute {
  attribute("operator", value)
}

pub fn k1(value: String) -> Attribute {
  attribute("k1", value)
}

pub fn k2(value: String) -> Attribute {
  attribute("k2", value)
}

pub fn k3(value: String) -> Attribute {
  attribute("k3", value)
}

pub fn k4(value: String) -> Attribute {
  attribute("k4", value)
}

pub fn scale(value: String) -> Attribute {
  attribute("scale", value)
}

pub fn x_channel_selector(value: String) -> Attribute {
  attribute("xChannelSelector", value)
}

pub fn y_channel_selector(value: String) -> Attribute {
  attribute("yChannelSelector", value)
}

// === 기타 SVG 속성 ===

pub fn color(value: String) -> Attribute {
  attribute("color", value)
}

pub fn display(value: String) -> Attribute {
  attribute("display", value)
}

pub fn enable_background(value: String) -> Attribute {
  attribute("enableBackground", value)
}

pub fn lighting_color(value: String) -> Attribute {
  attribute("lightingColor", value)
}
