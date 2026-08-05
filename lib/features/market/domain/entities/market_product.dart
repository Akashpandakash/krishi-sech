enum MarketCategory { seeds, fertilizers, tools }

enum MarketProductKind {
  premiumWheatSeeds,
  organicFertilizer,
  gardenSprayer,
  tomatoSeeds,
}

enum MarketUnit { bag, pack, piece }

class MarketProduct {
  const MarketProduct({
    required this.id,
    required this.kind,
    required this.category,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    required this.vendor,
  });

  final String id;
  final MarketProductKind kind;
  final MarketCategory category;
  final int price;
  final MarketUnit unit;
  final int stockQuantity;
  final String vendor;

  bool get isAvailable => stockQuantity > 0;
}
