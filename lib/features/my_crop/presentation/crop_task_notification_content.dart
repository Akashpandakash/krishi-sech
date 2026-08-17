import 'package:flutter/widgets.dart';
import 'package:krishi_sech/core/localization/app_date_format.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

class CropTaskNotificationContent {
  const CropTaskNotificationContent({required this.title, required this.body});

  final String title;
  final String body;
}

CropTaskNotificationContent buildCropTaskNotificationContent({
  required Crop crop,
  required CropTask task,
  required String languageCode,
}) {
  final locale = Locale(languageCode);
  final l10n = lookupAppLocalizations(locale);
  final cropName = switch (crop.kind) {
    CropKind.paddy => l10n.cropPaddy,
    CropKind.wheat => l10n.cropWheat,
    CropKind.maize => l10n.cropMaize,
    CropKind.tomato => l10n.cropTomato,
    CropKind.brinjal => l10n.cropBrinjal,
    CropKind.chilli => l10n.cropChilli,
    CropKind.mustard => l10n.cropMustard,
    CropKind.potato => l10n.cropPotato,
    CropKind.onion => l10n.cropOnion,
    CropKind.other => crop.customName ?? l10n.cropOther,
  };
  final taskName = switch (task.type) {
    CropTaskReminderType.irrigation => l10n.irrigationTask,
    CropTaskReminderType.fertilizer => l10n.fertilizerTask,
    CropTaskReminderType.pestInspection => l10n.pestInspectionTask,
    CropTaskReminderType.harvest => l10n.harvestTask,
  };
  final dueTime = AppDateFormat.time(languageCode).format(task.dueDate);
  return CropTaskNotificationContent(
    title: l10n.cropTaskNotificationTitle,
    body: l10n.cropTaskNotificationBody(cropName, taskName, dueTime),
  );
}
