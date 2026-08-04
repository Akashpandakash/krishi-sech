class SmartRecommendationSnapshot {
  const SmartRecommendationSnapshot({
    this.irrigation,
    this.fertilizer,
    this.diseaseSeverity,
    this.fromCache = false,
    this.irrigationFailed = false,
    this.fertilizerFailed = false,
  });
  final IrrigationSummary? irrigation;
  final FertilizerSummary? fertilizer;
  final String? diseaseSeverity;
  final bool fromCache;
  final bool irrigationFailed;
  final bool fertilizerFailed;
  SmartRecommendationSnapshot copyWith({
    IrrigationSummary? irrigation,
    FertilizerSummary? fertilizer,
    String? diseaseSeverity,
    bool? fromCache,
    bool? irrigationFailed,
    bool? fertilizerFailed,
  }) => SmartRecommendationSnapshot(
    irrigation: irrigation ?? this.irrigation,
    fertilizer: fertilizer ?? this.fertilizer,
    diseaseSeverity: diseaseSeverity ?? this.diseaseSeverity,
    fromCache: fromCache ?? this.fromCache,
    irrigationFailed: irrigationFailed ?? this.irrigationFailed,
    fertilizerFailed: fertilizerFailed ?? this.fertilizerFailed,
  );
}

class IrrigationSummary {
  const IrrigationSummary({
    required this.required,
    required this.quantityLiters,
    required this.method,
    required this.nextDate,
    required this.confidence,
  });
  final bool required;
  final int quantityLiters;
  final String method;
  final DateTime nextDate;
  final double confidence;
  factory IrrigationSummary.fromJson(Map<String, dynamic> json) {
    final quantity = json['waterQuantity'] as Map<String, dynamic>;
    return IrrigationSummary(
      required: json['irrigationRequired'] as bool,
      quantityLiters: (quantity['value'] as num).round(),
      method: json['irrigationMethod'] as String,
      nextDate: DateTime.parse(json['nextIrrigationDate'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
  Map<String, dynamic> toJson() => {
    'irrigationRequired': required,
    'waterQuantity': {'value': quantityLiters},
    'irrigationMethod': method,
    'nextIrrigationDate': nextDate.toIso8601String(),
    'confidence': confidence,
  };
}

class FertilizerSummary {
  const FertilizerSummary({
    required this.name,
    required this.quantity,
    required this.nextDate,
    required this.confidence,
  });
  final String name;
  final String quantity;
  final DateTime nextDate;
  final double confidence;
  factory FertilizerSummary.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'] as Map<String, dynamic>;
    return FertilizerSummary(
      name: json['recommendedFertilizer'] as String,
      quantity: '${quantity['value']} ${quantity['unit']}/${quantity['per']}',
      nextDate: DateTime.parse(json['nextRecommendationDate'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
  Map<String, dynamic> toJson() => {
    'recommendedFertilizer': name,
    'quantityLabel': quantity,
    'nextRecommendationDate': nextDate.toIso8601String(),
    'confidence': confidence,
  };
  factory FertilizerSummary.fromCache(Map<String, dynamic> json) =>
      FertilizerSummary(
        name: json['recommendedFertilizer'] as String,
        quantity: json['quantityLabel'] as String,
        nextDate: DateTime.parse(json['nextRecommendationDate'] as String),
        confidence: (json['confidence'] as num).toDouble(),
      );
}
