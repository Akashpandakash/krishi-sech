import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';

abstract interface class MandiPriceRepository {
  /// Prices published for [state], optionally narrowed to one district or
  /// commodity. The state is required because AGMARKNET is queried per state
  /// and a nationwide pull is neither useful to a farmer nor cheap.
  Future<MandiPriceBoard> getPrices({
    required String state,
    String? district,
    String? commodity,
  });
}
