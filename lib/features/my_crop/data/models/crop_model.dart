import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';

class CropModel {
  const CropModel({
    required this.id,
    required this.userId,
    required this.cropType,
    required this.variety,
    required this.sowingDate,
    required this.landArea,
    required this.landAreaUnit,
    required this.growthStage,
    required this.healthStatus,
    required this.irrigationType,
    required this.soilType,
    required this.plantingMethod,
    required this.createdAt,
    required this.updatedAt,
    this.customName,
    this.farmName,
    this.expectedHarvestDate,
    this.notes,
    this.seedBrand,
    this.lastFertilizerUsed,
    this.lastPesticideUsed,
  });

  final String id;
  final String userId;
  final String cropType;
  final String? customName;
  final String variety;
  final DateTime sowingDate;
  final double landArea;
  final String landAreaUnit;
  final String growthStage;
  final String healthStatus;
  final String irrigationType;
  final String soilType;
  final String plantingMethod;
  final String? seedBrand;
  final String? lastFertilizerUsed;
  final String? lastPesticideUsed;
  final String? farmName;
  final DateTime? expectedHarvestDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CropModel.fromEntity(Crop crop) => CropModel(
    id: crop.id,
    userId: crop.userId,
    cropType: crop.kind.name,
    customName: crop.customName,
    variety: crop.variety,
    sowingDate: crop.sowingDate,
    landArea: crop.landArea,
    landAreaUnit: crop.landAreaUnit.name,
    growthStage: crop.growthStage.name,
    healthStatus: crop.health.name,
    irrigationType: crop.irrigationType.name,
    soilType: crop.soilType.name,
    plantingMethod: crop.plantingMethod.name,
    seedBrand: crop.seedBrand,
    lastFertilizerUsed: crop.lastFertilizerUsed,
    lastPesticideUsed: crop.lastPesticideUsed,
    farmName: crop.farmName,
    expectedHarvestDate: crop.expectedHarvestDate,
    notes: crop.notes,
    createdAt: crop.createdAt,
    updatedAt: crop.updatedAt,
  );

  factory CropModel.fromJson(Map<String, dynamic> json) {
    final sowingDate = DateTime.parse(json['sowingDate'] as String);
    final cropName = json['cropName'] as String?;
    final cropType =
        json['cropType'] as String? ??
        json['kind'] as String? ??
        _kindFromCropName(cropName).name;
    return CropModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? 'local-user',
      cropType: cropType,
      customName:
          json['customName'] as String? ??
          (_kindFromCropName(cropName) == CropKind.other ? cropName : null),
      variety: json['variety'] as String? ?? '',
      sowingDate: sowingDate,
      landArea: (json['landArea'] as num).toDouble(),
      landAreaUnit:
          json['landAreaUnit'] as String? ?? json['landUnit'] as String,
      growthStage: json['growthStage'] as String,
      healthStatus: json['healthStatus'] as String? ?? json['health'] as String,
      irrigationType:
          json['irrigationType'] as String? ??
          json['irrigationMethod'] as String,
      soilType: json['soilType'] as String? ?? SoilType.other.name,
      plantingMethod:
          json['plantingMethod'] as String? ?? PlantingMethod.other.name,
      seedBrand: json['seedBrand'] as String?,
      lastFertilizerUsed: json['lastFertilizerUsed'] as String?,
      lastPesticideUsed: json['lastPesticideUsed'] as String?,
      farmName: json['farmName'] as String?,
      expectedHarvestDate: json['expectedHarvestDate'] == null
          ? null
          : DateTime.parse(json['expectedHarvestDate'] as String),
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? sowingDate,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? sowingDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'cropType': cropType,
    'variety': variety,
    'sowingDate': sowingDate.toIso8601String(),
    'landArea': landArea,
    'landAreaUnit': landAreaUnit,
    'growthStage': growthStage,
    'healthStatus': healthStatus,
    'irrigationType': irrigationType,
    'soilType': soilType,
    'plantingMethod': plantingMethod,
    'seedBrand': seedBrand,
    'lastFertilizerUsed': lastFertilizerUsed,
    'lastPesticideUsed': lastPesticideUsed,
    'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (customName != null) 'customName': customName,
    if (farmName != null) 'farmName': farmName,
  };

  Map<String, dynamic> toApiJson() => {
    'cropName': customName?.trim().isNotEmpty == true
        ? customName!.trim()
        : _displayCropName(cropType),
    'variety': variety,
    'sowingDate': sowingDate.toUtc().toIso8601String(),
    'growthStage': growthStage,
    'landArea': landArea,
    'landUnit': landAreaUnit,
    'soilType': soilType,
    'irrigationMethod': irrigationType,
    'expectedHarvestDate': expectedHarvestDate?.toUtc().toIso8601String(),
    'healthStatus': healthStatus,
    'notes': notes,
  };

  CropModel mergeLocalProfile(CropModel? local) => local == null
      ? this
      : CropModel(
          id: id,
          userId: userId,
          cropType: cropType,
          customName: customName,
          variety: variety,
          sowingDate: sowingDate,
          landArea: landArea,
          landAreaUnit: landAreaUnit,
          growthStage: growthStage,
          healthStatus: healthStatus,
          irrigationType: irrigationType,
          soilType: soilType,
          plantingMethod: local.plantingMethod,
          seedBrand: local.seedBrand,
          lastFertilizerUsed: local.lastFertilizerUsed,
          lastPesticideUsed: local.lastPesticideUsed,
          farmName: local.farmName,
          expectedHarvestDate: expectedHarvestDate,
          notes: notes,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  Crop toEntity() => Crop(
    id: id,
    userId: userId,
    kind: CropKind.values.byName(cropType),
    customName: customName,
    variety: variety,
    sowingDate: sowingDate,
    landArea: landArea,
    landAreaUnit: LandAreaUnit.values.byName(landAreaUnit),
    growthStage: GrowthStage.values.byName(growthStage),
    health: CropHealth.values.byName(healthStatus),
    irrigationType: IrrigationType.values.byName(irrigationType),
    soilType: SoilType.values.byName(soilType),
    plantingMethod: PlantingMethod.values.byName(plantingMethod),
    seedBrand: seedBrand,
    lastFertilizerUsed: lastFertilizerUsed,
    lastPesticideUsed: lastPesticideUsed,
    farmName: farmName,
    expectedHarvestDate: expectedHarvestDate,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static CropKind _kindFromCropName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return CropKind.values.firstWhere(
      (kind) => kind.name == normalized,
      orElse: () => CropKind.other,
    );
  }

  static String _displayCropName(String kind) =>
      '${kind[0].toUpperCase()}${kind.substring(1)}';
}
