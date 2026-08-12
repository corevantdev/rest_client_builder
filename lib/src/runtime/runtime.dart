/// Runtime support used by generated and handwritten REST clients.
///
/// Includes Dio-backed execution ([DioRestClient], [DioRestHttpEngine]) plus
/// interceptor, retry, timeout, logging, and RestResult mapping helpers.
library;

export 'cancel/basic_cancel_token.dart';
export 'cancel/cancel_token.dart';
export 'cache/rest_response_cache.dart';
export 'client/dio_rest_client.dart';
export 'client/rest_client.dart';
export 'client/rest_client_builder.dart';
export 'client/rest_response_mapper.dart';
export 'config/rest_client_config.dart';
export 'config/rest_api_client_registry.dart';
export 'config/rest_api_global_configuration.dart';
export 'config/rest_execution_options.dart';
export 'config/rest_global_config.dart';
export 'dio/dio_error_mapper.dart';
export 'dio/dio_rest_http_engine.dart';
export 'interceptor/default_interceptor_pipeline.dart';
export 'interceptor/logging_rest_interceptor.dart';
export 'interceptor/rest_interceptor.dart';
export 'multipart/basic_multipart.dart';
export 'multipart/rest_multipart_body.dart';
export 'multipart/rest_multipart_part.dart';
export 'multipart/rest_part.dart';
export 'progress/progress_callback.dart';
export 'request/basic_rest_request.dart';
export 'request/rest_body_type.dart';
export 'request/rest_request.dart';
export 'response/basic_rest_response.dart';
export 'response/rest_response.dart';
