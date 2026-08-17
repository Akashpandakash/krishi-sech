enum MarketCategory { seeds, fertilizers, tools }

enum MarketUnit { bag, pack, piece, kg, litre }

/// A product listed by a seller in the Krishi Market catalogue.
///
/// [name] and [description] arrive already resolved to the app's language:
/// seller-authored text cannot live in the app's compiled ARB catalogue, so
/// the backend stores it per locale and picks one, falling back to English.
class MarketProduct {
  const MarketProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    required this.vendor,
  });

  final String id;
  final String name;
  final String description;
  final MarketCategory category;
  final int price;
  final MarketUnit unit;
  final int stockQuantity;
  final String vendor;

  bool get isAvailable => stockQuantity > 0;
}
