import 'dart:convert';

import '../../core/error/rest_error.dart';
import '../../core/logger/rest_logger.dart';
import '../../core/result/rest_result.dart';
import '../request/rest_body_type.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import 'rest_interceptor.dart';

/// Logs request / response / error lines when attached to a pipeline.
class LoggingRestInterceptor implements RestInterceptor {
  /// Creates a logging interceptor.
  const LoggingRestInterceptor(
    this.logger, {
    this.logCurl = true,
    this.logResponseBody = true,
  });

  /// Destination logger.
  final RestLogger logger;

  /// Whether to output a copy-pasteable cURL command for requests.
  final bool logCurl;

  /// Whether to log the response body payload.
  final bool logResponseBody;

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
    logger.info('→ ${request.method} $target');
    if (logCurl) {
      logger.debug('cURL:\n${toCurl(request)}');
    }
    if (request.headers.isNotEmpty) {
      logger.verbose('→ headers: ${redactHeaders(request.headers)}');
    }
    if (request.queryParameters.isNotEmpty) {
      logger.verbose('→ query: ${request.queryParameters}');
    }
    return request;
  }

  @override
  Future<RestResponse> onResponse(RestResponse response) async {
    final target = response.request.url ?? response.request.path;
    final status = response.statusCode;
    final method = response.request.method;

    if (status >= 400) {
      logger.error('← $status $method $target${_formatData(response.data)}');
    } else {
      logger.info('← $status $method $target${logResponseBody ? _formatData(response.data) : ''}');
    }
    return response;
  }

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async {
    logger.error('← ERROR: ${error.message}', error: error, stackTrace: error.stackTrace);
    return Failure<RestResponse>(error);
  }

  String _formatData(Object? data) {
    if (data == null) return '';
    try {
      if (data is Map || data is List) {
        return '\n📦 Body: ${jsonEncode(data)}';
      }
      return '\n📦 Body: $data';
    } catch (_) {
      return '\n📦 Body: $data';
    }
  }

  /// Converts a [RestRequest] into a copy-pasteable cURL command.
  static String toCurl(RestRequest request, {bool redactSensitive = true}) {
    final buffer = StringBuffer('curl -X ${request.method}');
    var targetUrl = request.url ?? request.path;
    if (request.queryParameters.isNotEmpty) {
      final uri = Uri.parse(targetUrl);
      final query = <String, dynamic>{...uri.queryParameters, ...request.queryParameters};
      targetUrl = uri.replace(queryParameters: query).toString();
    }
    buffer.write(" '$targetUrl'");

    final headers = redactSensitive ? redactHeaders(request.headers) : request.headers;
    for (final entry in headers.entries) {
      buffer.write(" \\\n  -H '${entry.key}: ${entry.value}'");
    }

    if (request.body != null) {
      if (request.bodyType == RestBodyType.json) {
        final jsonStr = request.body is String ? request.body as String : jsonEncode(request.body);
        buffer.write(" \\\n  -d '$jsonStr'");
      } else if (request.bodyType == RestBodyType.formUrlEncoded && request.body is Map) {
        final form = (request.body as Map).entries
            .map((e) => '${Uri.encodeQueryComponent(e.key.toString())}=${Uri.encodeQueryComponent(e.value.toString())}')
            .join('&');
        buffer.write(" \\\n  -d '$form'");
      } else if (request.body is String) {
        buffer.write(" \\\n  -d '${request.body}'");
      }
    }
    return buffer.toString();
  }

  /// Returns a copy of [headers] with sensitive values replaced by `[redacted]`.
  static Map<String, String> redactHeaders(Map<String, String> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase()) ? '[redacted]' : entry.value,
    };
  }
}
