import 'dart:convert';

import 'package:rest_client_builder/rest_client_builder.dart';

import 'core/app_config.dart';
import 'api/demo_api.dart';
import 'api/payment_api.dart';
import 'api/product_api.dart';
import 'models/payment.dart';
import 'models/product.dart';
import 'models/user.dart';

/// Production-style example of `rest_client_builder`.
///
/// Runs offline with [CallbackRestClient] so CI / local demos need no network.
/// Swap in `AppRestConfiguration().createRestClient()` for real Dio HTTP.
void main() async {
  final sampleUser = {
    'id': '1',
    'user_name': 'Ada',
    'role': 'admin',
    'createdAt': '2024-01-02T03:04:05.000Z',
    'tags': ['dart', 'flutter'],
    'scores': {'chess': 2100},
    'address': {'city': 'London', 'country': 'UK'},
  };

  final requests = <RestRequest>[];
  final client = CallbackRestClient(
    onExecute: (request) async {
      requests.add(request);

      if (request.method == HttpMethodNames.delete) {
        return Success(
          BasicRestResponse(statusCode: 204, request: request),
        );
      }

      if (request.bodyType == RestBodyType.multipart) {
        return Success(
          BasicRestResponse(
            statusCode: 200,
            request: request,
            data: sampleUser,
          ),
        );
      }

      if (request.path.contains('/users') &&
          request.method == HttpMethodNames.get &&
          !request.path.contains('/users/')) {
        return Success(
          BasicRestResponse(
            statusCode: 200,
            request: request,
            data: [sampleUser],
          ),
        );
      }

      return Success(
        BasicRestResponse(
          statusCode: 200,
          request: request,
          data: sampleUser,
        ),
      );
    },
  );

  // Set global shared client (for offline test runner / custom configs)
  RestApiClientRegistry.defaultClient = client;

  // Direct invocation via top-level demoApi — uses shared default client internally
  DemoApi apiService = demoApi;

  await _demoCrud(apiService);
  await _demoFoldPattern(apiService);
  await _demoMultipartCancelProgress(apiService);
  await _demoLoginExcludesAuth(apiService);
  await _demoOption3PaymentApi();
  await _demoProductApi();

  // ignore: avoid_print
  print('example ok — ${requests.length} requests exercised');
  // ignore: avoid_print
  print('endpoints: ${DemoApiDocs.endpoints.join(', ')}');
}

Future<void> _demoCrud(DemoApi api) async {
  final user = User(
    id: '1',
    name: 'Ada',
    role: Role.admin,
    createdAt: DateTime.utc(2024, 1, 2, 3, 4, 5),
    tags: const ['dart'],
    scores: const {'chess': 2100},
  );

  final get = await api.getUser('1', expand: 'address');
  expectTrue(get.getOrThrow().name == 'Ada');

  final list = await api.listUsers({'page': 1});
  expectTrue(list.getOrThrow().length == 1);

  final created = await api.createUser(user);
  expectTrue(created.getOrThrow().name == 'Ada');

  final replaced = await api.replaceUser('1', user);
  expectTrue(replaced.getOrThrow().name == 'Ada');

  final patched = await api.patchUser('1', {'user_name': 'Ada Lovelace'});
  expectTrue(patched.getOrThrow().name == 'Ada');

  final deleted = await api.deleteUser('1');
  expectTrue(deleted.isSuccess);
}

/// Demonstrates RestResult's functional combinators — ideal for GetX controllers.
///
/// Instead of try/catch, use `.fold()` or `.when()` to handle success/failure
/// branches declaratively:
///
/// ```dart
/// // In a GetX controller:
/// final result = await api.getUser(id);
/// result.fold(
///   (error) => showSnackbar(error.message),
///   (user)  => userState.value = user,
/// );
/// ```
Future<void> _demoFoldPattern(DemoApi api) async {
  final result = await api.getUser('1');

  // .fold() — failure-first, then success (like Either):
  final name = result.fold(
    (error) => 'Unknown',
    (user) => user.name ?? 'No name',
  );
  expectTrue(name == 'Ada');

  // .when() — named parameters, reads more clearly:
  result.when(
    success: (user) => expectTrue(user.id == '1'),
    failure: (error) => throw StateError('should not fail: $error'),
  );

  // .map() — transform the success value:
  final greeting = result.map((user) => 'Hello, ${user.name}!');
  expectTrue(greeting.getOrThrow() == 'Hello, Ada!');

  // .dataOrNull / .errorOrNull — quick null-safe access:
  expectTrue(result.dataOrNull != null);
  expectTrue(result.errorOrNull == null);
}

Future<void> _demoMultipartCancelProgress(DemoApi api) async {
  final token = BasicCancelToken();
  final progress = <String>[];

  final bytes = utf8.encode('fake-image-bytes');
  final part = RestPart.fromBytes(
    name: 'file',
    bytes: bytes,
    fileName: 'avatar.png',
    contentType: 'image/png',
  );

  final result = await api.uploadAvatar(
    part,
    'profile',
    cancelToken: token,
    onSendProgress: (count, total) => progress.add('up:$count/$total'),
    onReceiveProgress: (count, total) => progress.add('down:$count/$total'),
  );

  result.getOrThrow();
  expectTrue(!token.isCancelled);
}

Future<void> _demoLoginExcludesAuth(DemoApi api) async {
  final result = await api.login('ada@example.com', 'secret');
  result.getOrThrow();
}

Future<void> _demoOption3PaymentApi() async {
  // Option 3 Demo: paymentApi uses PaymentRestConfiguration dedicated client pool automatically!
  // Developers call paymentApi.charge(...) with ZERO client setup or injection!
  //
  // (In real runtime, paymentApi connects to https://payment-service.com via PaymentRestConfiguration).
  expectTrue(PaymentApiDocs.endpoints.isNotEmpty);
}

Future<void> _demoProductApi() async {
  // productApi shares the default client & connection pool with demoApi automatically!
  expectTrue(ProductApiDocs.endpoints.isNotEmpty);
}

void expectTrue(bool value) {
  if (!value) {
    throw StateError('example assertion failed');
  }
}
