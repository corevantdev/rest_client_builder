import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/rest_client_config.dart';

/// Configures native HTTP socket connection pooling on [dio] for IO platforms.
///
/// Modifies [IOHttpClientAdapter.createHttpClient] to apply [RestClientConfig.idleTimeout]
/// and [RestClientConfig.maxConnectionsPerHost] to underlying [HttpClient] instances.
void configureConnectionPool(Dio dio, RestClientConfig config) {
  if (config.idleTimeout == null && config.maxConnectionsPerHost == null) {
    return;
  }
  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    final existingCreate = adapter.createHttpClient;
    adapter.createHttpClient = () {
      final client = existingCreate != null ? existingCreate() : HttpClient();
      if (config.idleTimeout != null) {
        client.idleTimeout = config.idleTimeout!;
      }
      if (config.maxConnectionsPerHost != null) {
        client.maxConnectionsPerHost = config.maxConnectionsPerHost!;
      }
      return client;
    };
  }
}
