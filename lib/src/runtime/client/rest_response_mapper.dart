import 'dart:async';

import '../../core/error/rest_error.dart';
import '../../core/result/rest_result.dart';
import '../../core/sse/sse_event.dart';
import '../client/rest_client.dart';
import '../config/rest_client_config.dart';
import '../interceptor/rest_interceptor.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import '../../core/logger/rest_logger.dart';

/// Callback-driven [RestClient] for tests and local demos (no networking).
class CallbackRestClient implements RestClient {
  /// Creates a client that delegates to [onExecute].
  CallbackRestClient({
    required this.onExecute,
    RestClientConfig? config,
    this.onExecuteSSE,
  }) : config = config ?? const BasicRestClientConfig();

  /// Handler invoked by generated API methods.
  final Future<RestResult<RestResponse>> Function(RestRequest request) onExecute;

  /// Handler invoked by SSE API methods.
  final Stream<SSEEvent> Function(RestRequest request)? onExecuteSSE;

  @override
  final RestClientConfig config;

  @override
  Future<RestResult<RestResponse>> execute(RestRequest request) =>
      onExecute(request);

  @override
  Stream<SSEEvent> executeSSE(RestRequest request) =>
      onExecuteSSE != null ? onExecuteSSE!(request) : const Stream.empty();
}

/// Minimal concrete [RestClientConfig].
class BasicRestClientConfig implements RestClientConfig {
  /// Creates a basic config.
  const BasicRestClientConfig({
    this.baseUrl = '',
    this.defaultHeaders = const <String, String>{},
    this.connectTimeoutMs = 10000,
    this.receiveTimeoutMs = 30000,
    this.sendTimeoutMs = 30000,
    this.enableLog = false,
    this.retryMaxAttempts = 1,
    this.retryDelayMs = 0,
    this.retryStatusCodes,
    this.interceptors = const <RestInterceptor>[],
    this.logger = const NoOpRestLogger(),
  });

  @override
  final String baseUrl;

  @override
  final Map<String, String> defaultHeaders;

  @override
  final int connectTimeoutMs;

  @override
  final int receiveTimeoutMs;

  @override
  final int sendTimeoutMs;

  @override
  final bool enableLog;

  @override
  final int retryMaxAttempts;

  @override
  final int retryDelayMs;

  @override
  final List<int>? retryStatusCodes;

  @override
  final List<RestInterceptor> interceptors;

  @override
  final RestLogger logger;
}

/// Maps raw [RestClient.execute] results into typed [RestResult]s.
abstract final class RestResponseMapper {
  /// Maps a response into a single model via [fromJson].
  static RestResult<T> mapModel<T>(
    RestResult<RestResponse> result,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return _map(result, (data) {
      if (data is Map<String, dynamic>) {
        return fromJson(data);
      }
      if (data is Map) {
        return fromJson(Map<String, dynamic>.from(data));
      }
      throw RestError.validation(
        'Expected JSON object for model `$T`',
        details: {'runtimeType': data.runtimeType.toString()},
      );
    });
  }

  /// Maps a response into a list of models via [fromJson].
  static RestResult<List<T>> mapModelList<T>(
    RestResult<RestResponse> result,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return _map(result, (data) {
      if (data is! List) {
        throw RestError.validation(
          'Expected JSON array for `List<$T>`',
          details: {'runtimeType': data.runtimeType.toString()},
        );
      }
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return fromJson(item);
        }
        if (item is Map) {
          return fromJson(Map<String, dynamic>.from(item));
        }
        throw RestError.validation('Expected JSON object in array');
      }).toList(growable: false);
    });
  }

  /// Maps a successful empty/ignored body to `void`.
  static RestResult<void> mapVoid(RestResult<RestResponse> result) {
    return result.when(
      success: (response) {
        if (!response.isSuccess) {
          return Failure<void>(
            RestError.http(
              'HTTP ${response.statusCode}',
              statusCode: response.statusCode,
              details: {
                'body': response.data,
                'bodyString': response.bodyString,
              },
            ),
          );
        }
        return const Success<void>(null);
      },
      failure: (error) => Failure<void>(error),
    );
  }

  /// Maps a response body with a custom decoder.
  static RestResult<T> mapCustom<T>(
    RestResult<RestResponse> result,
    T Function(Object? data) decode,
  ) {
    return _map(result, decode);
  }

  /// Maps a streaming response body into a raw `Stream<List<int>>`.
  ///
  /// When the Dio engine is configured with `ResponseType.stream`, the
  /// response [RestResponse.data] is a Dio `ResponseBody` which exposes a
  /// `Stream<Uint8List>` via its `.stream` property.
  ///
  /// For non-Dio clients (e.g. test mocks), any existing [RestResponse.bodyBytes]
  /// or [RestResponse.bodyString] are wrapped in a single-item stream so the
  /// API contract is satisfied without network I/O.
  static RestResult<Stream<List<int>>> mapStream(
    RestResult<RestResponse> result,
  ) {
    return result.when(
      success: (response) {
        if (!response.isSuccess) {
          return Failure<Stream<List<int>>>(
            RestError.http(
              'HTTP \${response.statusCode}',
              statusCode: response.statusCode,
              details: {
                'body': response.data,
                'bodyString': response.bodyString,
              },
            ),
          );
        }
        try {
          final data = response.data;
          // Dio ResponseType.stream: data is ResponseBody with a .stream field.
          // We access it dynamically to avoid a hard Dio import here.
          if (data != null) {
            // Try to get a Stream<List<int>> from Dio ResponseBody.stream.
            try {
              // ignore: avoid_dynamic_calls
              final dynamic maybeStream = (data as dynamic).stream;
              if (maybeStream is Stream) {
                final typed = maybeStream.cast<List<int>>();
                return Success<Stream<List<int>>>(typed);
              }
            } catch (_) {
              // data is not a ResponseBody — fall through to byte/string fallback.
            }
          }
          // Fallback: wrap existing bytes or string into a single-chunk stream.
          final bytes = response.bodyBytes;
          if (bytes != null && bytes.isNotEmpty) {
            return Success<Stream<List<int>>>(Stream.value(bytes));
          }
          final bodyStr = response.bodyString;
          if (bodyStr != null && bodyStr.isNotEmpty) {
            final encoded = bodyStr.codeUnits;
            return Success<Stream<List<int>>>(Stream.value(encoded));
          }
          // Empty response — return an empty stream.
          return Success<Stream<List<int>>>(const Stream.empty());
        } on RestError catch (error) {
          return Failure<Stream<List<int>>>(error);
        } on Object catch (error, stackTrace) {
          return Failure<Stream<List<int>>>(RestError.fromException(error, stackTrace));
        }
      },
      failure: (error) => Failure<Stream<List<int>>>(error),
    );
  }

  static RestResult<T> _map<T>(
    RestResult<RestResponse> result,
    T Function(Object? data) decode,
  ) {
    return result.when(
      success: (response) {
        if (!response.isSuccess) {
          return Failure<T>(
            RestError.http(
              'HTTP ${response.statusCode}',
              statusCode: response.statusCode,
              details: {
                'body': response.data,
                'bodyString': response.bodyString,
              },
            ),
          );
        }
        try {
          return Success<T>(decode(response.data));
        } on RestError catch (error) {
          return Failure<T>(error);
        } on Object catch (error, stackTrace) {
          return Failure<T>(RestError.fromException(error, stackTrace));
        }
      },
      failure: (error) => Failure<T>(error),
    );
  }
}
