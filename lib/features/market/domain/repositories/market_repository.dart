import 'package:krishi_sech/features/market/domain/entities/market_product.dart';

abstract interface class MarketRepository {
  Future<List<MarketProduct>> getProducts();
  Future<MarketProduct> getProduct(String id);
}
