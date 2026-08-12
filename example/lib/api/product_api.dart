import 'package:rest_client_builder/rest_client_builder.dart';

import '../models/product.dart';

import '../rest_client_builder/api/product_api.rest.g.dart';
export '../rest_client_builder/api/product_api.rest.g.dart';

/// Product Microservice API — connects to 'https://product-service.com',
/// but REUSES the main shared client pool (no new client instance needed)!
@RestApi(baseUrl: 'https://product-service.com')
abstract class ProductApi {
  @GET('/products/{id}')
  Future<RestResult<Product>> getProduct(@Path('id') String id);

  @GET('/products')
  @Cache(durationMs: 60000)
  Future<RestResult<List<Product>>> listProducts();
}
