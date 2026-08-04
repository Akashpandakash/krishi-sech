import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/l10n/l10n.dart';

String cropHealthRecordTypeLabel(
  BuildContext context,
  CropHealthRecordType type,
) => switch (type) {
  CropHealthRecordType.disease => context.l10n.diseaseHistory,
  CropHealthRecordType.fertilizer => context.l10n.fertilizerHistory,
  CropHealthRecordType.irrigation => context.l10n.irrigationHistory,
  CropHealthRecordType.spray => context.l10n.sprayHistory,
  CropHealthRecordType.scan => context.l10n.scanHistory,
  CropHealthRecordType.note => context.l10n.notes,
  CropHealthRecordType.photo => context.l10n.photoHistory,
};
