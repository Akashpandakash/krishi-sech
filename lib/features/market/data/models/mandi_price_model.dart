import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';

abstract final class MandiPriceMapper {
  static MandiPrice fromJson(Map<String, dynamic> json) {
    final arrivalDate = DateTime.tryParse(json['arrivalDate'] as String? ?? '');
    if (arrivalDate == null) {
      throw const FormatException('Mandi price is missing an arrival date');
    }
    return MandiPrice(
      id: json['id'] as String,
      commodity: json['commodity'] as String,
      variety: _text(json['variety']),
      grade: _text(json['grade']),
      state: json['state'] as String,
      district: json['district'] as String,
      marketName: json['market'] as String,
      minPrice: (json['minPrice'] as num).round(),
      maxPrice: (json['maxPrice'] as num).round(),
      modalPrice: (json['modalPrice'] as num).round(),
      unit: json['unit'] as String? ?? 'quintal',
      arrivalDate: arrivalDate.toLocal(),
      trend: _trend(json['trend'] as String?),
      previousModalPrice: (json['previousModalPrice'] as num?)?.round(),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static PriceTrend _trend(String? value) => switch (value) {
    'up' => PriceTrend.up,
    'down' => PriceTrend.down,
    'stable' => PriceTrend.stable,
    // An unrecognised direction is treated as no comparison rather than
    // guessed at, so a future backend value cannot render as a wrong arrow.
    _ => PriceTrend.unknown,
  };
}
