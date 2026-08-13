import '../../core/result/rest_result.dart';
import '../../core/sse/sse_event.dart';
import '../config/rest_client_config.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';

/// High-level REST client entry point used by generated and handwritten APIs.
///
/// Implementations will orchestrate interceptors, retries, and a
/// [RestHttpEngine]. This interface does not execute HTTP by itself.
abstract interface class RestClient {
  /// Active client configuration.
  RestClientConfig get config;

  /// Executes [request] through the runtime pipeline.
  ///
  /// Returns [Success] with a [RestResponse] or [Failure] with a [RestError].
  Future<RestResult<RestResponse>> execute(RestRequest request);

  /// Executes an SSE request and returns a live stream of [SSEEvent]s.
  Stream<SSEEvent> executeSSE(RestRequest request);
}

/// Low-level HTTP transport abstraction.
///
/// Concrete adapters (e.g. `dart:io`, `package:http`) will implement this later.
/// No default implementation is provided.
abstract interface class RestHttpEngine {
  /// Sends [request] over the network and returns a [RestResponse].
  ///
  /// May throw or return via [RestResult] wrappers at the [RestClient] layer.
  Future<RestResponse> send(RestRequest request);
}
