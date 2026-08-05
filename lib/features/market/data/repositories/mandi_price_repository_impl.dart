import 'package:krishi_sech/features/market/data/datasources/local_mandi_price_data_source.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';

class MandiPriceRepositoryImpl implements MandiPriceRepository {
  const MandiPriceRepositoryImpl(this.dataSource);

  final LocalMandiPriceDataSource dataSource;

  @override
  Future<List<MandiPrice>> getPrices() => dataSource.getPrices();
}
