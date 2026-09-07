//// Provides binding operations for Glendix.
////
//// ```gleam
//// import gleam/result
//// import glendix/binding
//// import redraw
//// import redraw/dom/attribute
////
//// pub fn pie_chart(
////   attrs attrs: List(attribute.Attribute),
////   children children: List(redraw.Element),
//// ) -> Result(redraw.Element, binding.BindingError) {
////   use module <- result.try(binding.module("recharts"))
////   use component <- result.try(binding.resolve(module, "PieChart"))
////   Ok(binding.element(component, attrs, children))
//// }
//// ```

import gleam/javascript/promise
import gleam/option
import gleam/result
import glendix/js/promise as glendix_promise
import lustre/effect
import redraw
import redraw/dom/attribute

/// A typed `JsModule` value used by the binding capability.
pub type JsModule

/// Represents one JavaScript component exported by a configured module.
pub type JsComponent

/// Describes a missing JavaScript binding.
pub type BindingError {
  /// The requested JavaScript module is not registered.
  ModuleWasNotFound(name: String, reason: String)
  /// The requested export is not available from the module.
  ExportWasNotFound(name: String, reason: String)
}

/// Describes a configured module initialization failure.
pub type InitializationError {
  /// The configured initializer could not be invoked as a Promise operation.
  InitializationCouldNotStart(
    module_name: String,
    export_name: String,
    reason: String,
  )
  /// The initializer Promise rejected before the module became ready.
  InitializationRejected(
    module_name: String,
    export_name: String,
    reason: String,
  )
}

/// Reports the current caller-owned module initialization phase.
pub type InitializationStatus {
  /// The configured initializer has not started.
  Uninitialized
  /// One initializer Promise is currently shared by every consumer.
  Initializing
  /// The module is safe for rendering and non-React API use.
  Ready
  /// The most recent initialization attempt failed.
  Failed(error: InitializationError)
}

/// Caller-owned one-flight state for one configured JavaScript module.
pub opaque type ModuleInitialization {
  ModuleInitialization(
    module: JsModule,
    module_name: String,
    export_name: String,
    failure_policy: InitializationFailurePolicy,
    phase: InitializationPhase,
  )
}

/// Returns a JavaScript module handle by name.
pub fn module(name name: String) -> Result(JsModule, BindingError) {
  module_raw(name)
  |> result.map_error(fn(error) {
    ModuleWasNotFound(name: name, reason: raw_binding_error_message(error))
  })
}

/// Resolves an exported JavaScript value from a module handle.
pub fn resolve(
  module module: JsModule,
  name name: String,
) -> Result(JsComponent, BindingError) {
  resolve_raw(module, name)
  |> result.map_error(fn(error) {
    ExportWasNotFound(name: name, reason: raw_binding_error_message(error))
  })
}

/// Creates caller-owned initialization state for a configured module.
///
/// Modules without an initializer begin in `Ready`; configured initializers
/// begin in `Uninitialized`.
pub fn initialization(module module: JsModule) -> ModuleInitialization {
  let module_name = module_name_raw(module)
  let export_name = initialization_export_name_raw(module)
  let failure_policy = case initialization_retry_policy_raw(module) {
    "on-failure" -> RetryFailure
    _ -> CacheFailure
  }
  let phase = case export_name {
    "" -> InitializationReady
    _ -> InitializationUninitialized
  }
  ModuleInitialization(
    module: module,
    module_name: module_name,
    export_name: export_name,
    failure_policy: failure_policy,
    phase: phase,
  )
}

/// Reports the current phase without exposing the shared Promise.
pub fn initialization_status(
  initialization initialization: ModuleInitialization,
) -> InitializationStatus {
  let ModuleInitialization(phase: phase, ..) = initialization
  case phase {
    InitializationUninitialized -> Uninitialized
    InitializationInitializing(_) -> Initializing
    InitializationReady -> Ready
    InitializationFailed(error) -> Failed(error)
  }
}

/// Starts or reuses the module's one-flight initialization attempt.
///
/// The returned lifecycle must replace the caller's previous value. A caller
/// records the Promise result with `settle_initialization` before starting a
/// later retry.
pub fn initialize(
  initialization initialization: ModuleInitialization,
) -> #(ModuleInitialization, promise.Promise(Result(Nil, InitializationError))) {
  let ModuleInitialization(failure_policy: failure_policy, phase: phase, ..) =
    initialization
  case phase {
    InitializationUninitialized -> start_initialization(initialization)
    InitializationInitializing(attempt) -> #(initialization, attempt)
    InitializationReady -> #(initialization, promise.resolve(Ok(Nil)))
    InitializationFailed(error) ->
      case failure_policy {
        CacheFailure -> #(initialization, promise.resolve(Error(error)))
        RetryFailure -> start_initialization(initialization)
      }
  }
}

/// Records one attempt's completion in caller-owned lifecycle state.
///
/// Calls outside `Initializing` are ignored so duplicate or stale completion
/// messages cannot replace an already-settled state.
pub fn settle_initialization(
  initialization initialization: ModuleInitialization,
  with outcome: Result(Nil, InitializationError),
) -> ModuleInitialization {
  let ModuleInitialization(phase: phase, ..) = initialization
  case phase {
    InitializationInitializing(_) ->
      case outcome {
        Ok(Nil) -> with_phase(initialization, InitializationReady)
        Error(error) -> with_phase(initialization, InitializationFailed(error))
      }
    InitializationUninitialized
    | InitializationReady
    | InitializationFailed(_) -> initialization
  }
}

/// Resets a settled configured initializer for an explicit later attempt.
///
/// An in-flight attempt is never reset because its eventual completion would
/// otherwise race a newer attempt. Modules without an initializer remain ready.
pub fn reset_initialization(
  initialization initialization: ModuleInitialization,
) -> ModuleInitialization {
  let ModuleInitialization(export_name: export_name, phase: phase, ..) =
    initialization
  case export_name, phase {
    "", _ -> initialization
    _, InitializationInitializing(_) -> initialization
    _, InitializationUninitialized -> initialization
    _, InitializationReady | _, InitializationFailed(_) ->
      with_phase(initialization, InitializationUninitialized)
  }
}

/// Returns the module only after it is ready for every configured consumer.
pub fn initialized_module(
  initialization initialization: ModuleInitialization,
) -> option.Option(JsModule) {
  let ModuleInitialization(module: module, phase: phase, ..) = initialization
  case phase {
    InitializationReady -> option.Some(module)
    InitializationUninitialized
    | InitializationInitializing(_)
    | InitializationFailed(_) -> option.None
  }
}

/// Starts or reuses initialization and dispatches its result as a Lustre effect.
pub fn initialization_effect(
  initialization initialization: ModuleInitialization,
  to_message to_message: fn(Result(Nil, InitializationError)) -> message,
) -> #(ModuleInitialization, effect.Effect(message)) {
  let #(next, attempt) = initialize(initialization)
  let initialization_effect =
    effect.from(fn(dispatch) {
      glendix_promise.await_(attempt, then: fn(outcome) {
        dispatch(to_message(outcome))
      })
    })
  #(next, initialization_effect)
}

/// Reads an initialization attempt from a React Suspense boundary.
///
/// Store the lifecycle returned by `initialize` outside the render call so
/// rerenders reuse the same attempt.
pub fn use_initialization(
  attempt attempt: promise.Promise(Result(Nil, InitializationError)),
) -> Result(Nil, InitializationError) {
  redraw.use_promise(attempt)
}

/// Creates an element from an external component, attributes, and children.
pub fn element(
  component component: JsComponent,
  attributes attributes: List(attribute.Attribute),
  children children: List(redraw.Element),
) -> redraw.Element {
  element_raw(component, attributes, children)
}

/// Creates an element from an external component and children.
pub fn element_(
  component component: JsComponent,
  children children: List(redraw.Element),
) -> redraw.Element {
  element_without_attributes_raw(component, children)
}

/// Creates an element from an external component without children.
pub fn void_element(
  component component: JsComponent,
  attributes attributes: List(attribute.Attribute),
) -> redraw.Element {
  void_element_raw(component, attributes)
}

type RawBindingError

type InitializationFailurePolicy {
  CacheFailure
  RetryFailure
}

type InitializationPhase {
  InitializationUninitialized
  InitializationInitializing(promise.Promise(Result(Nil, InitializationError)))
  InitializationReady
  InitializationFailed(InitializationError)
}

fn start_initialization(
  initialization: ModuleInitialization,
) -> #(ModuleInitialization, promise.Promise(Result(Nil, InitializationError))) {
  let ModuleInitialization(
    module: module,
    module_name: module_name,
    export_name: export_name,
    ..,
  ) = initialization
  case initialize_module_raw(module) {
    Error(raw_error) -> {
      let error =
        InitializationCouldNotStart(
          module_name: module_name,
          export_name: export_name,
          reason: raw_binding_error_message(raw_error),
        )
      #(
        with_phase(initialization, InitializationFailed(error)),
        promise.resolve(Error(error)),
      )
    }
    Ok(initializer_promise) -> {
      let attempt =
        initializer_promise
        |> promise.map(fn(_) { Ok(Nil) })
        |> glendix_promise.catch_(with: fn(rejection) {
          promise.resolve(
            Error(InitializationRejected(
              module_name: module_name,
              export_name: export_name,
              reason: promise_rejection_message_raw(rejection),
            )),
          )
        })
      #(
        with_phase(initialization, InitializationInitializing(attempt)),
        attempt,
      )
    }
  }
}

fn with_phase(
  initialization: ModuleInitialization,
  phase: InitializationPhase,
) -> ModuleInitialization {
  let ModuleInitialization(
    module: module,
    module_name: module_name,
    export_name: export_name,
    failure_policy: failure_policy,
    ..,
  ) = initialization
  ModuleInitialization(
    module: module,
    module_name: module_name,
    export_name: export_name,
    failure_policy: failure_policy,
    phase: phase,
  )
}

// -- FFI --
@external(javascript, "./binding_ffi.mjs", "get_module")
fn module_raw(name name: String) -> Result(JsModule, RawBindingError)

@external(javascript, "./binding_ffi.mjs", "resolve")
fn resolve_raw(
  module module: JsModule,
  name name: String,
) -> Result(JsComponent, RawBindingError)

@external(javascript, "./binding_ffi.mjs", "module_name")
fn module_name_raw(module: JsModule) -> String

@external(javascript, "./binding_ffi.mjs", "initialization_export_name")
fn initialization_export_name_raw(module: JsModule) -> String

@external(javascript, "./binding_ffi.mjs", "initialization_retry_policy")
fn initialization_retry_policy_raw(module: JsModule) -> String

@external(javascript, "./binding_ffi.mjs", "initialize_module")
fn initialize_module_raw(
  module: JsModule,
) -> Result(promise.Promise(Nil), RawBindingError)

@external(javascript, "./binding_ffi.mjs", "component_element")
fn element_raw(
  component: JsComponent,
  attributes: List(attribute.Attribute),
  children: List(redraw.Element),
) -> redraw.Element

@external(javascript, "./binding_ffi.mjs", "component_element_without_attributes")
fn element_without_attributes_raw(
  component: JsComponent,
  children: List(redraw.Element),
) -> redraw.Element

@external(javascript, "./binding_ffi.mjs", "void_component_element")
fn void_element_raw(
  component: JsComponent,
  attributes: List(attribute.Attribute),
) -> redraw.Element

@external(javascript, "./binding_ffi.mjs", "binding_error_message")
fn raw_binding_error_message(error: RawBindingError) -> String

@external(javascript, "./binding_ffi.mjs", "binding_error_message")
fn promise_rejection_message_raw(
  rejection: glendix_promise.PromiseRejection,
) -> String
