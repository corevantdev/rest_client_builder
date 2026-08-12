import '../request/rest_request.dart';
import 'rest_response.dart';

/// Concrete [RestResponse] used by adapters and tests.
class BasicRestResponse implements RestResponse {
  /// Creates a basic response.
  const BasicRestResponse({
    required this.statusCode,
    required this.request,
    this.headers = const <String, String>{},
    this.data,
    this.bodyBytes,
    this.bodyString,
  });

  @override
  final int statusCode;

  @override
  final Map<String, String> headers;

  @override
  final Object? data;

  @override
  final List<int>? bodyBytes;

  @override
  final String? bodyString;

  @override
  final RestRequest request;

  @override
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
