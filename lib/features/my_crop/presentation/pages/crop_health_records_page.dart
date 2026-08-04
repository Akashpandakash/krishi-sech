import 'dart:io';

import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_health_record_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_health_record_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/add_edit_crop_health_record_page.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class CropHealthRecordsPage extends StatelessWidget {
  const CropHealthRecordsPage({super.key, required this.cropId});

  final String cropId;

  Future<void> _delete(BuildContext context, CropHealthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteRecord),
        content: Text(context.l10n.deleteRecordConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await CropHealthRecordScope.of(context).deleteRecord(record.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CropHealthRecordScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cropHealthRecord)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_health_record'),
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.addCropHealthRecord,
          arguments: CropHealthRecordFormArguments(cropId: cropId),
        ),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addRecord),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final records = controller.recordsForCrop(cropId);
          return SafeArea(
            child: ResponsiveContent(
              child: records.isEmpty
                  ? Center(child: Text(context.l10n.noHealthRecords))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Card(
                          child: ListTile(
                            leading: _RecordLeading(record: record),
                            title: Text(record.title),
                            subtitle: Text(
                              '${cropHealthRecordTypeLabel(context, record.type)} • '
                              '${MaterialLocalizations.of(context).formatMediumDate(record.occurredAt)}'
                              '${record.details == null ? '' : '\n${record.details}'}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.editCropHealthRecord,
                                    arguments: CropHealthRecordFormArguments(
                                      cropId: cropId,
                                      recordId: record.id,
                                    ),
                                  );
                                } else {
                                  _delete(context, record);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(context.l10n.editRecord),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(context.l10n.deleteRecord),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _RecordLeading extends StatelessWidget {
  const _RecordLeading({required this.record});

  final CropHealthRecord record;

  @override
  Widget build(BuildContext context) {
    final path = record.photoPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          cacheWidth: 192,
          cacheHeight: 192,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(child: Icon(_iconFor(record.type)));
  }

  IconData _iconFor(CropHealthRecordType type) => switch (type) {
    CropHealthRecordType.disease => Icons.coronavirus_outlined,
    CropHealthRecordType.fertilizer => Icons.science_outlined,
    CropHealthRecordType.irrigation => Icons.water_drop_outlined,
    CropHealthRecordType.spray => Icons.sanitizer_outlined,
    CropHealthRecordType.scan => Icons.document_scanner_outlined,
    CropHealthRecordType.note => Icons.notes_outlined,
    CropHealthRecordType.photo => Icons.photo_outlined,
  };
}
