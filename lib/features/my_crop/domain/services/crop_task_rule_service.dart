import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';

class CropTaskRuleService {
  const CropTaskRuleService();

  List<CropTask> generate(Crop crop, {DateTime? generatedAt}) {
    final now = generatedAt ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rules = _rulesFor(crop.kind);
    final currentType = _currentTaskType(crop);

    return CropTaskReminderType.values
        .map((type) {
          final offset = switch (type) {
            CropTaskReminderType.irrigation => rules.irrigationDay,
            CropTaskReminderType.fertilizer => rules.fertilizerDay,
            CropTaskReminderType.pestInspection => rules.pestInspectionDay,
            CropTaskReminderType.harvest => rules.harvestDay,
          };
          var dueDate =
              type == CropTaskReminderType.harvest &&
                  crop.expectedHarvestDate != null
              ? crop.expectedHarvestDate!
              : crop.sowingDate.add(Duration(days: offset));
          dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 7);

          if (type == currentType && !dueDate.isAfter(today)) {
            dueDate = DateTime(today.year, today.month, today.day, 7);
          }

          return CropTask(
            id: 'generated-${crop.id}-${type.name}',
            cropId: crop.id,
            type: type,
            dueDate: dueDate,
            isGenerated: true,
            createdAt: now,
            updatedAt: now,
          );
        })
        .toList(growable: false);
  }

  CropTaskReminderType _currentTaskType(Crop crop) => switch (crop.nextTask) {
    CropTaskType.irrigation => CropTaskReminderType.irrigation,
    CropTaskType.fertilizer => CropTaskReminderType.fertilizer,
    CropTaskType.pestInspection => CropTaskReminderType.pestInspection,
    CropTaskType.harvestPreparation ||
    CropTaskType.completed => CropTaskReminderType.harvest,
  };

  _CropTaskRules _rulesFor(CropKind kind) => switch (kind) {
    CropKind.paddy => const _CropTaskRules(5, 20, 35, 120),
    CropKind.wheat => const _CropTaskRules(20, 25, 45, 125),
    CropKind.maize => const _CropTaskRules(12, 22, 38, 100),
    CropKind.tomato => const _CropTaskRules(7, 18, 28, 90),
    CropKind.brinjal => const _CropTaskRules(7, 20, 30, 105),
    CropKind.chilli => const _CropTaskRules(8, 22, 32, 120),
    CropKind.mustard => const _CropTaskRules(25, 30, 45, 110),
    CropKind.potato => const _CropTaskRules(12, 25, 40, 100),
    CropKind.onion => const _CropTaskRules(10, 25, 40, 120),
    CropKind.other => const _CropTaskRules(10, 25, 40, 120),
  };
}

class _CropTaskRules {
  const _CropTaskRules(
    this.irrigationDay,
    this.fertilizerDay,
    this.pestInspectionDay,
    this.harvestDay,
  );

  final int irrigationDay;
  final int fertilizerDay;
  final int pestInspectionDay;
  final int harvestDay;
}
