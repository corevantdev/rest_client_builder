import 'package:rest_client_builder/rest_client_builder.dart';

/// Demo auth interceptor — attaches a bearer token when present in extras.
class AuthInterceptor implements RestInterceptor {
  AuthInterceptor({this.token, Future<String?> Function()? tokenReader})
      : _tokenReader = tokenReader;

  /// Optional bearer token.
  final String? token;

  /// Reads the current token immediately before a request is sent.
  ///
  /// Apps typically pass a secure-storage or preferences lookup here. Keeping
  /// this asynchronous means refreshed and logged-out tokens are respected
  /// without rebuilding the global REST client.
  final Future<String?> Function()? _tokenReader;

  @override
  Future<RestRequest> onRequest(RestRequest request) async {
    final currentToken =
        _tokenReader == null ? token : await _tokenReader.call();
    if (currentToken == null || currentToken.isEmpty) {
      return request;
    }
    if (request is BasicRestRequest) {
      return request.copyWith(
        headers: {
          ...request.headers,
          HttpHeaderNames.authorization: 'Bearer $currentToken',
        },
      );
    }
    return request;
  }

  @override
  Future<RestResponse> onResponse(RestResponse response) async => response;

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async =>
      Failure<RestResponse>(error);
}

/// Demo upload interceptor — stamps a marker header for multipart calls.
class UploadInterceptor implements RestInterceptor {
  @override
  Future<RestRequest> onRequest(RestRequest request) async {
    if (request.bodyType != RestBodyType.multipart) {
      return request;
    }
    if (request is BasicRestRequest) {
      return request.copyWith(
        headers: {
          ...request.headers,
          'X-Upload': '1',
        },
      );
    }
    return request;
  }

  @override
  Future<RestResponse> onResponse(RestResponse response) async => response;

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async =>
      Failure<RestResponse>(error);
}
