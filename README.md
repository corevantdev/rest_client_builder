# RestClientBuilder

A Clean Architecture code-generation framework for typed REST API clients in **Dart** and **Flutter** — powered by annotations and `build_runner`.

Declare endpoints once. Call generated type-safe clients directly (`userService.getUser('1')`) returning `RestResult<T>`, running on **Dio**, with zero client management in your controllers.

> **Status:** Production-ready. Includes Dio runtime, TCP socket connection pooling, compile-time validation, multipart uploads, interceptors, cancel/progress, `@RestModel` / `@RestApi` codegen, and a full example app.

---

## Features

- **Zero-Boilerplate Invocation**: Call APIs directly via top-level getters (`userService.getUser('1')`) with **zero** `RestClient` or `Dio` setup in your controllers.
- **Built-In Connection Pooling**: Automatic HTTP Keep-Alive and TCP socket reuse for maximum speed.
- **Microservices & Multi-Domain**: Support for multiple microservices via `@RestApi(baseUrl: ...)` or dedicated isolated configuration via `@RestApi(configuration: ...)`.
- **Functional Result Type**: Strongly-typed `RestResult<T>` with `.fold()`, `.when()`, `.map()`, `.flatMap()`, `.mapAsync()`, `.flatMapAsync()`, and `.getOrThrow()` — perfect for GetX, Bloc, and Provider.
- **`@RestModel` JSON Codegen**: Declarative `fromJson` / `toJson` generation with `JsonKey` support.
- **Memory-Safe Multipart**: `RestPart.fromBytes` / `RestPart.fromBase64` (web & Flutter friendly, no `dart:io` `File` dependency).
- **Cancel & Progress Callbacks**: Built-in `CancelToken`, `onSendProgress`, and `onReceiveProgress`.
- **Interceptors & Security**: Class-level or method-level `@UseInterceptor` and `@ExcludeInterceptor`.
- **Response Caching**: In-memory `@Cache` annotation with configurable TTL per method or class.
- **Custom HTTP Verbs (`@HTTP`)**: Beyond `@GET`/`@POST` — support WebDAV (`REPORT`, `COPY`, `LOCK`), CDN (`PURGE`), and any custom protocol verb.
- **Streaming Downloads (`@Streaming`)**: Receive large files/video as a raw `Stream<List<int>>` without buffering into RAM.
- **Server-Sent Events (`@SSE`)**: Subscribe to live HTTP event streams with zero boilerplate.
- **Resilient Request Queue**: Automatically save and replay failed requests when network drops, with `@ResilientQueue` / `@OfflineQueue`.
- **Compile-Time Safety**: Fails at `build_runner` build time on invalid route syntax, GET+Body, missing path placeholders, or invalid multipart settings.

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  rest_client_builder: ^1.3.6

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

## Quick Start (5 Steps)

### Step 1: Define your Configuration

Create a class annotated with `@RestConfiguration()` that implements `RestApiGlobalConfiguration`.

```dart
// lib/core/app_config.dart
import 'package:rest_client_builder/rest_client_builder.dart';

@RestConfiguration()
class AppRestConfiguration implements RestApiGlobalConfiguration {
  @override
  final String baseUrl = 'https://api.example.com';

  @override
  final Map<String, String> headers = const {
    'Accept': 'application/json',
  };

  @override
  final int? retryMaxAttempts = 3;

  @override
  final int? retryDelayMs = 200;

  @override
  final List<int>? retryStatusCodes = const [502, 503];

  @override
  final int? connectTimeoutMs = 10000;

  @override
  final int? receiveTimeoutMs = 30000;

  @override
  final int? sendTimeoutMs = 15000;

  @override
  final bool? enableLog = true;

  @override
  final List<RestInterceptor> interceptors = const [];
}
```

### Step 2: Define your Model

Annotate a standard class with `@RestModel()`. The generator produces all serialization code automatically.

```dart
// lib/models/user.dart
import 'package:rest_client_builder/rest_client_builder.dart';

@RestModel()
class User {
  const User({required this.id, required this.name});

  final String id;

  @JsonKey(name: 'user_name')
  final String name;
}
```

### Step 3: Define your API

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

### Step 4: Run the Code Generator

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 5: Call Endpoints in your Controllers

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

`rest_client_builder` supports multi-domain microservice architectures while managing client connections efficiently:

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
// lib/core/payment_config.dart
@RestConfiguration()
class PaymentRestConfiguration implements RestApiGlobalConfiguration {
  @override
  final String baseUrl = 'https://payment-service.com';

  @override
  final Map<String, String> headers = const {
    'Accept': 'application/json',
    'X-Payment-Version': 'v2',
  };

  @override
  final int? retryMaxAttempts = 1; // Never retry payment calls

  @override
  final int? retryDelayMs = 0;

  @override
  final List<int>? retryStatusCodes = const [];

  @override
  final int? connectTimeoutMs = 5000;

  @override
  final int? receiveTimeoutMs = 15000;

  @override
  final int? sendTimeoutMs = 15000;

  @override
  final bool? enableLog = true;

  @override
  final List<RestInterceptor> interceptors = const [];
}

// lib/api/payment_api.dart
@RestApi(
  baseUrl: 'https://payment-service.com',
  configuration: PaymentRestConfiguration,
)
abstract class PaymentApi {
  @POST('/charge')
  Future<RestResult<ChargeResponse>> charge(@Body() ChargeRequest request);
}
```

Calling `paymentApi.charge(...)` automatically routes through `PaymentRestConfiguration`'s isolated connection pool — **zero client setup required**.

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
- **Default TTL**: 300,000 ms (5 minutes) when `durationMs` is omitted.
- **Manual Clear**: Call `RestResponseCache.clear()` to invalidate all cached data (e.g. after user logout).

---

## Result Handling (`RestResult<T>`)

Endpoints return `Future<RestResult<T>>` instead of throwing raw exceptions. Match or transform results declaratively:

```dart
final result = await userService.getUser('1');

// 1. .fold() — positional: failure first, then success (like Either):
final userName = result.fold(
  (error) => 'Guest',
  (user)  => user.name,
);

// 2. .when() — named callback dispatch (reads more clearly):
result.when(
  success: (user)  => print('Found: ${user.name}'),
  failure: (error) => print('Failed: ${error.message}'),
);

// 3. .map() — synchronously transform the success value:
final greeting = result.map((user) => 'Hello, ${user.name}!');

// 4. .flatMap() — chain another RestResult-returning operation:
final order = result.flatMap((user) => orderRepo.findByUser(user.id));

// 5. .mapAsync() / .flatMapAsync() — async transform / chain:
final profile = await result.mapAsync((user) => profileRepo.get(user.id));
final order   = await result.flatMapAsync((user) => orderRepo.submit(user));

// 6. .getOrElse() — return success value, or a default on failure:
final user = result.getOrElse(() => User.guest());

// 7. Quick property access:
final userOrNull  = result.dataOrNull;
final errorOrNull = result.errorOrNull;

// 8. Throw explicit RestError when expected:
final user = result.getOrThrow();
```

---

## Interceptors & Async Auth Tokens

Do not pass static tokens into base configurations: they become stale upon login or refresh. Attach global interceptors to load tokens asynchronously before every request:

```dart
class AuthInterceptor implements RestInterceptor {
  AuthInterceptor({Future<String?> Function()? tokenReader})
      : _tokenReader = tokenReader;

  final Future<String?> Function()? _tokenReader;

  @override
  Future<RestRequest> onRequest(RestRequest request) async {
    final token = _tokenReader == null ? null : await _tokenReader!();
    if (token == null || token.isEmpty) return request;
    if (request is BasicRestRequest) {
      return request.copyWith(headers: {
        ...request.headers,
        'Authorization': 'Bearer $token',
      });
    }
    return request;
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

## Custom HTTP Verbs (`@HTTP`)

For protocols and standards beyond the standard verbs — WebDAV, CDN purges, IETF extensions — use `@HTTP`:

```dart
@RestApi(baseUrl: 'https://api.example.com')
abstract class AdminApi {
  /// WebDAV: query collection metadata.
  @HTTP('REPORT', '/users/analytics')
  Future<RestResult<Map<String, dynamic>>> reportAnalytics(
    @Body() Map<String, dynamic> query,
  );

  /// CDN: purge a cached resource.
  @HTTP('PURGE', '/cache/{key}')
  Future<RestResult<void>> purgeCache(@Path('key') String key);

  /// Copy a document (WebDAV).
  @HTTP('COPY', '/docs/{id}')
  Future<RestResult<void>> copyDoc(
    @Path('id') String id,
    @Header('Destination') String destination,
  );
}
```

- **Method string is auto-uppercased**: `@HTTP('get', ...)` → sends `GET`.
- **All standard parameter annotations work**: `@Body`, `@Path`, `@Query`, `@Header`, `@Part`, `@Field`, etc.
- **`@Multipart` and `@FormUrlEncoded` supported** on `@HTTP` methods just like standard verbs.

---

## Streaming Downloads (`@Streaming`)

For large files, videos, or byte streams where buffering the entire body into RAM is not acceptable:

```dart
@RestApi(baseUrl: 'https://cdn.example.com')
abstract class FileApi {
  /// Download a file as a raw byte stream (zero-copy, memory-efficient).
  @Streaming()
  @GET('/files/{id}')
  Future<RestResult<Stream<List<int>>>> downloadFile(
    @Path('id') String id, {
    @Query('format') String? format,
    @Cancel() CancelToken? cancelToken,
    RestProgressCallback? onReceiveProgress,
  });
}
```

Consuming the stream:

```dart
final result = await fileApi.downloadFile('report-2024.pdf',
  onReceiveProgress: (received, total) =>
    print('${(received / total * 100).toStringAsFixed(1)}%'),
);

result.when(
  failure: (error) => print('Download failed: ${error.message}'),
  success: (stream) async {
    final sink = File('report.pdf').openWrite();
    await stream.pipe(sink);
    await sink.close();
    print('Download complete!');
  },
);
```

**Rules for `@Streaming`:**
- Return type **must** be `Future<RestResult<Stream<List<int>>>>`. Other return types will cause a build-time error.
- Cannot be combined with `@Multipart` or `@FormUrlEncoded` (streaming is for downloads).
- Cancel tokens and `onReceiveProgress` work normally.

---

## Server-Sent Events (`@SSE`)

Subscribe to live HTTP event streams with zero boilerplate using `@SSE`:

```dart
@RestApi(baseUrl: 'https://api.example.com')
abstract class NotificationApi {
  /// Stream live events from server.
  @SSE()
  @GET('/events/stream')
  Stream<SSEEvent> watchEvents();
}
```

Consuming events:

```dart
notificationApi.watchEvents().listen(
  (event) {
    print('Event: ${event.event}, Data: ${event.data}, ID: ${event.id}');
  },
  onError: (error) => print('Stream error: $error'),
);
```

- **Returns `Stream<SSEEvent>` directly** (no `Future` or `RestResult` wrapper).
- **HTML §9.2 Spec Compliant**: Parses `data:`, `event:`, `id:`, `retry:`, ignores comment lines (`:`), and concatenates multi-line data.
- **`reconnectMs`**: Pass a suggested reconnect delay hint via `@SSE(reconnectMs: 5000)`. Actual reconnect logic must be implemented in an interceptor or by the caller.

---

## Resilient Request Queue (`@ResilientQueue` / `@OfflineQueue`)

Automatically save and replay failed requests when network drops, connections timeout, or server errors (e.g. 502, 503, 429) occur:

```dart
@RestApi(baseUrl: 'https://api.example.com')
abstract class OrderApi {
  /// Auto-queues on network loss, timeout, or 502/503/429 status codes, and removes from queue on HTTP 200/201.
  @ResilientQueue(
    removeWhen: [200, 201],
    enqueueOnStatusCodes: [502, 503, 504, 429],
  )
  @POST('/orders')
  Future<RestResult<Order>> createOrder(@Body() Order order);
}
```

> **Note:** `@OfflineQueue` is supported as a backward-compatible alias for `@ResilientQueue`.

### Setup & Flushed Replay

```dart
final offlineQueue = RestRequestQueue();

// Build a client with the queue interceptor attached:
final client = RestClientBuilder()
    .baseUrl('https://api.example.com')
    .addInterceptor(RestQueueInterceptor(
      queue: offlineQueue,
      onQueued: (request, item) => print('Saved offline: ${request.path}'),
    ))
    .build();

// Set it as the global default (or inject per-API):
RestApiClientRegistry.defaultClient = client;

// Inspect or observe queued non-synced requests in UI:
print('Pending offline syncs: ${offlineQueue.length}');
offlineQueue.itemsStream.listen((items) {
  print('Queued requests: ${items.map((e) => e.request.path)}');
});

// Replay all pending requests when network is restored:
final flushResult = await offlineQueue.flush(client);
print('Synced ${flushResult.succeeded} requests (${flushResult.kept} remaining)');
```

- **Filter/Cancel**: Use `offlineQueue.removeWhere((item) => ...)` or `offlineQueue.clear()`.
- **Custom Dequeue**: Pass a `RestQueueResolver` implementation to `offlineQueue.flush(client, resolver: MyResolver())` for complex removal conditions.

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

## Fluent Client Builder (`RestClientBuilder`)

For advanced scenarios where you need a manually constructed `RestClient` (e.g. testing, isolated pools), use the fluent `RestClientBuilder`:

```dart
final client = RestClientBuilder()
    .baseUrl('https://api.example.com')
    .defaultHeaders({'Accept': 'application/json'})
    .timeouts(connectTimeoutMs: 10000, receiveTimeoutMs: 30000)
    .retry(maxAttempts: 3, delayMs: 500, statusCodes: [502, 503])
    .logging(enable: true)
    .addInterceptor(AuthInterceptor())
    .build();

// Optionally set as the process-wide default:
RestApiClientRegistry.defaultClient = client;
```

---

## Project Structure

```
rest_client_builder/
├── lib/
│   ├── rest_client_builder.dart      # Public barrel import
│   └── src/
│       ├── annotations/           # @RestApi, @RestModel, HTTP verb annotations
│       │   ├── api/               # @RestApi, @UseInterceptor, @ExcludeInterceptor, @Tag
│       │   ├── cache/             # @Cache
│       │   ├── configuration/     # @RestConfiguration, @BaseUrl, @Headers, @Retry, timeouts
│       │   ├── form/              # @FormUrlEncoded, @Field, @FieldMap
│       │   ├── http/              # @GET @POST @PUT @PATCH @DELETE @HEAD @OPTIONS @HTTP @SSE @Streaming
│       │   ├── models/            # @RestModel
│       │   ├── multipart/         # @Multipart, @Part
│       │   ├── parameters/        # @Path, @Query, @QueryMap, @Body, @Header, @HeaderMap, @Url, @Cancel
│       │   └── queue/             # @ResilientQueue / @OfflineQueue
│       ├── core/                  # RestResult, RestError, SSEEvent, utilities
│       ├── runtime/               # Dio execution runtime, interceptors, multipart, cache, queue
│       └── generator/             # Code generation logic & validators
├── example/                       # Production-style consumer example app
└── test/                          # Unit & generator tests
```

### Generated Output Layout

Sources under `lib/` are mirrored under `lib/rest_client_builder/` with builder-specific suffixes:

```
lib/
├── models/user.dart                          ← your @RestModel source
├── api/user_service.dart                     ← your @RestApi source
├── core/app_config.dart                      ← your @RestConfiguration source
└── rest_client_builder/
    ├── models/user.g.dart                    ← rest_model output
    ├── api/user_service.rest.g.dart          ← rest_api output
    └── core/app_config.rest.config.g.dart    ← rest_configuration output
```

---

## License

MIT License — free for commercial and open-source use.
