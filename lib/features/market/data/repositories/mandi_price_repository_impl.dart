import 'package:krishi_sech/features/market/data/datasources/remote_mandi_price_data_source.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';

class MandiPriceRepositoryImpl implements MandiPriceRepository {
  const MandiPriceRepositoryImpl(this.dataSource);

  final RemoteMandiPriceDataSource dataSource;

  @override
  Future<MandiPriceBoard> getPrices({
    required String state,
    String? district,
    String? commodity,
  }) => dataSource.getPrices(
    state: state,
    district: district,
    commodity: commodity,
  );
}
