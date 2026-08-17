import 'package:krishi_sech/features/market/data/datasources/remote_market_data_source.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/domain/repositories/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  const MarketRepositoryImpl(this.dataSource);

  final RemoteMarketDataSource dataSource;

  /// Category and search filtering stay client-side: the catalogue is small
  /// enough to hold in memory and filtering locally keeps typing responsive.
  @override
  Future<List<MarketProduct>> getProducts() => dataSource.getProducts();

  @override
  Future<MarketProduct> getProduct(String id) => dataSource.getProduct(id);
}
