import 'package:rest_client_builder/rest_client_builder.dart';

@RestModel()
class Address {
  const Address({
    this.city,
    this.country,
  });

  final String? city;
  final String? country;
}
