enum CropKind {
  paddy,
  wheat,
  maize,
  tomato,
  brinjal,
  chilli,
  mustard,
  potato,
  onion,
  other,
}

enum GrowthStage {
  sowing,
  germination,
  seedling,
  vegetative,
  flowering,
  fruiting,
  maturity,
  harvested,
}

enum CropHealth { healthy, moderate, needsAttention }

enum LandAreaUnit { acre, hectare, bigha, katha }

enum IrrigationType { drip, sprinkler, flood, rainFed, manual }

enum SoilType { alluvial, black, red, laterite, sandy, clay, loamy, other }

enum PlantingMethod {
  directSowing,
  transplanting,
  broadcasting,
  raisedBed,
  other,
}

enum CropTaskType {
  irrigation,
  fertilizer,
  pestInspection,
  harvestPreparation,
  completed,
}

class Crop {
  const Crop({
    required this.id,
    required this.kind,
    required this.variety,
    required this.sowingDate,
    required this.landArea,
    required this.landAreaUnit,
    required this.growthStage,
    required this.irrigationType,
    this.userId = 'local-user',
    this.customName,
    this.farmName,
    this.soilType = SoilType.other,
    this.plantingMethod = PlantingMethod.other,
    this.seedBrand,
    this.lastFertilizerUsed,
    this.lastPesticideUsed,
    this.expectedHarvestDate,
    this.notes,
    this.health = CropHealth.healthy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? sowingDate,
       updatedAt = updatedAt ?? createdAt ?? sowingDate;

  final String id;
  final String userId;
  final CropKind kind;
  final String? customName;
  final String variety;
  final DateTime sowingDate;
  final double landArea;
  final LandAreaUnit landAreaUnit;
  final GrowthStage growthStage;
  final IrrigationType irrigationType;
  final SoilType soilType;
  final PlantingMethod plantingMethod;
  final String? seedBrand;
  final String? lastFertilizerUsed;
  final String? lastPesticideUsed;
  final String? farmName;
  final DateTime? expectedHarvestDate;
  final String? notes;
  final CropHealth health;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get ageInDays =>
      DateTime.now().difference(sowingDate).inDays.clamp(0, 99999);
  int get plantAgeInDays => ageInDays;
  int get progressPercent => growthStage == GrowthStage.harvested
      ? 100
      : (((growthStage.index + 1) / GrowthStage.values.length) * 100).round();
  CropTaskType get nextTask => switch (growthStage) {
    GrowthStage.sowing || GrowthStage.germination => CropTaskType.irrigation,
    GrowthStage.seedling || GrowthStage.vegetative => CropTaskType.fertilizer,
    GrowthStage.flowering ||
    GrowthStage.fruiting => CropTaskType.pestInspection,
    GrowthStage.maturity => CropTaskType.harvestPreparation,
    GrowthStage.harvested => CropTaskType.completed,
  };
  int get daysUntilNextTask => switch (growthStage) {
    GrowthStage.sowing => 1,
    GrowthStage.germination => 2,
    GrowthStage.seedling => 3,
    GrowthStage.vegetative => 5,
    GrowthStage.flowering => 2,
    GrowthStage.fruiting => 3,
    GrowthStage.maturity => 2,
    GrowthStage.harvested => 0,
  };

  Crop copyWith({
    CropKind? kind,
    String? customName,
    String? variety,
    DateTime? sowingDate,
    double? landArea,
    LandAreaUnit? landAreaUnit,
    GrowthStage? growthStage,
    IrrigationType? irrigationType,
    SoilType? soilType,
    PlantingMethod? plantingMethod,
    String? seedBrand,
    String? lastFertilizerUsed,
    String? lastPesticideUsed,
    String? farmName,
    DateTime? expectedHarvestDate,
    String? notes,
    CropHealth? health,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Crop(
    id: id,
    userId: userId ?? this.userId,
    kind: kind ?? this.kind,
    customName: customName ?? this.customName,
    variety: variety ?? this.variety,
    sowingDate: sowingDate ?? this.sowingDate,
    landArea: landArea ?? this.landArea,
    landAreaUnit: landAreaUnit ?? this.landAreaUnit,
    growthStage: growthStage ?? this.growthStage,
    irrigationType: irrigationType ?? this.irrigationType,
    soilType: soilType ?? this.soilType,
    plantingMethod: plantingMethod ?? this.plantingMethod,
    seedBrand: seedBrand ?? this.seedBrand,
    lastFertilizerUsed: lastFertilizerUsed ?? this.lastFertilizerUsed,
    lastPesticideUsed: lastPesticideUsed ?? this.lastPesticideUsed,
    farmName: farmName ?? this.farmName,
    expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
    notes: notes ?? this.notes,
    health: health ?? this.health,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
