import 'package:krishi_sech/features/market/domain/entities/market_product.dart';

abstract final class MarketProductMapper {
  static MarketProduct fromJson(Map<String, dynamic> json) => MarketProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    category: _category(json['category'] as String?),
    price: (json['price'] as num).round(),
    unit: _unit(json['unit'] as String?),
    stockQuantity: (json['stockQuantity'] as num?)?.round() ?? 0,
    vendor: json['vendor'] as String? ?? '',
  );

  static MarketCategory _category(String? value) => switch (value) {
    'seeds' => MarketCategory.seeds,
    'fertilizers' => MarketCategory.fertilizers,
    'tools' => MarketCategory.tools,
    _ => throw FormatException('Unknown market category: $value'),
  };

  static MarketUnit _unit(String? value) => switch (value) {
    'bag' => MarketUnit.bag,
    'pack' => MarketUnit.pack,
    'piece' => MarketUnit.piece,
    'kg' => MarketUnit.kg,
    'litre' => MarketUnit.litre,
    _ => throw FormatException('Unknown market unit: $value'),
  };
}
