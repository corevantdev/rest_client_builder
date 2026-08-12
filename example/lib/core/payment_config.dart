import 'package:rest_client_builder/rest_client_builder.dart';

export '../rest_client_builder/core/payment_config.rest.config.g.dart';

/// Dedicated configuration for Payment / Checkout microservices.
///
/// Uses dedicated timeouts (0 retries to prevent double charging) and
/// payment-specific headers.
@RestConfiguration()
class PaymentRestConfiguration implements RestApiGlobalConfiguration {
  @override
  final String baseUrl = 'https://payment-service.com';
  @override
  final Map<String, String> headers = const {
    'Accept': 'application/json',
    'X-Payment-Version': 'v2',
  };
  @override
  final int? retryMaxAttempts = 1; // 0 retries on payment calls
  @override
  final int? retryDelayMs = 0;
  @override
  final List<int>? retryStatusCodes = const [];
  @override
  final int? connectTimeoutMs = 5000;
  @override
  final int? receiveTimeoutMs = 15000;
  @override
  final int? sendTimeoutMs = 15000;
  @override
  final bool? enableLog = true;
  @override
  final List<RestInterceptor> interceptors = const [];
}
