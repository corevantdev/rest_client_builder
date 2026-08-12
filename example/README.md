# rest_client_builder example

Production-style consumer of `rest_client_builder`.

## What's included

| File | Demonstrates |
|------|----------------|
| `lib/user.dart` | `@RestModel`, nested models, enums, `JsonKey` |
| `lib/demo_api.dart` | CRUD, form login, multipart, cancel/progress, interceptors |
| `lib/app_config.dart` | `@RestConfiguration` + `DioRestClient` wiring |
| `lib/interceptors.dart` | `AuthInterceptor`, `UploadInterceptor` |
| `lib/main.dart` | Offline end-to-end demo via `CallbackRestClient` |

## Run

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run lib/main.dart
```

Expected output includes `example ok` and the generated `DemoApiDocs.endpoints` list.

## Live HTTP

In your app (not required for this demo):

```dart
import 'app_config.dart';
import 'demo_api.dart';

final api = DemoApi(buildExampleClient(authToken: '…'));
final user = (await api.getUser('1')).getOrThrow();
```
