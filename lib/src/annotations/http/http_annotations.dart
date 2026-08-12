import 'package:meta/meta_meta.dart';

import '../../core/constants/rest_constants.dart';

/// Base type for HTTP verb annotations.
@Target({TargetKind.method})
class HttpMethod {
  /// Creates an HTTP method annotation.
  const HttpMethod(this.method, [this.path = '']);

  /// HTTP method name (e.g. `GET`, `POST`).
  final String method;

  /// Relative path appended to the base URL.
  ///
  /// May contain `{placeholders}` bound with [Path].
  final String path;
}

/// HTTP GET request.
@Target({TargetKind.method})
class GET extends HttpMethod {
  /// Creates a GET annotation.
  const GET([String path = '']) : super(HttpMethodNames.get, path);
}

/// HTTP POST request.
@Target({TargetKind.method})
class POST extends HttpMethod {
  /// Creates a POST annotation.
  const POST([String path = '']) : super(HttpMethodNames.post, path);
}

/// HTTP PUT request.
@Target({TargetKind.method})
class PUT extends HttpMethod {
  /// Creates a PUT annotation.
  const PUT([String path = '']) : super(HttpMethodNames.put, path);
}

/// HTTP PATCH request.
@Target({TargetKind.method})
class PATCH extends HttpMethod {
  /// Creates a PATCH annotation.
  const PATCH([String path = '']) : super(HttpMethodNames.patch, path);
}

/// HTTP DELETE request.
@Target({TargetKind.method})
class DELETE extends HttpMethod {
  /// Creates a DELETE annotation.
  const DELETE([String path = '']) : super(HttpMethodNames.delete, path);
}

/// HTTP HEAD request.
@Target({TargetKind.method})
class HEAD extends HttpMethod {
  /// Creates a HEAD annotation.
  const HEAD([String path = '']) : super(HttpMethodNames.head, path);
}

/// HTTP OPTIONS request.
@Target({TargetKind.method})
class OPTIONS extends HttpMethod {
  /// Creates an OPTIONS annotation.
  const OPTIONS([String path = '']) : super(HttpMethodNames.options, path);
}
