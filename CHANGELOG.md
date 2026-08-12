# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
