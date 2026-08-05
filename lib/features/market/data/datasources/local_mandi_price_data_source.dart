import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';

class LocalMandiPriceDataSource {
  const LocalMandiPriceDataSource();

  Future<List<MandiPrice>> getPrices() async => [
    MandiPrice(
      id: 'wheat-burdwan',
      crop: MandiCrop.wheat,
      marketName: 'Burdwan Krishak Bazar',
      district: 'Purba Bardhaman',
      minPrice: 2350,
      maxPrice: 2520,
      modalPrice: 2440,
      unit: 'quintal',
      updatedAt: DateTime(2026, 8, 6, 8, 30),
      trend: PriceTrend.up,
    ),
    MandiPrice(
      id: 'paddy-koley',
      crop: MandiCrop.paddy,
      marketName: 'Koley Market',
      district: 'Kolkata',
      minPrice: 2180,
      maxPrice: 2320,
      modalPrice: 2250,
      unit: 'quintal',
      updatedAt: DateTime(2026, 8, 6, 8, 15),
      trend: PriceTrend.stable,
    ),
    MandiPrice(
      id: 'mustard-bankura',
      crop: MandiCrop.mustard,
      marketName: 'Bankura Sadar Market',
      district: 'Bankura',
      minPrice: 5450,
      maxPrice: 5780,
      modalPrice: 5600,
      unit: 'quintal',
      updatedAt: DateTime(2026, 8, 6, 7, 55),
      trend: PriceTrend.up,
    ),
    MandiPrice(
      id: 'tomato-howrah',
      crop: MandiCrop.tomato,
      marketName: 'Howrah Wholesale Market',
      district: 'Howrah',
      minPrice: 1800,
      maxPrice: 2400,
      modalPrice: 2100,
      unit: 'quintal',
      updatedAt: DateTime(2026, 8, 6, 9, 5),
      trend: PriceTrend.down,
    ),
    MandiPrice(
      id: 'potato-kolkata',
      crop: MandiCrop.potato,
      marketName: 'Koley Market',
      district: 'Kolkata',
      minPrice: 1450,
      maxPrice: 1680,
      modalPrice: 1560,
      unit: 'quintal',
      updatedAt: DateTime(2026, 8, 6, 8, 45),
      trend: PriceTrend.stable,
    ),
  ];
}
