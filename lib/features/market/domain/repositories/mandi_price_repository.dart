import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';

abstract interface class MandiPriceRepository {
  Future<List<MandiPrice>> getPrices();
}
