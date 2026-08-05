class FarmProfile {
  const FarmProfile({
    required this.farmName,
    required this.farmerType,
    required this.totalLandArea,
    required this.landUnit,
    required this.soilType,
    required this.irrigationSource,
    required this.mainCrops,
    this.coarseLocation,
    this.updatedAt,
  });
  final String farmName;
  final String farmerType;
  final double totalLandArea;
  final String landUnit;
  final String soilType;
  final String irrigationSource;
  final List<String> mainCrops;
  final String? coarseLocation;
  final DateTime? updatedAt;
  Map<String, dynamic> toJson() => {
    'farmName': farmName,
    'farmerType': farmerType,
    'totalLandArea': totalLandArea,
    'landUnit': landUnit,
    'soilType': soilType,
    'irrigationSource': irrigationSource,
    'mainCrops': mainCrops,
    'coarseLocation': coarseLocation,
    'updatedAt': updatedAt?.toIso8601String(),
  };
  factory FarmProfile.fromJson(Map<String, dynamic> json) => FarmProfile(
    farmName: json['farmName'] as String,
    farmerType: json['farmerType'] as String,
    totalLandArea: (json['totalLandArea'] as num).toDouble(),
    landUnit: json['landUnit'] as String,
    soilType: json['soilType'] as String,
    irrigationSource: json['irrigationSource'] as String,
    mainCrops: (json['mainCrops'] as List? ?? const []).cast<String>(),
    coarseLocation: json['coarseLocation'] as String?,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}
