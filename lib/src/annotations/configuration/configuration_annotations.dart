import 'package:meta/meta_meta.dart';

/// Marks a class as the REST client configuration root.
///
/// Pair with [BaseUrl], [Headers], [GlobalInterceptors], [Retry], [EnableLog],
/// and timeout annotations on the same class (or on a [RestApi] class).
@Target({TargetKind.classType})
class RestConfiguration {
  /// Creates a configuration marker.
  ///
  /// [name] is an optional logical name when multiple configs exist.
  const RestConfiguration({this.name});

  /// Optional configuration identifier.
  final String? name;
}

/// Declares the default base URL for a REST client.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class BaseUrl {
  /// Creates a base URL annotation.
  /// When used on a configuration method, omit [value]; the method result is
  /// read each time a client is created.
  const BaseUrl([this.value]);

  /// Absolute base URL, e.g. `https://api.example.com`.
  final String? value;
}

/// Declares static HTTP headers for a client or method.
///
/// Method-level headers override class-level headers with the same name.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class Headers {
  /// Creates a headers annotation.
  const Headers([this.value = const <String, String>{}]);

  /// Header name/value pairs.
  final Map<String, String> value;
}

/// Registers interceptors applied to every request of a client.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class GlobalInterceptors {
  /// Creates a global interceptors annotation.
  /// With no arguments on a method, the method supplies the interceptor
  /// instances. The positional form remains available for API declarations.
  const GlobalInterceptors([this.interceptors = const <Type>[]]);

  /// Interceptor types to apply globally.
  final List<Type> interceptors;
}

/// Declares automatic retry policy for a client or method.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class Retry {
  /// Creates a retry annotation.
  const Retry([
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
    this.retryStatusCodes,
  ]);

  /// Maximum attempts including the initial request.
  final int maxAttempts;

  /// Delay between retry attempts.
  final Duration delay;

  /// Optional status codes that should trigger a retry.
  final List<int>? retryStatusCodes;
}

/// Enables request/response logging for a client or method.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class EnableLog {
  /// Creates an enable-log annotation.
  ///
  /// When [enabled] is `false`, logging is explicitly disabled for the target.
  const EnableLog([this.enabled = true]);

  /// Whether logging is enabled.
  final bool enabled;
}

/// Declares the connection timeout.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class ConnectTimeout {
  /// Creates a connect-timeout annotation.
  const ConnectTimeout(this.duration);

  /// Timeout duration.
  final Duration duration;
}

/// Declares the receive timeout.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class ReceiveTimeout {
  /// Creates a receive-timeout annotation.
  const ReceiveTimeout(this.duration);

  /// Timeout duration.
  final Duration duration;
}

/// Declares the send timeout.
@Target({
  TargetKind.classType,
  TargetKind.method,
  TargetKind.getter,
  TargetKind.field
})
class SendTimeout {
  /// Creates a send-timeout annotation.
  const SendTimeout(this.duration);

  /// Timeout duration.
  final Duration duration;
}
