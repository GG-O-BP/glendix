// HTML 태그 편의 함수 - 순수 Gleam, FFI 없음
// react.element / react.element_ / react.void_element 래퍼

import glendix/react.{type ReactElement}
import glendix/react/attribute.{type Attribute}

// === 컨테이너 ===

pub fn div(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("div", attrs, children)
}

pub fn div_(children: List(ReactElement)) -> ReactElement {
  react.element_("div", children)
}

pub fn span(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("span", attrs, children)
}

pub fn span_(children: List(ReactElement)) -> ReactElement {
  react.element_("span", children)
}

pub fn section(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("section", attrs, children)
}

pub fn main(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("main", attrs, children)
}

pub fn header(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("header", attrs, children)
}

pub fn footer(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("footer", attrs, children)
}

pub fn nav(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("nav", attrs, children)
}

pub fn article(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("article", attrs, children)
}

pub fn aside(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("aside", attrs, children)
}

// === 텍스트 ===

pub fn p(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("p", attrs, children)
}

pub fn p_(children: List(ReactElement)) -> ReactElement {
  react.element_("p", children)
}

pub fn h1(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("h1", attrs, children)
}

pub fn h2(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("h2", attrs, children)
}

pub fn h3(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("h3", attrs, children)
}

pub fn h4(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("h4", attrs, children)
}

pub fn h5(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("h5", attrs, children)
}

pub fn h6(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("h6", attrs, children)
}

pub fn strong(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("strong", attrs, children)
}

pub fn em(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("em", attrs, children)
}

pub fn small(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("small", attrs, children)
}

pub fn pre(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("pre", attrs, children)
}

pub fn code(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("code", attrs, children)
}

// === 리스트 ===

pub fn ul(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("ul", attrs, children)
}

pub fn ol(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("ol", attrs, children)
}

pub fn li(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("li", attrs, children)
}

// === 폼 ===

pub fn form(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("form", attrs, children)
}

pub fn button(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("button", attrs, children)
}

pub fn label(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("label", attrs, children)
}

pub fn input(attrs: List(Attribute)) -> ReactElement {
  react.void_element("input", attrs)
}

pub fn textarea(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("textarea", attrs, children)
}

pub fn select(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("select", attrs, children)
}

pub fn option(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("option", attrs, children)
}

// === 테이블 ===

pub fn table(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("table", attrs, children)
}

pub fn thead(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("thead", attrs, children)
}

pub fn tbody(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("tbody", attrs, children)
}

pub fn tfoot(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("tfoot", attrs, children)
}

pub fn tr(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("tr", attrs, children)
}

pub fn td(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("td", attrs, children)
}

pub fn th(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("th", attrs, children)
}

// === 기타 ===

pub fn a(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("a", attrs, children)
}

pub fn img(attrs: List(Attribute)) -> ReactElement {
  react.void_element("img", attrs)
}

pub fn br(attrs: List(Attribute)) -> ReactElement {
  react.void_element("br", attrs)
}

pub fn hr(attrs: List(Attribute)) -> ReactElement {
  react.void_element("hr", attrs)
}

// === Tier 1: Mendix 위젯에서 자주 사용 ===

pub fn fieldset(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("fieldset", attrs, children)
}

pub fn legend(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("legend", attrs, children)
}

pub fn details(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("details", attrs, children)
}

pub fn summary(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("summary", attrs, children)
}

pub fn dialog(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("dialog", attrs, children)
}

pub fn progress(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("progress", attrs, children)
}

pub fn meter(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("meter", attrs, children)
}

pub fn figure(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("figure", attrs, children)
}

pub fn figcaption(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("figcaption", attrs, children)
}

pub fn blockquote(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("blockquote", attrs, children)
}

pub fn cite(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("cite", attrs, children)
}

pub fn iframe(attrs: List(Attribute)) -> ReactElement {
  react.void_element("iframe", attrs)
}

pub fn dl(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("dl", attrs, children)
}

pub fn dt(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("dt", attrs, children)
}

pub fn dd(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("dd", attrs, children)
}

// === Tier 2: 미디어/시맨틱 ===

pub fn video(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("video", attrs, children)
}

pub fn audio(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("audio", attrs, children)
}

pub fn source(attrs: List(Attribute)) -> ReactElement {
  react.void_element("source", attrs)
}

pub fn track(attrs: List(Attribute)) -> ReactElement {
  react.void_element("track", attrs)
}

pub fn picture(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("picture", attrs, children)
}

pub fn canvas(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("canvas", attrs, children)
}

pub fn abbr(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("abbr", attrs, children)
}

pub fn mark(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("mark", attrs, children)
}

pub fn del(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("del", attrs, children)
}

pub fn ins(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("ins", attrs, children)
}

pub fn sub(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("sub", attrs, children)
}

pub fn sup(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("sup", attrs, children)
}

pub fn time(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("time", attrs, children)
}

pub fn address(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("address", attrs, children)
}

pub fn output(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("output", attrs, children)
}

pub fn datalist(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("datalist", attrs, children)
}

pub fn optgroup(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("optgroup", attrs, children)
}

pub fn colgroup(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("colgroup", attrs, children)
}

pub fn col(attrs: List(Attribute)) -> ReactElement {
  react.void_element("col", attrs)
}

pub fn caption(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("caption", attrs, children)
}

// === Tier 3: 추가 텍스트/시맨틱/Void 요소 ===

/// 키보드 입력 표시
pub fn kbd(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("kbd", attrs, children)
}

/// 프로그램 출력 샘플 텍스트
pub fn samp(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("samp", attrs, children)
}

/// 변수/수학 표현식 (var → Gleam 예약어 회피)
pub fn var_(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("var", attrs, children)
}

/// 루비 주석 컨테이너 (CJK/한국어 발음 표기)
pub fn ruby(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("ruby", attrs, children)
}

/// 루비 텍스트 (발음/주석)
pub fn rt(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("rt", attrs, children)
}

/// 루비 대체 텍스트 (괄호 폴백)
pub fn rp(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("rp", attrs, children)
}

/// 양방향 텍스트 격리 (국제화)
pub fn bdi(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("bdi", attrs, children)
}

/// 양방향 텍스트 방향 재정의
pub fn bdo(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("bdo", attrs, children)
}

/// 기계 판독 가능 데이터 (data → Gleam 충돌 회피)
pub fn data_(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("data", attrs, children)
}

/// 검색 섹션
pub fn search(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("search", attrs, children)
}

/// 제목 그룹 (h1~h6 + p 묶음)
pub fn hgroup(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("hgroup", attrs, children)
}

/// 이미지 맵 (map → Gleam list.map 충돌 회피)
pub fn map_(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("map", attrs, children)
}

/// 줄바꿈 기회 (Void 요소)
pub fn wbr(attrs: List(Attribute)) -> ReactElement {
  react.void_element("wbr", attrs)
}

/// 외부 리소스 삽입 (Void 요소)
pub fn embed(attrs: List(Attribute)) -> ReactElement {
  react.void_element("embed", attrs)
}

/// 이미지 맵 영역 (Void 요소)
pub fn area(attrs: List(Attribute)) -> ReactElement {
  react.void_element("area", attrs)
}

// === Tier 4: 추가 인라인/구조 요소 ===

/// 볼드 텍스트
pub fn b(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("b", attrs, children)
}

/// 이탤릭 텍스트
pub fn i(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("i", attrs, children)
}

/// 취소선 텍스트
pub fn s(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("s", attrs, children)
}

/// 밑줄 텍스트
pub fn u(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("u", attrs, children)
}

/// 짧은 인용문
pub fn q(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("q", attrs, children)
}

/// 정의 용어
pub fn dfn(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("dfn", attrs, children)
}

/// 스크립트 미지원 시 대체 콘텐츠
pub fn noscript(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("noscript", attrs, children)
}

/// HTML 템플릿
pub fn template(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("template", attrs, children)
}

/// 웹 컴포넌트 슬롯
pub fn slot(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("slot", attrs, children)
}

/// 메뉴 요소
pub fn menu(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("menu", attrs, children)
}

// === 문서 구조 / 메타데이터 ===

/// HTML 루트 요소
pub fn html(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("html", attrs, children)
}

/// 문서 헤드
pub fn head(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("head", attrs, children)
}

/// 문서 본문
pub fn body(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.element("body", attrs, children)
}

/// 기본 URL (Void 요소)
pub fn base(attrs: List(Attribute)) -> ReactElement {
  react.void_element("base", attrs)
}

/// 리소스 링크 (Void 요소)
pub fn link(attrs: List(Attribute)) -> ReactElement {
  react.void_element("link", attrs)
}

/// 메타데이터 (Void 요소)
pub fn meta(attrs: List(Attribute)) -> ReactElement {
  react.void_element("meta", attrs)
}

/// 스크립트
pub fn script(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("script", attrs, children)
}

/// 인라인 스타일 시트 (attribute.style 충돌 회피)
pub fn style_el(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("style", attrs, children)
}

/// 문서 제목 (svg.title 충돌 회피)
pub fn title_el(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("title", attrs, children)
}

/// 외부 오브젝트 삽입
pub fn object(
  attrs: List(Attribute),
  children: List(ReactElement),
) -> ReactElement {
  react.element("object", attrs, children)
}
