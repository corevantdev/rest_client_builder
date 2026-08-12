import '../../core/error/rest_error.dart';
import '../../core/result/rest_result.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import 'rest_interceptor.dart';

/// Default [InterceptorPipeline] with forward request / reverse response order.
class DefaultInterceptorPipeline implements InterceptorPipeline {
  /// Creates a pipeline.
  const DefaultInterceptorPipeline(this.interceptors);

  @override
  final List<RestInterceptor> interceptors;

  @override
  Future<RestResult<RestResponse>> run(
    RestRequest request,
    Future<RestResponse> Function(RestRequest request) send,
  ) async {
    var currentRequest = request;
    for (final interceptor in interceptors) {
      currentRequest = await interceptor.onRequest(currentRequest);
    }

    try {
      var response = await send(currentRequest);
      for (final interceptor in interceptors.reversed) {
        response = await interceptor.onResponse(response);
      }
      return Success<RestResponse>(response);
    } on RestError catch (error) {
      return _handleError(error);
    } on Object catch (error, stackTrace) {
      return _handleError(RestError.fromException(error, stackTrace));
    }
  }

  Future<RestResult<RestResponse>> _handleError(RestError initial) async {
    var error = initial;
    for (final interceptor in interceptors.reversed) {
      final recovered = await interceptor.onError(error);
      if (recovered.isSuccess) {
        return recovered;
      }
      error = recovered.errorOrNull ?? error;
    }
    return Failure<RestResponse>(error);
  }
}

/// Keys written into [RestRequest.extras] by generated clients.
abstract final class RestInterceptorExtras {
  /// Type names from `@UseInterceptor` (class + method, merged).
  static const useInterceptors = 'useInterceptors';

  /// Type names from `@ExcludeInterceptor` (class + method, merged).
  static const excludeInterceptors = 'excludeInterceptors';
}

/// Resolves the effective interceptor list for a call.
///
/// Starts with [global] then [perRequest]. [excludeTypeNames] removes matches
/// by [restInterceptorTypeName]. When [useTypeNames] is non-empty, it acts as a
/// whitelist over the remaining list (typical for `@UseInterceptor`). When
/// [useTypeNames] is empty, all non-excluded interceptors run.
///
/// No auth-refresh or cache interceptors are injected by the framework.
List<RestInterceptor> resolveRestInterceptors({
  required List<RestInterceptor> global,
  List<RestInterceptor> perRequest = const <RestInterceptor>[],
  List<String> useTypeNames = const <String>[],
  List<String> excludeTypeNames = const <String>[],
}) {
  var selected = <RestInterceptor>[...global, ...perRequest];
  if (excludeTypeNames.isNotEmpty) {
    final excluded = excludeTypeNames.toSet();
    selected = [
      for (final interceptor in selected)
        if (!excluded.contains(restInterceptorTypeName(interceptor)))
          interceptor,
    ];
  }
  if (useTypeNames.isNotEmpty) {
    final allowed = useTypeNames.toSet();
    selected = [
      for (final interceptor in selected)
        if (allowed.contains(restInterceptorTypeName(interceptor))) interceptor,
    ];
  }
  return List<RestInterceptor>.unmodifiable(selected);
}

/// Runtime type name used for `@UseInterceptor` / `@ExcludeInterceptor` matching.
String restInterceptorTypeName(RestInterceptor interceptor) {
  return interceptor.runtimeType.toString();
}

/// Reads interceptor type-name lists from request [extras].
({List<String> use, List<String> exclude}) readRestInterceptorExtras(
  Map<String, Object?> extras,
) {
  return (
    use: _stringList(extras[RestInterceptorExtras.useInterceptors]),
    exclude: _stringList(extras[RestInterceptorExtras.excludeInterceptors]),
  );
}

List<String> _stringList(Object? value) {
  if (value is List<String>) {
    return value;
  }
  if (value is List) {
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
  return const <String>[];
}
