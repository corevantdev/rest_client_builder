import 'package:dio/dio.dart';

import '../../core/error/rest_error.dart';

/// Maps Dio failures into transport-agnostic [RestError] values.
abstract final class DioErrorMapper {
  /// Converts a [DioException] into a [RestError].
  static RestError fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RestError.timeout(
          error.message ?? 'Request timed out',
          cause: error,
          stackTrace: error.stackTrace,
          details: {
            'dioType': error.type.name,
            'uri': error.requestOptions.uri.toString(),
          },
        );
      case DioExceptionType.cancel:
        return RestError.cancelled(
          error.message ?? 'Request cancelled',
          cause: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        return RestError.http(
          error.message ?? 'HTTP $status',
          statusCode: status,
          cause: error,
          stackTrace: error.stackTrace,
          details: {
            'data': error.response?.data,
            'uri': error.requestOptions.uri.toString(),
          },
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return RestError.connection(
          error.message ?? 'Connection failed',
          cause: error,
          stackTrace: error.stackTrace,
          details: {
            'dioType': error.type.name,
            'uri': error.requestOptions.uri.toString(),
          },
        );
      default:
        return RestError.unknown(
          error.message ?? error.error?.toString() ?? 'Unknown Dio error',
          cause: error,
          stackTrace: error.stackTrace,
          details: {'uri': error.requestOptions.uri.toString()},
        );
    }
  }
}
