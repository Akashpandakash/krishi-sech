import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/image_picker_repository.dart';
import 'package:krishi_sech/features/disease_scan/presentation/pages/disease_scan_page.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_health_photo_store.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class CropDetailsPage extends StatelessWidget {
  const CropDetailsPage({required this.cropId, super.key});

  final String cropId;

  Future<void> _edit(BuildContext context, CropController controller) async {
    final updated = await Navigator.of(
      context,
    ).pushNamed<bool>(AppRoutes.editCrop, arguments: cropId);
    if (updated != true || !context.mounted) return;
    // The shared controller is updated before the route returns. Reading it
    // here also guards against a removed crop without issuing a duplicate GET.
    controller.cropById(cropId);
  }

  Future<void> _scanDisease(BuildContext context, Crop crop) async {
    final source = await showModalBottomSheet<_DiseaseImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.scanCrop,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.l10n.takePhoto),
                onTap: () =>
                    Navigator.pop(sheetContext, _DiseaseImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () =>
                    Navigator.pop(sheetContext, _DiseaseImageSource.gallery),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    try {
      final picker = ImagePickerRepository();
      final selected = source == _DiseaseImageSource.camera
          ? await picker.takePhoto()
          : await picker.chooseFromGallery();
      if (selected == null) return;
      final savedPath = await const LocalCropHealthPhotoStore().savePhoto(
        selected,
      );
      if (!context.mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.diseasePreview,
        arguments: DiseaseScanImageArguments(
          imagePath: savedPath,
          cropId: crop.id,
          cropName: cropKindLabel(context, crop),
        ),
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      final denied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            denied
                ? context.l10n.imagePermissionDenied
                : context.l10n.imageCouldNotBeOpened,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imageCouldNotBeOpened)),
      );
    }
  }

  Future<void> _delete(BuildContext context, Crop crop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteCrop),
        content: Text(context.l10n.deleteCropConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_crop'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await CropScope.of(context).deleteCrop(crop.id);
    if (context.mounted && deleted) Navigator.of(context).pop();
  }

  Future<void> _updateHealth(BuildContext context, Crop crop) async {
    final value = await showDialog<CropHealth>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.healthStatus),
        children: CropHealth.values
            .map(
              (health) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, health),
                child: Text(cropHealthLabel(context, health)),
              ),
            )
            .toList(),
      ),
    );
    if (value != null && context.mounted) {
      await CropScope.of(context).setHealth(crop.id, value);
    }
  }

  Future<void> _updateStage(BuildContext context, Crop crop) async {
    final value = await showDialog<GrowthStage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.updateGrowthStage),
        children: GrowthStage.values
            .map(
              (stage) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, stage),
                child: Text(growthStageLabel(context, stage)),
              ),
            )
            .toList(),
      ),
    );
    if (value != null && context.mounted) {
      await CropScope.of(context).setGrowthStage(crop.id, value);
    }
  }

  Future<void> _deleteTask(BuildContext context, CropTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteTask),
        content: Text(context.l10n.deleteTaskConfirmation),
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
      await CropTaskScope.of(context).deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CropScope.of(context);
    final taskController = CropTaskScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([controller, taskController]),
      builder: (context, _) {
        final crop = controller.cropById(cropId);
        if (crop == null) {
          return Scaffold(body: Center(child: Text(context.l10n.cropNotFound)));
        }
        final date = MaterialLocalizations.of(context);
        final timeline = taskController.tasksForCrop(crop.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.cropDetails),
            actions: [
              IconButton(
                key: const Key('edit_crop_action'),
                onPressed: () => _edit(context, controller),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: const Key('delete_crop_action'),
                onPressed: () => _delete(context, crop),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.lightGreen,
                          child: Icon(
                            Icons.eco,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cropKindLabel(context, crop),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(crop.variety.isEmpty ? '—' : crop.variety),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Detail(
                      context.l10n.sowingDate,
                      date.formatMediumDate(crop.sowingDate),
                    ),
                    _Detail(
                      context.l10n.plantAge,
                      context.l10n.daysOld(crop.plantAgeInDays),
                    ),
                    _Detail(
                      context.l10n.currentGrowthStage,
                      growthStageLabel(context, crop.growthStage),
                    ),
                    _Detail(
                      context.l10n.soilType,
                      soilTypeLabel(context, crop.soilType),
                    ),
                    _Detail(
                      context.l10n.irrigationMethod,
                      irrigationLabel(context, crop.irrigationType),
                    ),
                    _Detail(
                      context.l10n.plantingMethod,
                      plantingMethodLabel(context, crop.plantingMethod),
                    ),
                    _Detail(
                      context.l10n.landArea,
                      '${crop.landArea} ${areaUnitLabel(context, crop.landAreaUnit)}',
                    ),
                    _Detail(
                      context.l10n.healthStatus,
                      cropHealthLabel(context, crop.health),
                    ),
                    _Detail(
                      context.l10n.growthProgress,
                      '${crop.progressPercent}%',
                    ),
                    _Detail(
                      context.l10n.nextAction,
                      cropTaskLabel(context, crop.nextTask),
                    ),
                    _Detail(
                      context.l10n.seedBrand,
                      crop.seedBrand ?? context.l10n.notAvailable,
                    ),
                    _Detail(
                      context.l10n.lastFertilizerUsed,
                      crop.lastFertilizerUsed ?? context.l10n.notAvailable,
                    ),
                    _Detail(
                      context.l10n.lastPesticideUsed,
                      crop.lastPesticideUsed ?? context.l10n.notAvailable,
                    ),
                    _Detail(
                      context.l10n.expectedHarvestDate,
                      crop.expectedHarvestDate == null
                          ? context.l10n.notAvailable
                          : date.formatMediumDate(crop.expectedHarvestDate!),
                    ),
                    _Detail(
                      context.l10n.notes,
                      crop.notes ?? context.l10n.notAvailable,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      key: const Key('scan_crop_disease'),
                      onPressed: () => _scanDisease(context, crop),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(context.l10n.scanCrop),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('crop_health_records'),
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.cropHealthRecords,
                        arguments: crop.id,
                      ),
                      icon: const Icon(Icons.history),
                      label: Text(context.l10n.cropHealthRecord),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.cropTimeline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (timeline.isEmpty)
                      Text(context.l10n.noCropTimelineTasks)
                    else
                      ...timeline.map(
                        (task) => _TimelineTask(
                          task: task,
                          onCompleted: () =>
                              taskController.toggleCompleted(task.id),
                          onEdit: () => Navigator.of(context).pushNamed(
                            AppRoutes.editCropTask,
                            arguments: task.id,
                          ),
                          onDelete: () => _deleteTask(context, task),
                        ),
                      ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      key: const Key('update_crop_health'),
                      onPressed: () => _updateHealth(context, crop),
                      icon: const Icon(Icons.health_and_safety_outlined),
                      label: Text(context.l10n.updateHealthStatus),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('update_crop_stage'),
                      onPressed: () => _updateStage(context, crop),
                      icon: const Icon(Icons.trending_up),
                      label: Text(context.l10n.updateGrowthStage),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _edit(context, controller),
                      icon: const Icon(Icons.edit),
                      label: Text(context.l10n.editCrop),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _DiseaseImageSource { camera, gallery }

class _TimelineTask extends StatelessWidget {
  const _TimelineTask({
    required this.task,
    required this.onCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  final CropTask task;
  final VoidCallback onCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) => onCompleted(),
      ),
      title: Text(
        cropTaskReminderLabel(context, task.type),
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        MaterialLocalizations.of(context).formatMediumDate(task.dueDate),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.editTask,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: context.l10n.deleteTask,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      title: Text(label),
      trailing: SizedBox(
        width: 180,
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}
