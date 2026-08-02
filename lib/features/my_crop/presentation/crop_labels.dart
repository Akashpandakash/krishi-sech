import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/l10n/l10n.dart';

String cropKindLabel(BuildContext context, Crop crop) =>
    crop.kind == CropKind.other && crop.customName?.trim().isNotEmpty == true
    ? crop.customName!.trim()
    : switch (crop.kind) {
        CropKind.paddy => context.l10n.cropPaddy,
        CropKind.wheat => context.l10n.cropWheat,
        CropKind.maize => context.l10n.cropMaize,
        CropKind.tomato => context.l10n.cropTomato,
        CropKind.brinjal => context.l10n.cropBrinjal,
        CropKind.chilli => context.l10n.cropChilli,
        CropKind.mustard => context.l10n.cropMustard,
        CropKind.potato => context.l10n.cropPotato,
        CropKind.onion => context.l10n.cropOnion,
        CropKind.other => context.l10n.cropOther,
      };

String cropKindOptionLabel(BuildContext context, CropKind kind) =>
    cropKindLabel(
      context,
      Crop(
        id: '',
        kind: kind,
        variety: '',
        sowingDate: DateTime.now(),
        landArea: 1,
        landAreaUnit: LandAreaUnit.acre,
        growthStage: GrowthStage.sowing,
        irrigationType: IrrigationType.manual,
      ),
    );

String growthStageLabel(BuildContext context, GrowthStage stage) =>
    switch (stage) {
      GrowthStage.sowing => context.l10n.stageSowing,
      GrowthStage.germination => context.l10n.stageGermination,
      GrowthStage.seedling => context.l10n.stageSeedling,
      GrowthStage.vegetative => context.l10n.stageVegetative,
      GrowthStage.flowering => context.l10n.stageFlowering,
      GrowthStage.fruiting => context.l10n.stageFruiting,
      GrowthStage.maturity => context.l10n.stageMaturity,
      GrowthStage.harvested => context.l10n.stageHarvested,
    };

String cropHealthLabel(BuildContext context, CropHealth health) =>
    switch (health) {
      CropHealth.healthy => context.l10n.healthHealthy,
      CropHealth.moderate => context.l10n.healthModerate,
      CropHealth.needsAttention => context.l10n.healthNeedsAttention,
    };

String areaUnitLabel(BuildContext context, LandAreaUnit unit) => switch (unit) {
  LandAreaUnit.acre => context.l10n.unitAcre,
  LandAreaUnit.hectare => context.l10n.unitHectare,
  LandAreaUnit.bigha => context.l10n.unitBigha,
  LandAreaUnit.katha => context.l10n.unitKatha,
};

String irrigationLabel(BuildContext context, IrrigationType type) =>
    switch (type) {
      IrrigationType.drip => context.l10n.irrigationDrip,
      IrrigationType.sprinkler => context.l10n.irrigationSprinkler,
      IrrigationType.flood => context.l10n.irrigationFlood,
      IrrigationType.rainFed => context.l10n.irrigationRainFed,
      IrrigationType.manual => context.l10n.irrigationManual,
    };

String cropTaskLabel(BuildContext context, CropTaskType task) => switch (task) {
  CropTaskType.irrigation => context.l10n.taskIrrigationReminder,
  CropTaskType.fertilizer => context.l10n.taskFertilizerReminder,
  CropTaskType.pestInspection => context.l10n.taskPestInspection,
  CropTaskType.harvestPreparation => context.l10n.taskHarvestPreparation,
  CropTaskType.completed => context.l10n.taskCompleted,
};
