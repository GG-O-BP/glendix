// HTML 속성 - List(Attribute) 기반 선언적 API
// className 자동 병합, none() 조건부 무시, style camelCase 변환 지원

import gleam/string
import glendix/react.{type Ref}

/// HTML/React 속성
pub type Attribute

// === 생성 ===

/// 범용 속성 생성 (escape hatch)
@external(javascript, "./attribute_ffi.mjs", "make_attribute")
pub fn attribute(key: String, content: a) -> Attribute

/// 조건부 속성 (렌더링 시 무시됨)
pub fn none() -> Attribute {
  attribute("none_", Nil)
}

// === 공통 HTML 속성 ===

pub fn id(value: String) -> Attribute {
  attribute("id", value)
}

/// className 설정 (여러 번 호출 시 자동 병합)
pub fn class(value: String) -> Attribute {
  attribute("className", value)
}

/// 여러 클래스명을 공백으로 결합
pub fn classes(values: List(String)) -> Attribute {
  attribute("className", string.join(values, " "))
}

pub fn href(value: String) -> Attribute {
  attribute("href", value)
}

pub fn src(value: String) -> Attribute {
  attribute("src", value)
}

pub fn alt(value: String) -> Attribute {
  attribute("alt", value)
}

pub fn type_(value: String) -> Attribute {
  attribute("type", value)
}

pub fn value(val: String) -> Attribute {
  attribute("value", val)
}

pub fn name(value: String) -> Attribute {
  attribute("name", value)
}

pub fn placeholder(value: String) -> Attribute {
  attribute("placeholder", value)
}

pub fn disabled(value: Bool) -> Attribute {
  attribute("disabled", value)
}

pub fn checked(value: Bool) -> Attribute {
  attribute("checked", value)
}

pub fn readonly(value: Bool) -> Attribute {
  attribute("readOnly", value)
}

pub fn required(value: Bool) -> Attribute {
  attribute("required", value)
}

pub fn hidden(value: Bool) -> Attribute {
  attribute("hidden", value)
}

pub fn selected(value: Bool) -> Attribute {
  attribute("selected", value)
}

pub fn multiple(value: Bool) -> Attribute {
  attribute("multiple", value)
}

pub fn autofocus(value: Bool) -> Attribute {
  attribute("autoFocus", value)
}

pub fn draggable(value: Bool) -> Attribute {
  attribute("draggable", value)
}

pub fn content_editable(value: Bool) -> Attribute {
  attribute("contentEditable", value)
}

pub fn min(value: String) -> Attribute {
  attribute("min", value)
}

pub fn max(value: String) -> Attribute {
  attribute("max", value)
}

pub fn step(value: String) -> Attribute {
  attribute("step", value)
}

pub fn rows(value: Int) -> Attribute {
  attribute("rows", value)
}

pub fn cols(value: Int) -> Attribute {
  attribute("cols", value)
}

pub fn tab_index(value: Int) -> Attribute {
  attribute("tabIndex", value)
}

pub fn col_span(value: Int) -> Attribute {
  attribute("colSpan", value)
}

pub fn row_span(value: Int) -> Attribute {
  attribute("rowSpan", value)
}

pub fn role(value: String) -> Attribute {
  attribute("role", value)
}

/// htmlFor 설정
pub fn for(value: String) -> Attribute {
  attribute("htmlFor", value)
}

pub fn target(value: String) -> Attribute {
  attribute("target", value)
}

pub fn action(value: String) -> Attribute {
  attribute("action", value)
}

pub fn method(value: String) -> Attribute {
  attribute("method", value)
}

pub fn accept(value: String) -> Attribute {
  attribute("accept", value)
}

pub fn autocomplete(value: String) -> Attribute {
  attribute("autoComplete", value)
}

pub fn width(value: String) -> Attribute {
  attribute("width", value)
}

pub fn height(value: String) -> Attribute {
  attribute("height", value)
}

pub fn title(value: String) -> Attribute {
  attribute("title", value)
}

/// aria-* 속성
pub fn aria(name: String, value: String) -> Attribute {
  attribute("aria-" <> name, value)
}

/// data-* 속성
pub fn data(name: String, value: String) -> Attribute {
  attribute("data-" <> name, value)
}

// === React 특수 속성 ===

pub fn key(value: String) -> Attribute {
  attribute("key", value)
}

pub fn ref(ref: Ref(a)) -> Attribute {
  attribute("ref", ref)
}

/// 인라인 스타일 (CSS 속성명 자동 camelCase 변환)
@external(javascript, "./attribute_ffi.mjs", "make_style_attribute")
pub fn style(styles: List(#(String, String))) -> Attribute

// === 추가 HTML 속성 ===

/// dangerouslySetInnerHTML 설정
@external(javascript, "./attribute_ffi.mjs", "make_inner_html")
pub fn dangerously_set_inner_html(html: String) -> Attribute

/// callback ref (DOM 요소 접근)
pub fn ref_(callback: fn(a) -> Nil) -> Attribute {
  attribute("ref", callback)
}

/// 리소스 로딩 전략 ("lazy" | "eager")
pub fn loading(value: String) -> Attribute {
  attribute("loading", value)
}

/// 다운로드 파일명
pub fn download(value: String) -> Attribute {
  attribute("download", value)
}

/// 링크 관계
pub fn rel(value: String) -> Attribute {
  attribute("rel", value)
}

/// <details> 열림 상태
pub fn open(value: Bool) -> Attribute {
  attribute("open", value)
}

/// 최대 입력 길이
pub fn max_length(value: Int) -> Attribute {
  attribute("maxLength", value)
}

/// 최소 입력 길이
pub fn min_length(value: Int) -> Attribute {
  attribute("minLength", value)
}

/// 입력 유효성 검증 패턴 (정규식)
pub fn pattern(value: String) -> Attribute {
  attribute("pattern", value)
}

/// select/input 크기
pub fn size(value: Int) -> Attribute {
  attribute("size", value)
}

/// 미디어 자동 재생
pub fn autoplay(value: Bool) -> Attribute {
  attribute("autoPlay", value)
}

/// 미디어 컨트롤 표시
pub fn controls(value: Bool) -> Attribute {
  attribute("controls", value)
}

/// 미디어 반복 재생
pub fn loop(value: Bool) -> Attribute {
  attribute("loop", value)
}

/// 미디어 음소거
pub fn muted(value: Bool) -> Attribute {
  attribute("muted", value)
}

/// 비제어 컴포넌트 기본값
pub fn default_value(value: String) -> Attribute {
  attribute("defaultValue", value)
}

/// 비제어 체크박스 기본 체크 상태
pub fn default_checked(value: Bool) -> Attribute {
  attribute("defaultChecked", value)
}

/// 폼 액션 URL
pub fn form_action(value: String) -> Attribute {
  attribute("formAction", value)
}

/// 폼 인코딩 타입
pub fn enctype(value: String) -> Attribute {
  attribute("encType", value)
}

/// 폼 유효성 검증 비활성화
pub fn no_validate(value: Bool) -> Attribute {
  attribute("noValidate", value)
}

/// iframe 샌드박스 정책
pub fn sandbox(value: String) -> Attribute {
  attribute("sandbox", value)
}

/// iframe 허용 기능 정책
pub fn allow(value: String) -> Attribute {
  attribute("allow", value)
}

/// 반응형 이미지 소스 세트
pub fn srcset(value: String) -> Attribute {
  attribute("srcSet", value)
}

/// 미디어 쿼리 조건
pub fn media(value: String) -> Attribute {
  attribute("media", value)
}

// === 추가 HTML 속성 (Round 2) ===

/// 가상 키보드 입력 모드 ("none" | "text" | "decimal" | "numeric" | "tel" | "search" | "email" | "url")
pub fn input_mode(value: String) -> Attribute {
  attribute("inputMode", value)
}

/// 요소 비활성화 (포커스/클릭/입력 불가)
pub fn inert(value: Bool) -> Attribute {
  attribute("inert", value)
}

/// 맞춤법 검사 활성화
pub fn spell_check(value: Bool) -> Attribute {
  attribute("spellCheck", value)
}

/// 번역 가능 여부 ("yes" | "no")
pub fn translate(value: String) -> Attribute {
  attribute("translate", value)
}

/// 요소 언어 코드 (BCP 47)
pub fn lang(value: String) -> Attribute {
  attribute("lang", value)
}

/// 텍스트 방향 ("ltr" | "rtl" | "auto")
pub fn dir(value: String) -> Attribute {
  attribute("dir", value)
}

/// textarea 줄바꿈 모드 ("soft" | "hard")
pub fn wrap(value: String) -> Attribute {
  attribute("wrap", value)
}

/// 연결할 form 요소 ID
pub fn form(value: String) -> Attribute {
  attribute("form", value)
}

/// 폼 제출 HTTP 메서드 (submit 버튼용)
pub fn form_method(value: String) -> Attribute {
  attribute("formMethod", value)
}

/// 폼 제출 대상 (submit 버튼용)
pub fn form_target(value: String) -> Attribute {
  attribute("formTarget", value)
}

/// datalist 연결 ID
pub fn list(value: String) -> Attribute {
  attribute("list", value)
}

/// 테이블 헤더 범위 ("row" | "col" | "rowgroup" | "colgroup")
pub fn scope(value: String) -> Attribute {
  attribute("scope", value)
}

/// 관련 헤더 셀 ID 목록
pub fn headers(value: String) -> Attribute {
  attribute("headers", value)
}

/// blockquote/del/ins/q 인용 소스 URL
pub fn cite_attr(value: String) -> Attribute {
  attribute("cite", value)
}

/// 변경 일시 (del/ins/time 요소)
pub fn datetime(value: String) -> Attribute {
  attribute("dateTime", value)
}

/// 비디오 포스터 이미지 URL
pub fn poster(value: String) -> Attribute {
  attribute("poster", value)
}

/// 미디어 사전 로드 정책 ("none" | "metadata" | "auto")
pub fn preload(value: String) -> Attribute {
  attribute("preload", value)
}

/// CORS 요청 모드 ("anonymous" | "use-credentials")
pub fn cross_origin(value: String) -> Attribute {
  attribute("crossOrigin", value)
}

/// 반응형 이미지 미디어 조건별 크기
pub fn sizes(value: String) -> Attribute {
  attribute("sizes", value)
}

/// 이미지 맵 좌표
pub fn coords(value: String) -> Attribute {
  attribute("coords", value)
}

/// 이미지 맵 영역 형태 ("rect" | "circle" | "poly" | "default")
pub fn shape(value: String) -> Attribute {
  attribute("shape", value)
}

/// contentEditable 경고 억제
pub fn suppress_content_editable_warning(value: Bool) -> Attribute {
  attribute("suppressContentEditableWarning", value)
}

/// 하이드레이션 경고 억제
pub fn suppress_hydration_warning(value: Bool) -> Attribute {
  attribute("suppressHydrationWarning", value)
}

// === 추가 HTML 속성 (Round 3) ===

/// 모바일 Enter 키 동작 ("enter" | "done" | "go" | "next" | "previous" | "search" | "send")
pub fn enter_key_hint(value: String) -> Attribute {
  attribute("enterKeyHint", value)
}

/// Popover API ("auto" | "manual")
pub fn popover(value: String) -> Attribute {
  attribute("popover", value)
}

/// Popover 대상 요소 ID
pub fn popover_target(value: String) -> Attribute {
  attribute("popoverTarget", value)
}

/// Popover 동작 ("show" | "hide" | "toggle")
pub fn popover_target_action(value: String) -> Attribute {
  attribute("popoverTargetAction", value)
}

/// 리소스 로딩 우선순위 ("high" | "low" | "auto")
pub fn fetch_priority(value: String) -> Attribute {
  attribute("fetchPriority", value)
}

/// 모바일 대문자 변환 ("none" | "sentences" | "words" | "characters")
pub fn auto_capitalize(value: String) -> Attribute {
  attribute("autoCapitalize", value)
}

/// 파일 입력 카메라 선택 ("user" | "environment")
pub fn capture_(value: String) -> Attribute {
  attribute("capture", value)
}

/// CSP nonce
pub fn nonce(value: String) -> Attribute {
  attribute("nonce", value)
}

// === 추가 HTML 속성 (Round 4) ===

/// <meta> content 속성
pub fn content(value: String) -> Attribute {
  attribute("content", value)
}

/// 키보드 단축키
pub fn access_key(value: String) -> Attribute {
  attribute("accessKey", value)
}

/// className 별칭 (class와 동일)
pub fn class_name(value: String) -> Attribute {
  attribute("className", value)
}

/// htmlFor 별칭 (for와 동일)
pub fn html_for(value: String) -> Attribute {
  attribute("htmlFor", value)
}

/// 텍스트 방향성 제출 이름
pub fn dirname(value: String) -> Attribute {
  attribute("dirName", value)
}

/// 성능 타이밍 측정 식별자
pub fn element_timing(value: String) -> Attribute {
  attribute("elementTiming", value)
}

/// Shadow DOM 파트 내보내기
pub fn export_parts(value: String) -> Attribute {
  attribute("exportParts", value)
}

/// 커스텀 요소 사양
pub fn is(value: String) -> Attribute {
  attribute("is", value)
}

/// 마이크로데이터 항목 ID
pub fn item_id(value: String) -> Attribute {
  attribute("itemId", value)
}

/// 마이크로데이터 속성명
pub fn item_prop(value: String) -> Attribute {
  attribute("itemProp", value)
}

/// 마이크로데이터 참조 ID
pub fn item_ref(value: String) -> Attribute {
  attribute("itemRef", value)
}

/// 마이크로데이터 범위 설정
pub fn item_scope(value: String) -> Attribute {
  attribute("itemScope", value)
}

/// 마이크로데이터 타입 URL
pub fn item_type(value: String) -> Attribute {
  attribute("itemType", value)
}

/// 폼 문자 인코딩
pub fn accept_charset(value: String) -> Attribute {
  attribute("acceptCharset", value)
}

/// 버튼 폼 인코딩 타입
pub fn form_enctype(value: String) -> Attribute {
  attribute("formEnctype", value)
}

/// 버튼 폼 유효성 검증 비활성화
pub fn form_no_validate(value: Bool) -> Attribute {
  attribute("formNoValidate", value)
}

/// CSS Shadow Parts 노출
pub fn part(value: String) -> Attribute {
  attribute("part", value)
}

/// 웹 컴포넌트 슬롯 이름
pub fn slot(value: String) -> Attribute {
  attribute("slot", value)
}
