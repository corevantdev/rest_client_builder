/// Common string constants used across the framework.
///
/// Values are transport-agnostic labels and defaults — not tied to any HTTP
/// client implementation.
abstract final class RestConstants {
  /// Package name.
  static const String packageName = 'rest_client_builder';

  /// Default JSON MIME type.
  static const String contentTypeJson = 'application/json';

  /// Default form URL-encoded MIME type.
  static const String contentTypeFormUrlEncoded =
      'application/x-www-form-urlencoded';

  /// Default multipart MIME type prefix.
  static const String contentTypeMultipart = 'multipart/form-data';

  /// UTF-8 charset token.
  static const String charsetUtf8 = 'utf-8';

  /// Default connect/receive timeout hint in milliseconds (for adapters).
  static const int defaultTimeoutMs = 30000;

  /// Empty JSON object literal.
  static const String emptyJsonObject = '{}';

  /// Empty JSON array literal.
  static const String emptyJsonArray = '[]';
}

/// Canonical HTTP method name constants.
abstract final class HttpMethodNames {
  /// GET
  static const String get = 'GET';

  /// POST
  static const String post = 'POST';

  /// PUT
  static const String put = 'PUT';

  /// PATCH
  static const String patch = 'PATCH';

  /// DELETE
  static const String delete = 'DELETE';

  /// HEAD
  static const String head = 'HEAD';

  /// OPTIONS
  static const String options = 'OPTIONS';

  /// All supported method names.
  static const List<String> all = <String>[
    get,
    post,
    put,
    patch,
    delete,
    head,
    options,
  ];
}

/// Common HTTP header name constants.
abstract final class HttpHeaderNames {
  /// Content-Type
  static const String contentType = 'Content-Type';

  /// Accept
  static const String accept = 'Accept';

  /// Authorization
  static const String authorization = 'Authorization';

  /// User-Agent
  static const String userAgent = 'User-Agent';

  /// Cache-Control
  static const String cacheControl = 'Cache-Control';

  /// Content-Length
  static const String contentLength = 'Content-Length';

  /// Accept-Encoding
  static const String acceptEncoding = 'Accept-Encoding';

  /// X-Request-Id
  static const String requestId = 'X-Request-Id';
}

/// Common HTTP status code constants.
abstract final class HttpStatusCodes {
  /// 200 OK
  static const int ok = 200;

  /// 201 Created
  static const int created = 201;

  /// 204 No Content
  static const int noContent = 204;

  /// 400 Bad Request
  static const int badRequest = 400;

  /// 401 Unauthorized
  static const int unauthorized = 401;

  /// 403 Forbidden
  static const int forbidden = 403;

  /// 404 Not Found
  static const int notFound = 404;

  /// 408 Request Timeout
  static const int requestTimeout = 408;

  /// 409 Conflict
  static const int conflict = 409;

  /// 422 Unprocessable Entity
  static const int unprocessableEntity = 422;

  /// 429 Too Many Requests
  static const int tooManyRequests = 429;

  /// 500 Internal Server Error
  static const int internalServerError = 500;

  /// 502 Bad Gateway
  static const int badGateway = 502;

  /// 503 Service Unavailable
  static const int serviceUnavailable = 503;

  /// Whether [code] is in the 2xx range.
  static bool isSuccess(int code) => code >= 200 && code < 300;

  /// Whether [code] is in the 4xx range.
  static bool isClientError(int code) => code >= 400 && code < 500;

  /// Whether [code] is in the 5xx range.
  static bool isServerError(int code) => code >= 500 && code < 600;
}
