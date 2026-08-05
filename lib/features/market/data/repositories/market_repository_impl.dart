import 'package:krishi_sech/features/market/data/datasources/local_market_data_source.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/domain/repositories/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  const MarketRepositoryImpl(this.dataSource);

  final LocalMarketDataSource dataSource;

  @override
  Future<List<MarketProduct>> getProducts() => dataSource.getProducts();
}
