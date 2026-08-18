# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## 1.3.7

- **Restored compatibility with Flutter SDK `meta` 1.17.0 pin**:
  - Relaxed the `meta` dependency constraint from `^1.19.0` to `>=1.17.0 <2.0.0`.
  - Flutter stable SDKs (e.g. Flutter 3.38.x) pin `meta` to `1.17.0` via `flutter`/`flutter_test`. The previous tight constraint caused `pub get` to fail for consumers even though the package only uses `@Target`/`TargetKind` from `package:meta/meta_meta.dart` — both of which are fully available since `meta 1.15.0`.
  - No API changes. No `dependency_overrides` required by consumers.

---

## 1.3.6

- **Documentation & Example Improvements**:
  - Refined README examples with accurate import/export usage.
  - Corrected streaming download result handling using `.when()`.
  - Added documentation for missing `RestResult` combinators (`.flatMap()`, `.mapAsync()`, `.flatMapAsync()`, `.getOrElse()`).
  - Added full working examples for `RestClientBuilder` and queue management.
- **Code Quality**:
  - Resolved analyzer lints and removed unused generator imports.
  - Added missing documentation comments on public generator builder members.

---

## 1.3.5

- **Renamed to `@ResilientQueue` (`@OfflineQueue` preserved as alias)**:
  - Renamed primary annotation to `@ResilientQueue` to convey network stability, breakable connection resilience, rate limiting, and server error retries.
  - `@OfflineQueue` is supported as a backward-compatible typedef alias (`typedef OfflineQueue = ResilientQueue;`).
- **Status Code Trigger Configuration (`enqueueOnStatusCodes`)**:
  - Added `enqueueOnStatusCodes: List<int>` (e.g. `[502, 503, 504, 429]`) to specify HTTP status codes that automatically trigger queueing in `RestQueueInterceptor`.

---

## 1.3.4

### New Features

- **`@SSE` — Server-Sent Events Annotation (`Stream<SSEEvent>`)**:
  - Annotate API methods with `@SSE` to subscribe to live Server-Sent Event streams (`lib/src/annotations/http/sse_annotation.dart`).
  - Spec-compliant HTML §9.2 parser (`SseParser`) handling `data:`, `event:`, `id:`, `retry:`, comments (`:`), and multi-line data concatenation.
  - Direct `Stream<SSEEvent>` return type support without `Future` or `RestResult` wrapping.
  - Runtime execution support in `DioRestClient.executeSSE()`.

- **`@OfflineQueue` — Resilient Offline Request Queueing**:
  - Declarative `@OfflineQueue` annotation for auto-queueing failed requests on connection drop, timeout, or 5xx server error (`lib/src/annotations/queue/offline_queue_annotation.dart`).
  - `RestRequestQueue` in-memory queue engine with reactive live stream (`itemsStream`), item list (`items`), filtering/removal (`removeWhere`), and flush replay (`flush`).
  - `RestQueueInterceptor` for auto-enqueueing failed requests matching trigger rules.
  - Custom removal logic support via `RestQueueResolver`.

---

## 1.3.3

### New Features

- **`@HTTP` — Generic Custom HTTP Verb Annotation** (`lib/src/annotations/http/http_annotations.dart`):  
  Enables non-standard HTTP verbs beyond the built-in shortcuts (`@GET`, `@POST`, etc.).  
  Supports WebDAV (`REPORT`, `COPY`, `MOVE`, `LOCK`), CDN (`PURGE`), and any custom protocol verb.  
  The method string is automatically uppercased.  
  ```dart
  @HTTP('REPORT', '/analytics')
  Future<RestResult<Map<String, dynamic>>> report(@Body() Map<String, dynamic> q);
  ```

- **`@Streaming` — Streaming Response Annotation** (`lib/src/annotations/http/streaming_annotation.dart`):  
  Marks a method to receive the HTTP response body as a raw `Stream<List<int>>` without loading it into RAM.  
  Backed by Dio's `ResponseType.stream` under the hood.  
  Return type must be `Future<RestResult<Stream<List<int>>>>`.  
  Compile-time error if combined with `@Multipart` or `@FormUrlEncoded`.  
  ```dart
  @Streaming()
  @GET('/files/{id}')
  Future<RestResult<Stream<List<int>>>> downloadFile(@Path('id') String id);
  ```

- **`RestResponseMapper.mapStream()`**: New static mapper that extracts a `Stream<List<int>>` from a Dio `ResponseBody` (for real HTTP calls) or falls back to wrapping `bodyBytes`/`bodyString` into a single-chunk stream (for test clients and mocks).

### Improvements

- Visitor and writer updated to propagate `isStreaming` through the full code generation pipeline.
- Validator now rejects `@Streaming` methods that also declare `@Multipart` or `@FormUrlEncoded`.
- API docs table in generated files now shows `[streaming]` flag next to streamed endpoints.

---

## 1.3.2

- **Repository Migration:** Updated all repository, homepage, and package documentation references to the new Git repository `https://github.com/corevantdev/rest_client_builder`.
- **Unit Test Stability:** Updated outdated unit test assertions to match the new clean abstract class and generated `UserApiImpl` pattern.

## 1.3.1

- **Minor Refinements:** Internal documentation updates and dependency package adjustments.

## 1.3.0

- **Zero-Setup DX Top-Level Getters:** Automatically generates clean top-level getters (`demoApi`, `productApi`, `paymentApi`) so controllers can invoke APIs directly with zero `RestClient` management or dependency injection boilerplate.
- **Pure Abstract API Declarations:** Completely eliminated factory constructor requirements on `@RestApi()` classes.
- **In-Memory Response Caching (`@Cache`):** Added `@Cache(durationMs: ...)` annotation for class and method levels. Eliminates network roundtrips for cached responses via `RestResponseCache`.
- **Multi-Service & Microservice Architecture:** Flexible support for single shared socket connection pools, microservice custom base URLs, and dedicated isolated client pools (`@RestApi(configuration: ...)`).
- **Generator Variable Shadowing Fix:** Renamed internal request variable in generated code to prevent shadowing method parameter names (`request`, `body`, etc.).

## 1.2.1

- **Refactored Code Generation:** The builder now generates standalone `.g.dart` files, completely removing the need for `part` files.
- **Zero-Boilerplate Models:** Removed the requirement to manually define `fromJson`/`toJson` mappings inside your `@RestModel()` classes. 
- **Smart Imports:** API generation automatically detects dependencies and imports the necessary source and generated files.
- **Static Analysis & Dependencies:** Updated `analyzer`, `dio`, and other constraints. Addressed all static analysis warnings and documentation issues to achieve a perfect pub.dev score.

## 1.2.0

Initial stable release.

### Added

- `@RestApi` annotation-driven REST client code generation via `build_runner`.
- `@RestModel` JSON code generation (`fromJson` / `toJson`) with full `JsonKey` support.
- `RestResult<T>` sealed success/failure type with `when`, `fold`, `map`, `flatMap`,
  `mapAsync`, `flatMapAsync`, `getOrThrow`, and `getOrElse`.
- `RestError` transport-agnostic structured error with factory constructors:
  `unknown`, `validation`, `timeout`, `cancelled`, `connection`, `http`, and `serialization`.
- `DioRestClient` with retry, timeouts, header merging, logging, and interceptor resolution.
- `RestPart.fromBytes` / `RestPart.fromBase64` for web-safe multipart uploads (no `dart:io`).
- `BasicCancelToken` for cooperative cancellation with `isCancelled` / `whenCancelled`.
- `RestProgressCallback` for upload and download progress.
- `@UseInterceptor` / `@ExcludeInterceptor` per class or method.
- `@Retry`, `@ConnectTimeout`, `@ReceiveTimeout`, `@SendTimeout`, `@EnableLog` overrides
  at the global, API, and endpoint levels.
- Compile-time validation: duplicate routes, GET/HEAD + body, missing `@Path`,
  invalid multipart combinations, and invalid return types.
- `RestApiGlobalConfiguration` contract with `createRestClient()` factory (shared singleton)
  and `createFreshRestClient()` (isolated, for tests).
- `RestApiClientRegistry` for shared Dio connection-pool reuse.
- `CallbackRestClient` for easy unit testing without a network layer.
- `DefaultInterceptorPipeline` with forward-request / reverse-response / reverse-error order.
- `LoggingRestInterceptor` with sensitive-header redaction (`Authorization`, `Cookie`, etc.).
- Generated `ApiDocs.endpoints` list and dartdoc tables in every `*.rest.g.dart` file.
- `build.yaml` builder registration — no consumer `build.yaml` required.
- Full CRUD + multipart example under `example/`.
- 7 test suites covering core, runtime, validators, generator, and REST parts.
