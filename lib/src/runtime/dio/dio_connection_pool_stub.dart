import 'package:dio/dio.dart';

import '../config/rest_client_config.dart';

/// Configures native HTTP socket connection pooling on [dio].
///
/// On platforms without `dart:io` (e.g. Flutter Web), browser networking
/// controls connection pooling and this function is a no-op.
void configureConnectionPool(Dio dio, RestClientConfig config) {
  // No-op on web / platforms without dart:io.
}
