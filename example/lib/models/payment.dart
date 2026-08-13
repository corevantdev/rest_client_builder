import 'package:rest_client_builder/rest_client_builder.dart';


@RestModel()
class ChargeRequest {
  const ChargeRequest({
    required this.amount,
    required this.currency,
  });

  final int amount;
  final String currency;
}

@RestModel()
class ChargeResponse {
  const ChargeResponse({
    required this.id,
    required this.status,
  });

  final String id;
  final String status;
}
