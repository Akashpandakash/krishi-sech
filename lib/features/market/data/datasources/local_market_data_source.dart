import 'package:krishi_sech/features/market/domain/entities/market_product.dart';

class LocalMarketDataSource {
  const LocalMarketDataSource();

  Future<List<MarketProduct>> getProducts() async => const [
    MarketProduct(
      id: 'premium-wheat-seeds',
      kind: MarketProductKind.premiumWheatSeeds,
      category: MarketCategory.seeds,
      price: 1250,
      unit: MarketUnit.bag,
      stockQuantity: 48,
      vendor: 'Krishi Sech Seeds Cooperative',
    ),
    MarketProduct(
      id: 'organic-fertilizer',
      kind: MarketProductKind.organicFertilizer,
      category: MarketCategory.fertilizers,
      price: 680,
      unit: MarketUnit.pack,
      stockQuantity: 32,
      vendor: 'Green Soil Organics',
    ),
    MarketProduct(
      id: 'garden-sprayer',
      kind: MarketProductKind.gardenSprayer,
      category: MarketCategory.tools,
      price: 1899,
      unit: MarketUnit.piece,
      stockQuantity: 12,
      vendor: 'Bharat Farm Tools',
    ),
    MarketProduct(
      id: 'tomato-seeds',
      kind: MarketProductKind.tomatoSeeds,
      category: MarketCategory.seeds,
      price: 320,
      unit: MarketUnit.pack,
      stockQuantity: 0,
      vendor: 'Krishi Sech Seeds Cooperative',
    ),
  ];
}
