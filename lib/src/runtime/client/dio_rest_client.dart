import 'package:dio/dio.dart';

import '../../core/error/rest_error.dart';
import '../../core/result/rest_result.dart';
import '../cache/rest_response_cache.dart';
import '../config/rest_client_config.dart';
import '../config/rest_execution_options.dart';
import '../dio/dio_rest_http_engine.dart';
import '../interceptor/default_interceptor_pipeline.dart';
import '../interceptor/logging_rest_interceptor.dart';
import '../interceptor/rest_interceptor.dart';
import '../request/basic_rest_request.dart';
import '../request/rest_body_type.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import 'rest_client.dart';
import 'rest_response_mapper.dart';

/// Dio-powered [RestClient] with global config, retry, timeouts, logging,
/// headers, and interceptor resolution.
///
/// Does **not** implement response caching or auth-token refresh.
class DioRestClient implements RestClient {
  /// Creates a Dio REST client.
  DioRestClient({
    RestClientConfig? config,
    Dio? dio,
    RestHttpEngine? engine,
    List<RestInterceptor>? interceptors,
  })  : config = config ?? const BasicRestClientConfig(),
        _extraInterceptors = List<RestInterceptor>.unmodifiable(
          interceptors ?? const <RestInterceptor>[],
        ),
        _engine = engine ??
            DioRestHttpEngine(
              dio: dio,
              baseUrl: (config ?? const BasicRestClientConfig()).baseUrl,
            ) {
    if (dio != null) {
      _configureDio(dio, this.config);
    } else if (_engine is DioRestHttpEngine) {
      _configureDio(_engine.dio, this.config);
    }
  }

  /// Convenience constructor from global configuration.
  factory DioRestClient.fromConfig(
    RestClientConfig config, {
    Dio? dio,
    List<RestInterceptor>? interceptors,
  }) {
    return DioRestClient(
      config: config,
      dio: dio,
      interceptors: interceptors,
    );
  }

  @override
  final RestClientConfig config;

  final RestHttpEngine _engine;
  final List<RestInterceptor> _extraInterceptors;

  /// Effective interceptor list before per-request use/exclude filtering.
  List<RestInterceptor> get resolvedInterceptors => resolveRestInterceptors(
        global: _registeredInterceptors,
      );

  /// All interceptors registered on this client before per-request filtering.
  ///
  /// Computed once on first access and reused for every request.
  late final List<RestInterceptor> _registeredInterceptors = [
    ...config.interceptors,
    ..._extraInterceptors,
    if (config.enableLog) LoggingRestInterceptor(config.logger),
  ];

  /// Interceptors for a single [request], honoring `@UseInterceptor` /
  /// `@ExcludeInterceptor` type names in [RestRequest.extras].
  List<RestInterceptor> interceptorsForRequest(RestRequest request) {
    final extras = readRestInterceptorExtras(request.extras);
    return resolveRestInterceptors(
      global: _registeredInterceptors,
      useTypeNames: extras.use,
      excludeTypeNames: extras.exclude,
    );
  }

  @override
  Future<RestResult<RestResponse>> execute(RestRequest request) async {
    final prepared = _prepareRequest(request);
    final options = readRestExecutionOptions(prepared.extras);
    final cacheDurationMs = prepared.extras['cacheDurationMs'] as int?;

    if (cacheDurationMs != null && cacheDurationMs > 0) {
      final cacheKey = '${prepared.method}:${prepared.url ?? prepared.path}';
      final cached = RestResponseCache.get(cacheKey);
      if (cached != null) {
        if (config.enableLog) {
          config.logger.info('Cache HIT for $cacheKey');
        }
        return Success<RestResponse>(cached);
      }
    }

    final pipeline = DefaultInterceptorPipeline(
      interceptorsForRequest(prepared),
    );
    final maxAttempts =
        (options.retryMaxAttempts ?? config.retryMaxAttempts) < 1
            ? 1
            : (options.retryMaxAttempts ?? config.retryMaxAttempts);
    final enableLog = options.enableLog ?? config.enableLog;

    RestResult<RestResponse>? lastFailure;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (enableLog && attempt > 1) {
        config.logger.info('Retry attempt $attempt/$maxAttempts');
      }

      final result = await pipeline.run(prepared, _engine.send);

      if (result.isSuccess) {
        final response = result.dataOrNull!;
        if (cacheDurationMs != null && cacheDurationMs > 0 && response.isSuccess) {
          final cacheKey = '${prepared.method}:${prepared.url ?? prepared.path}';
          RestResponseCache.put(cacheKey, response, cacheDurationMs);
        }
        final shouldRetry = !response.isSuccess &&
            attempt < maxAttempts &&
            _shouldRetryStatus(response.statusCode, options.retryStatusCodes);
        if (!shouldRetry) {
          return result;
        }
        lastFailure = Failure<RestResponse>(
          RestError.http(
            'HTTP ${response.statusCode}',
            statusCode: response.statusCode,
            details: {'body': response.data},
          ),
        );
      } else {
        final error = result.errorOrNull!;
        final shouldRetry = attempt < maxAttempts && _shouldRetryError(error);
        if (!shouldRetry) {
          return result;
        }
        lastFailure = result;
      }

      final retryDelayMs = options.retryDelayMs ?? config.retryDelayMs;
      if (retryDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: retryDelayMs));
      }
    }

    return lastFailure ??
        Failure<RestResponse>(
            RestError.unknown('Request failed without result'));
  }

  RestRequest _prepareRequest(RestRequest request) {
    final headers = <String, String>{
      ...config.defaultHeaders,
      ...request.headers,
    };

    _ensureContentType(headers, request.bodyType);

    final connect = request.connectTimeoutMs ?? config.connectTimeoutMs;
    final receive = request.receiveTimeoutMs ?? config.receiveTimeoutMs;
    final send = request.sendTimeoutMs ?? config.sendTimeoutMs;

    final absoluteUrl = request.url ??
        (config.baseUrl.isEmpty
            ? null
            : joinRestUrl(config.baseUrl, request.path));

    if (request is BasicRestRequest) {
      return request.copyWith(
        headers: headers,
        url: absoluteUrl,
        connectTimeoutMs: connect,
        receiveTimeoutMs: receive,
        sendTimeoutMs: send,
      );
    }

    return BasicRestRequest(
      method: request.method,
      path: request.path,
      url: absoluteUrl,
      headers: headers,
      queryParameters: request.queryParameters,
      body: request.body,
      bodyType: request.bodyType,
      multipartBody: request.multipartBody,
      connectTimeoutMs: connect,
      receiveTimeoutMs: receive,
      sendTimeoutMs: send,
      cancelToken: request.cancelToken,
      onSendProgress: request.onSendProgress,
      onReceiveProgress: request.onReceiveProgress,
      extras: request.extras,
    );
  }

  void _ensureContentType(Map<String, String> headers, RestBodyType bodyType) {
    const key = 'Content-Type';
    final hasContentType = headers.keys.any(
      (header) => header.toLowerCase() == 'content-type',
    );
    if (hasContentType) {
      return;
    }
    switch (bodyType) {
      case RestBodyType.json:
        headers[key] = 'application/json';
      case RestBodyType.formUrlEncoded:
        headers[key] = 'application/x-www-form-urlencoded';
      case RestBodyType.multipart:
      case RestBodyType.none:
      case RestBodyType.bytes:
      case RestBodyType.text:
        break;
    }
  }

  bool _shouldRetryStatus(int statusCode, List<int>? overrideCodes) {
    final codes = overrideCodes ?? config.retryStatusCodes;
    if (codes == null || codes.isEmpty) {
      return statusCode >= 500 && statusCode < 600;
    }
    return codes.contains(statusCode);
  }

  bool _shouldRetryError(RestError error) {
    return error.code == RestErrorCodes.timeout ||
        error.code == RestErrorCodes.connection;
  }

  static void _configureDio(Dio dio, RestClientConfig config) {
    dio.options
      ..baseUrl = config.baseUrl
      ..connectTimeout = Duration(milliseconds: config.connectTimeoutMs)
      ..receiveTimeout = Duration(milliseconds: config.receiveTimeoutMs)
      ..sendTimeout = Duration(milliseconds: config.sendTimeoutMs)
      ..validateStatus = (_) => true;
  }
}
