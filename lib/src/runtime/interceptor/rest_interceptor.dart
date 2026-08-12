import '../../core/error/rest_error.dart';
import '../../core/result/rest_result.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';

/// Intercepts requests and responses in the runtime pipeline.
///
/// Interceptors may transform [RestRequest] / [RestResponse] values or map
/// errors. They must not send HTTP themselves unless acting as a terminal
/// custom engine.
abstract interface class RestInterceptor {
  /// Called before the HTTP engine sends [request].
  ///
  /// Return the (possibly modified) request to continue.
  Future<RestRequest> onRequest(RestRequest request);

  /// Called after a response is received from the engine.
  ///
  /// Return the (possibly modified) response to continue.
  Future<RestResponse> onResponse(RestResponse response);

  /// Called when the pipeline fails before a normal response is produced.
  ///
  /// Return [Success] to recover with a synthetic response, or [Failure] to
  /// propagate the error (possibly mapped).
  Future<RestResult<RestResponse>> onError(RestError error);
}

/// Short name for [RestInterceptor], intended for configuration declarations.
///
/// This makes `List<Interceptor>` usable in an `@GlobalInterceptors()` method.
typedef Interceptor = RestInterceptor;

/// Orchestrates a list of [RestInterceptor]s around an HTTP send operation.
///
/// Concrete pipeline implementations will be added later. This interface
/// documents the runtime flow contract only.
abstract interface class InterceptorPipeline {
  /// Interceptors in invocation order for requests
  /// (response/error hooks run in reverse).
  List<RestInterceptor> get interceptors;

  /// Runs the interceptor chain and invokes [send] as the terminal action.
  ///
  /// [send] is provided by the caller (typically bound to [RestHttpEngine.send]).
  Future<RestResult<RestResponse>> run(
    RestRequest request,
    Future<RestResponse> Function(RestRequest request) send,
  );
}
