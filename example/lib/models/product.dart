import 'package:rest_client_builder/rest_client_builder.dart';

export '../rest_client_builder/models/product.g.dart';

@RestModel()
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;
}
