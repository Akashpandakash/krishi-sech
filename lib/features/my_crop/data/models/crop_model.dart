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
    required this.createdAt,
    required this.updatedAt,
    this.customName,
    this.farmName,
    this.expectedHarvestDate,
    this.notes,
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
    farmName: crop.farmName,
    expectedHarvestDate: crop.expectedHarvestDate,
    notes: crop.notes,
    createdAt: crop.createdAt,
    updatedAt: crop.updatedAt,
  );

  factory CropModel.fromJson(Map<String, dynamic> json) {
    final sowingDate = DateTime.parse(json['sowingDate'] as String);
    return CropModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? 'local-user',
      cropType: json['cropType'] as String? ?? json['kind'] as String,
      customName: json['customName'] as String?,
      variety: json['variety'] as String? ?? '',
      sowingDate: sowingDate,
      landArea: (json['landArea'] as num).toDouble(),
      landAreaUnit: json['landAreaUnit'] as String,
      growthStage: json['growthStage'] as String,
      healthStatus: json['healthStatus'] as String? ?? json['health'] as String,
      irrigationType: json['irrigationType'] as String,
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
    'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (customName != null) 'customName': customName,
    if (farmName != null) 'farmName': farmName,
  };

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
    farmName: farmName,
    expectedHarvestDate: expectedHarvestDate,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
