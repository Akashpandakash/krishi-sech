enum MandiCrop { paddy, wheat, maize, mustard, tomato, potato, onion }

enum PriceTrend { up, down, stable }

class MandiPrice {
  const MandiPrice({
    required this.id,
    required this.crop,
    required this.marketName,
    required this.district,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
    required this.updatedAt,
    required this.trend,
  });

  final String id;
  final MandiCrop crop;
  final String marketName;
  final String district;
  final int minPrice;
  final int maxPrice;
  final int modalPrice;
  final String unit;
  final DateTime updatedAt;
  final PriceTrend trend;
}
