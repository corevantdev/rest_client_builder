import 'package:dio/dio.dart';

import '../../core/error/rest_error.dart';
import '../cancel/basic_cancel_token.dart';
import '../client/rest_client.dart';
import '../multipart/rest_multipart_body.dart';
import '../multipart/rest_multipart_part.dart';
import '../multipart/rest_part.dart';
import '../request/basic_rest_request.dart';
import '../request/rest_body_type.dart';
import '../request/rest_request.dart';
import '../response/basic_rest_response.dart';
import '../response/rest_response.dart';
import 'dio_error_mapper.dart';

/// Dio-backed [RestHttpEngine].
///
/// Performs the HTTP call only. Retry, logging, and interceptor orchestration
/// live in [DioRestClient].
class DioRestHttpEngine implements RestHttpEngine {
  /// Creates an engine.
  ///
  /// When [dio] is omitted, a new [Dio] is created. Pass a shared instance to
  /// reuse adapters owned by the host app.
  DioRestHttpEngine({
    Dio? dio,
    this.baseUrl = '',
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Fallback base URL when the request has no absolute [RestRequest.url].
  final String baseUrl;

  /// Underlying Dio instance.
  Dio get dio => _dio;

  @override
  Future<RestResponse> send(RestRequest request) async {
    final uri = _resolveUri(request);
    final isStream = request.extras['responseType'] == 'stream';
    final options = Options(
      method: request.method,
      headers: request.headers,
      connectTimeout: _duration(request.connectTimeoutMs),
      receiveTimeout: _duration(request.receiveTimeoutMs),
      sendTimeout: _duration(request.sendTimeoutMs),
      // Deliver HTTP responses to the runtime; non-2xx become RestResult
      // failures via RestResponseMapper / call-site policy.
      validateStatus: (_) => true,
      contentType: _contentType(request),
      listFormat: ListFormat.multi,
      responseType: isStream ? ResponseType.stream : null,
    );

    try {
      final response = await _dio.request<dynamic>(
        uri.toString(),
        data: _encodeBody(request),
        queryParameters: request.queryParameters.isEmpty
            ? null
            : request.queryParameters,
        options: options,
        cancelToken: _dioCancelToken(request),
        onSendProgress: request.onSendProgress == null
            ? null
            : (count, total) => request.onSendProgress!(count, total),
        onReceiveProgress: request.onReceiveProgress == null
            ? null
            : (count, total) => request.onReceiveProgress!(count, total),
      );
      return _toRestResponse(request, response, isStream: isStream);
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        return _toRestResponse(request, response, isStream: isStream);
      }
      throw DioErrorMapper.fromDioException(error);
    } on RestError {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw RestError.fromException(error, stackTrace);
    }
  }

  Uri _resolveUri(RestRequest request) {
    final absolute = request.url;
    if (absolute != null && absolute.isNotEmpty) {
      return Uri.parse(absolute);
    }
    return Uri.parse(joinRestUrl(baseUrl, request.path));
  }

  Duration? _duration(int? milliseconds) {
    if (milliseconds == null) {
      return null;
    }
    return Duration(milliseconds: milliseconds);
  }

  String? _contentType(RestRequest request) {
    switch (request.bodyType) {
      case RestBodyType.json:
        return Headers.jsonContentType;
      case RestBodyType.formUrlEncoded:
        return Headers.formUrlEncodedContentType;
      case RestBodyType.multipart:
      case RestBodyType.none:
      case RestBodyType.bytes:
      case RestBodyType.text:
        return null;
    }
  }

  Object? _encodeBody(RestRequest request) {
    switch (request.bodyType) {
      case RestBodyType.none:
        return null;
      case RestBodyType.json:
      case RestBodyType.bytes:
      case RestBodyType.text:
        return request.body;
      case RestBodyType.formUrlEncoded:
        if (request.body is Map) {
          return Map<String, dynamic>.from(request.body! as Map);
        }
        return request.body;
      case RestBodyType.multipart:
        return _toFormData(request.multipartBody);
    }
  }

  FormData? _toFormData(RestMultipartBody? body) {
    if (body == null) {
      return null;
    }
    final map = <String, dynamic>{};
    for (final part in body.parts) {
      map[part.name] = _encodePart(part);
    }
    return FormData.fromMap(map);
  }

  Object _encodePart(RestMultipartPart part) {
    if (part is RestPart) {
      return MultipartFile.fromBytes(
        part.bytes,
        filename: part.fileName,
        contentType: _mediaType(part.contentType),
      );
    }
    final value = part.value;
    if (value is List<int>) {
      return MultipartFile.fromBytes(
        value,
        filename: part.fileName,
        contentType: _mediaType(part.contentType),
      );
    }
    if (value is MultipartFile) {
      return value;
    }
    return value;
  }

  DioMediaType? _mediaType(String? contentType) {
    if (contentType == null || contentType.isEmpty) {
      return null;
    }
    return DioMediaType.parse(contentType);
  }

  CancelToken? _dioCancelToken(RestRequest request) {
    final token = request.cancelToken;
    if (token is BasicCancelToken) {
      return token.dioToken;
    }
    return null;
  }

  RestResponse _toRestResponse(
    RestRequest request,
    Response<dynamic> response, {
    bool isStream = false,
  }) {
    final headers = <String, String>{};
    response.headers.map.forEach((key, values) {
      headers[key] = values.join(',');
    });

    final data = response.data;

    // For streaming responses, store the raw ResponseBody in data so that
    // RestResponseMapper.mapStream() can pull .stream off it directly.
    if (isStream) {
      return BasicRestResponse(
        statusCode: response.statusCode ?? 0,
        headers: headers,
        data: data, // Dio ResponseBody
        request: request is BasicRestRequest
            ? request
            : BasicRestRequest(
                method: request.method,
                path: request.path,
                url: request.url,
                headers: request.headers,
                queryParameters: request.queryParameters,
                body: request.body,
                bodyType: request.bodyType,
                multipartBody: request.multipartBody,
                connectTimeoutMs: request.connectTimeoutMs,
                receiveTimeoutMs: request.receiveTimeoutMs,
                sendTimeoutMs: request.sendTimeoutMs,
                cancelToken: request.cancelToken,
                onSendProgress: request.onSendProgress,
                onReceiveProgress: request.onReceiveProgress,
                extras: request.extras,
              ),
      );
    }

    String? bodyString;
    if (data is String) {
      bodyString = data;
    } else if (data != null) {
      bodyString = data.toString();
    }

    List<int>? bodyBytes;
    if (data is List<int>) {
      bodyBytes = data;
    }

    return BasicRestResponse(
      statusCode: response.statusCode ?? 0,
      headers: headers,
      data: data,
      bodyBytes: bodyBytes,
      bodyString: bodyString,
      request: request is BasicRestRequest
          ? request
          : BasicRestRequest(
              method: request.method,
              path: request.path,
              url: request.url,
              headers: request.headers,
              queryParameters: request.queryParameters,
              body: request.body,
              bodyType: request.bodyType,
              multipartBody: request.multipartBody,
              connectTimeoutMs: request.connectTimeoutMs,
              receiveTimeoutMs: request.receiveTimeoutMs,
              sendTimeoutMs: request.sendTimeoutMs,
              cancelToken: request.cancelToken,
              onSendProgress: request.onSendProgress,
              onReceiveProgress: request.onReceiveProgress,
              extras: request.extras,
            ),
    );
  }
}
