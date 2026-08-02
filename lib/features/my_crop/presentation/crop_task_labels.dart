import 'package:flutter/material.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/l10n/l10n.dart';

String cropTaskReminderLabel(BuildContext context, CropTaskReminderType type) =>
    switch (type) {
      CropTaskReminderType.irrigation => context.l10n.irrigationTask,
      CropTaskReminderType.fertilizer => context.l10n.fertilizerTask,
      CropTaskReminderType.pestInspection => context.l10n.pestInspectionTask,
      CropTaskReminderType.harvest => context.l10n.harvestTask,
    };

IconData cropTaskReminderIcon(CropTaskReminderType type) => switch (type) {
  CropTaskReminderType.irrigation => Icons.water_drop_outlined,
  CropTaskReminderType.fertilizer => Icons.compost_outlined,
  CropTaskReminderType.pestInspection => Icons.bug_report_outlined,
  CropTaskReminderType.harvest => Icons.agriculture_outlined,
};

String taskReminderTimeLabel(BuildContext context, TaskReminderTime reminder) =>
    switch (reminder) {
      TaskReminderTime.atDueTime => context.l10n.reminderAtDueTime,
      TaskReminderTime.thirtyMinutesBefore =>
        context.l10n.reminderThirtyMinutesBefore,
      TaskReminderTime.oneHourBefore => context.l10n.reminderOneHourBefore,
      TaskReminderTime.oneDayBefore => context.l10n.reminderOneDayBefore,
      TaskReminderTime.none => context.l10n.reminderNone,
    };
