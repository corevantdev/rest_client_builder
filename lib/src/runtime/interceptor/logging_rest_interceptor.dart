import '../../core/logger/rest_logger.dart';
import '../../core/result/rest_result.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import 'rest_interceptor.dart';
import '../../core/error/rest_error.dart';

/// Logs request / response / error lines when attached to a pipeline.
class LoggingRestInterceptor implements RestInterceptor {
  /// Creates a logging interceptor.
  const LoggingRestInterceptor(this.logger);

  /// Destination logger.
  final RestLogger logger;

  /// Headers whose values are replaced with `[redacted]` in log output.
  static const _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
    'proxy-authorization',
  };

  @override
  Future<RestRequest> onRequest(RestRequest request) async {
    final target = request.url ?? request.path;
    logger.debug('→ ${request.method} $target');
    if (request.headers.isNotEmpty) {
      logger.verbose('→ headers: ${_redactHeaders(request.headers)}');
    }
    if (request.queryParameters.isNotEmpty) {
      logger.verbose('→ query: ${request.queryParameters}');
    }
    return request;
  }

  @override
  Future<RestResponse> onResponse(RestResponse response) async {
    final target = response.request.url ?? response.request.path;
    logger.debug('← ${response.statusCode} ${response.request.method} $target');
    return response;
  }

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async {
    logger.error('← error: ${error.message}', error: error, stackTrace: error.stackTrace);
    return Failure<RestResponse>(error);
  }

  /// Returns a copy of [headers] with sensitive values replaced by `[redacted]`.
  static Map<String, String> _redactHeaders(Map<String, String> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase())
            ? '[redacted]'
            : entry.value,
    };
  }
}
