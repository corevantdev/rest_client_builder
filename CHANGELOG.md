# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
