import 'package:meta/meta_meta.dart';

/// Marks an abstract class as a REST API client definition.
///
/// Methods on the annotated class should use HTTP verb annotations such as
/// [GET], [POST], etc. Code generation will produce the implementation.
@Target({TargetKind.classType})
class RestApi {
  /// Creates a REST API annotation.
  ///
  /// [baseUrl] overrides [BaseUrl] when both are present.
  /// [configuration] allows specifying a custom [RestApiGlobalConfiguration] class.
  const RestApi({this.baseUrl, this.path = '', this.configuration});

  /// Optional base URL for this API client.
  final String? baseUrl;

  /// Path prefix applied to every endpoint in this API.
  final String path;

  /// Optional custom configuration type (e.g. `AppRestConfiguration`).
  final Type? configuration;
}

/// Groups API methods under an OpenAPI-style tag.
@Target({TargetKind.classType, TargetKind.method})
class Tag {
  /// Creates a tag annotation.
  const Tag(this.name);

  /// Tag name used for documentation and grouping.
  final String name;
}

/// Applies additional interceptors to a client or method.
@Target({TargetKind.classType, TargetKind.method})
class UseInterceptor {
  /// Creates a use-interceptor annotation.
  const UseInterceptor(this.interceptors);

  /// Interceptor types to apply.
  final List<Type> interceptors;
}

/// Excludes interceptors that would otherwise apply.
@Target({TargetKind.classType, TargetKind.method})
class ExcludeInterceptor {
  /// Creates an exclude-interceptor annotation.
  const ExcludeInterceptor(this.interceptors);

  /// Interceptor types to skip.
  final List<Type> interceptors;
}
