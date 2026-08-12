import 'package:rest_client_builder/rest_client_builder.dart';

import '../core/payment_config.dart';
export '../core/payment_config.dart';
import '../models/payment.dart';

import '../rest_client_builder/api/payment_api.rest.g.dart';
export '../rest_client_builder/api/payment_api.rest.g.dart';

/// Dedicated Payment API using Option 3: Dedicated Configuration via Annotation.
///
/// Binds automatically to [PaymentRestConfiguration]'s dedicated client pool,
/// keeping payment operations completely isolated from standard app traffic.
@RestApi(
  baseUrl: 'https://payment-service.com',
  configuration: PaymentRestConfiguration,
)
abstract class PaymentApi {
  @POST('/charge')
  Future<RestResult<ChargeResponse>> charge(@Body() ChargeRequest request);
}
