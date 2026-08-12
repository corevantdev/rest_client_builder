# RestApiBuilder

A Clean Architecture code-generation framework for typed REST API clients in **Dart** and **Flutter** — powered by annotations and `build_runner`.

Declare endpoints once. Call generated type-safe clients directly (`userService.getUser('1')`) returning `RestResult<T>`, running on **Dio**, with zero client management in your controllers.

> **Status:** Production-ready. Includes Dio runtime, TCP socket connection pooling, compile-time validation, multipart uploads, interceptors, cancel/progress, `@RestModel` / `@RestApi` codegen, and a full example app.

---

## Features

- **Zero-Boilerplate Invocation**: Call APIs directly via top-level getters (`userService.getUser('1')`) with **zero** `RestClient` or `Dio` setup in your controllers.
- **Built-In Connection Pooling**: Automatic HTTP Keep-Alive and TCP socket reuse for maximum speed.
- **Microservices & Multi-Domain**: Support for multiple microservices via `@RestApi(baseUrl: ...)` or dedicated isolated configuration via `@RestApi(configuration: ...)`.
- **Functional Result Type**: Strongly-typed `RestResult<T>` with `.fold()`, `.when()`, `.map()`, and `.getOrThrow()` — perfect for GetX, Bloc, and Provider.
- **`@RestModel` JSON Codegen**: Declarative `fromJson` / `toJson` generation with `JsonKey` support.
- **Memory-Safe Multipart**: `RestPart.fromBytes` / `RestPart.fromBase64` (web & Flutter friendly, no `dart:io` `File` dependency).
- **Cancel & Progress Callbacks**: Built-in `CancelToken`, `onSendProgress`, and `onReceiveProgress`.
- **Interceptors & Security**: Class-level or method-level `@UseInterceptor` and `@ExcludeInterceptor`.
- **Compile-Time Safety**: Fails at `build_runner` build time on invalid route syntax, GET+Body, missing path placeholders, or invalid multipart settings.

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  rest_client_builder: ^1.3.0

dev_dependencies:
  build_runner: ^2.4.15
```

For local package development:

```yaml
dependencies:
  rest_client_builder:
    path: ../rest_client_builder
```

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
# or watch mode:
dart run build_runner watch --delete-conflicting-outputs
```

All generated files land centrally under `lib/rest_client_builder/`, preserving your project's folder structure.

| Builder | Generated Output |
|---------|------------------|
| `rest_model` | `lib/rest_client_builder/.../file.g.dart` |
| `rest_api` | `lib/rest_client_builder/.../file.rest.g.dart` |
| `rest_configuration` | `lib/rest_client_builder/.../file.rest.config.g.dart` |

---

## Quick Start (4 Steps)

### Step 1: Define your Model

Annotate a standard class with `@RestModel()`. The generator produces all serialization code automatically.

```dart
// lib/models/user.dart
import 'package:rest_client_builder/rest_client_builder.dart';

export '../rest_client_builder/models/user.g.dart';

@RestModel()
class User {
  const User({required this.id, required this.name});

  final String id;

  @JsonKey(name: 'user_name')
  final String name;
}
```

### Step 2: Define your API

Write a pure abstract class annotated with `@RestApi()`. Define your endpoints using `@GET`, `@POST`, `@PUT`, `@DELETE`, etc.

```dart
// lib/api/user_service.dart
import 'package:rest_client_builder/rest_client_builder.dart';
import '../models/user.dart';

import '../rest_client_builder/api/user_service.rest.g.dart';
export '../rest_client_builder/api/user_service.rest.g.dart';

@RestApi(baseUrl: 'https://api.example.com')
abstract class UserService {
  @GET('/users/{id}')
  Future<RestResult<User>> getUser(@Path('id') String id);

  @POST('/users')
  Future<RestResult<User>> createUser(@Body() User user);
}
```

### Step 3: Run the Code Generator

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 4: Call Endpoints in your Controllers

Call your API using the generated top-level getter (`userService`). **No `RestClient` creation or dependency injection setup required!**

```dart
class UserController extends GetxController {
  Future<void> fetchUser(String id) async {
    // 100% clean — uses shared client & connection pool internally!
    final result = await userService.getUser(id);

    result.fold(
      (error) => Get.snackbar('Error', error.message),
      (user)  => userState.value = user,
    );
  }
}
```

---

## Multi-Service & Microservice Architecture

`rest_api_builder` supports multi-domain microservice architectures while managing client connections efficiently:

### Option 1: Single Shared Client (Default — Recommended for Main API)
Omit `configuration` to share the primary application connection pool across endpoints.

```dart
@RestApi(baseUrl: 'https://api.example.com')
abstract class MainApi { ... }
```

### Option 2: Microservice Base URL (Shared Connection Pool)
Target a separate microservice domain while **reusing the existing process-wide socket pool**:

```dart
@RestApi(baseUrl: 'https://product-service.com')
abstract class ProductApi {
  @GET('/products')
  Future<RestResult<List<Product>>> listProducts();
}
```

### Option 3: Dedicated Configuration (Isolated Connection Pool)
For services requiring isolated security policies, custom timeouts, or 0 retries (e.g. Payments), annotate with a dedicated `@RestConfiguration`:

```dart
@RestApi(
  baseUrl: 'https://payment-service.com',
  configuration: PaymentRestConfiguration,
)
abstract class PaymentApi {
  @POST('/charge')
  Future<RestResult<ChargeResponse>> charge(@Body() ChargeRequest request);
}
```

---

## Response Caching (`@Cache`)

Eliminate unnecessary network requests for slow-changing APIs (e.g. products, categories, master data) using `@Cache`:

```dart
@RestApi(baseUrl: 'https://product-service.com')
abstract class ProductApi {
  // Caches response in memory for 60 seconds (60,000 ms)
  @GET('/products')
  @Cache(durationMs: 60000)
  Future<RestResult<List<Product>>> listProducts();
}
```

- **Method level or Class level**: Annotate an entire `@RestApi` class or individual method.
- **Zero Network Overhead**: Hits in-memory `RestResponseCache` instantly without sending HTTP requests.
- **Manual Clear**: Call `RestResponseCache.clear()` to invalidate all cached data (e.g. after user logout).

---

## Result Handling (`RestResult<T>`)

Endpoints return `Future<RestResult<T>>` instead of throwing raw exceptions. Match or transform results declaratively:

```dart
final result = await userService.getUser('1');

// 1. .fold() — handle failure and success branches:
final userName = result.fold(
  (error) => 'Guest',
  (user)  => user.name,
);

// 2. .when() — named callback dispatch:
result.when(
  success: (user)  => print('Found: ${user.name}'),
  failure: (error) => print('Failed: ${error.message}'),
);

// 3. .map() / .flatMap() — transform payloads:
final greeting = result.map((user) => 'Hello, ${user.name}!');

// 4. Quick property access:
final userOrNull  = result.dataOrNull;
final errorOrNull = result.errorOrNull;

// 5. Throw explicit RestError when expected:
final user = result.getOrThrow();
```

---

## Interceptors & Async Auth Tokens

Do not pass static tokens into base configurations: they become stale upon login or refresh. Attach global interceptors to load tokens asynchronously before every request:

```dart
class AuthInterceptor implements RestInterceptor {
  @override
  Future<RestRequest> onRequest(RestRequest request) async {
    final token = await secureStorage.read(key: 'access_token');
    if (token == null || token.isEmpty || request is! BasicRestRequest) {
      return request;
    }
    return request.copyWith(headers: {
      ...request.headers,
      'Authorization': 'Bearer $token',
    });
  }

  @override
  Future<RestResponse> onResponse(RestResponse response) async => response;

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async =>
      Failure(error);
}
```

Annotate endpoints or API classes to use or exclude interceptors:

```dart
@RestApi(baseUrl: 'https://api.example.com')
@UseInterceptor([AuthInterceptor])
abstract class DemoApi {
  // Login endpoint excludes auth header:
  @POST('/login')
  @FormUrlEncoded()
  @ExcludeInterceptor([AuthInterceptor])
  Future<RestResult<User>> login(@Field('email') String email, @Field('password') String password);
}
```

---

## Multipart Uploads & Progress

Upload files safely across Flutter Web, Mobile, and Desktop using memory-backed `RestPart`:

```dart
@POST('/avatar')
@Multipart()
Future<RestResult<User>> uploadAvatar(
  @Part(name: 'file') RestPart file,
  @Part(name: 'label') String label, {
  @Cancel() CancelToken? cancelToken,
  RestProgressCallback? onSendProgress,
});
```

Calling the upload endpoint:

```dart
final cancelToken = BasicCancelToken();
final bytes = await imageFile.readAsBytes();

final part = RestPart.fromBytes(
  name: 'file',
  bytes: bytes,
  fileName: 'avatar.png',
  contentType: 'image/png',
);

final result = await userService.uploadAvatar(
  part,
  'profile',
  cancelToken: cancelToken,
  onSendProgress: (sent, total) => print('Upload: $sent/$total'),
);
```

---

## Project Structure

```
rest_client_builder/
├── lib/
│   ├── rest_client_builder.dart      # Public barrel import
│   └── src/
│       ├── annotations/           # @RestApi, @RestModel, HTTP verb annotations
│       ├── core/                  # RestResult, RestError, utilities
│       ├── runtime/               # Dio execution runtime, interceptors, multipart
│       └── generator/             # Code generation logic & validators
├── example/                       # Production-style consumer example app
└── test/                          # Unit & generator tests
```

---

## License

MIT License — free for commercial and open-source use.
