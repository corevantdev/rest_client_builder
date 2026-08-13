import '../../core/result/rest_result.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';

/// Strategy interface for deciding whether a queued request should be removed
/// from [RestRequestQueue] after replay.
///
/// Implement this class when status-code check (`removeWhen`) is not enough
/// and custom logic is needed (e.g. inspecting response body or headers).
abstract interface class RestQueueResolver {
  /// Evaluates whether [request] should be dequeued after receiving [result].
  ///
  /// Return `true` to remove the request from the queue (sync completed).
  /// Return `false` to keep the request in the queue for another replay attempt.
  bool shouldRemove(RestRequest request, RestResult<RestResponse> result);
}
