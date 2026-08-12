/// Public API for the `rest_client_builder` package.
///
/// Exports annotations, core contracts (`RestResult`, `RestError`), and the Dio
/// runtime (`DioRestClient`, `RestPart`, cancel/progress, interceptors).
///
/// Code generation is provided via `build_runner` builders — import this library
/// in API/model sources, then run `dart run build_runner build`.
///
/// Implementation details under `src/generator/` and `src/internal/` are not
/// part of the public API.
library;

// Annotations — declarative surface for describing REST APIs.
export 'src/annotations/annotations.dart';

// Core — shared contracts, models, and domain primitives.
export 'src/core/core.dart';

// Runtime — helpers and clients used by generated and handwritten code.
export 'src/runtime/runtime.dart';

// Generator and internal modules are intentionally NOT exported.
