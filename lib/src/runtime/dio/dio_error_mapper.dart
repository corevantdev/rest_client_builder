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
          _cleanTimeoutMessage(error),
          cause: error,
          stackTrace: error.stackTrace,
          details: {
            'dioType': error.type.name,
            'uri': error.requestOptions.uri.toString(),
            if (error.message != null) 'rawMessage': error.message,
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
        final responseData = error.response?.data;
        final message = _extractErrorMessage(responseData) ??
            error.message ??
            'HTTP $status';
        return RestError.http(
          message,
          statusCode: status,
          cause: error,
          stackTrace: error.stackTrace,
          details: {
            'data': responseData,
            'uri': error.requestOptions.uri.toString(),
          },
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return RestError.connection(
          _cleanConnectionMessage(error),
          cause: error,
          stackTrace: error.stackTrace,
          details: {
            'dioType': error.type.name,
            'uri': error.requestOptions.uri.toString(),
            if (error.message != null) 'rawMessage': error.message,
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

  static String _cleanTimeoutMessage(DioException error) {
    final raw = error.message;
    if (raw != null && raw.isNotEmpty) {
      final match = RegExp(
        r'took longer than ([^ ]+) to (receive|send|connect)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (match != null) {
        final durationStr = match.group(1);
        final action = match.group(2)?.toLowerCase() ?? 'receive';
        final formattedDuration = _formatDurationString(durationStr);
        return 'Request timeout: took longer than $formattedDuration to $action data.';
      }
      if (!raw.contains('To get rid of this exception')) {
        return raw;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout: unable to connect to server within configured timeout.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout: took longer than configured timeout to send request.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout: server took longer than configured timeout to respond.';
      default:
        return 'Request timed out.';
    }
  }

  static String _formatDurationString(String? durationStr) {
    if (durationStr == null) return 'configured timeout';
    final parts = durationStr.split(':');
    if (parts.length == 3) {
      final secondsPart = double.tryParse(parts[2]);
      final minutesPart = int.tryParse(parts[1]);
      final hoursPart = int.tryParse(parts[0]);
      if (secondsPart != null && (minutesPart ?? 0) == 0 && (hoursPart ?? 0) == 0) {
        final sec = secondsPart.toStringAsFixed(
          secondsPart.truncateToDouble() == secondsPart ? 0 : 1,
        );
        return '${sec}s';
      }
    }
    return durationStr;
  }

  static String _cleanConnectionMessage(DioException error) {
    if (error.type == DioExceptionType.badCertificate) {
      return 'SSL certificate validation failed.';
    }
    final raw = error.message;
    if (raw != null && raw.isNotEmpty && !raw.contains('SocketException')) {
      return raw;
    }
    return 'Connection failed: unable to connect to server. Please check your internet connection.';
  }

  static String? _extractErrorMessage(Object? data) {
    if (data is Map) {
      final message =
          data['message'] ?? data['error'] ?? data['msg'] ?? data['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
