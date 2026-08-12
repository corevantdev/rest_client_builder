import 'package:meta/meta_meta.dart';

/// Binds a method parameter to a path placeholder (`{name}`).
@Target({TargetKind.parameter})
class Path {
  /// Creates a path parameter annotation.
  ///
  /// When [name] is omitted, the Dart parameter name is used.
  const Path([this.name]);

  /// Path placeholder name without braces.
  final String? name;
}

/// Binds a method parameter to a single query parameter.
@Target({TargetKind.parameter})
class Query {
  /// Creates a query parameter annotation.
  const Query([this.name, this.encoded = false]);

  /// Query key. Defaults to the Dart parameter name when `null`.
  final String? name;

  /// Whether [name]/value is already URL-encoded.
  final bool encoded;
}

/// Binds a `Map` parameter as multiple query parameters.
@Target({TargetKind.parameter})
class QueryMap {
  /// Creates a query-map annotation.
  const QueryMap({this.encoded = false});

  /// Whether values are already URL-encoded.
  final bool encoded;
}

/// Binds a method parameter to the request body.
@Target({TargetKind.parameter})
class Body {
  /// Creates a body annotation.
  const Body();
}

/// Binds a method parameter to a single request header.
@Target({TargetKind.parameter})
class Header {
  /// Creates a header parameter annotation.
  ///
  /// [name] is the HTTP header name (e.g. `Authorization`).
  const Header(this.name);

  /// HTTP header name.
  final String name;
}

/// Binds a `Map` parameter as multiple request headers.
@Target({TargetKind.parameter})
class HeaderMap {
  /// Creates a header-map annotation.
  const HeaderMap();
}

/// Replaces the full request URL with the annotated parameter value.
///
/// When present, the value is used instead of base URL + method path.
@Target({TargetKind.parameter})
class Url {
  /// Creates a URL override annotation.
  const Url();
}

/// Marks a parameter as the request cancellation token.
///
/// The parameter type must be [CancelToken] or `CancelToken?`.
///
/// ```dart
/// @GET('/users')
/// Future<RestResult<List<User>>> listUsers({
///   @Cancel() CancelToken? cancelToken,
/// });
/// ```
///
/// Named `@Cancel` (not `@CancelToken`) so it does not clash with the
/// [CancelToken] runtime interface.
@Target({TargetKind.parameter})
class Cancel {
  /// Creates a cancel-token parameter annotation.
  const Cancel();
}
