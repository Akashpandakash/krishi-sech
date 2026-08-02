import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class CropDetailsPage extends StatelessWidget {
  const CropDetailsPage({required this.cropId, super.key});

  final String cropId;

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
    await CropScope.of(context).deleteCrop(crop.id);
    if (context.mounted) Navigator.of(context).pop();
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
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.editCrop, arguments: crop.id),
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
                      context.l10n.cropAge,
                      context.l10n.daysOld(crop.ageInDays),
                    ),
                    _Detail(
                      context.l10n.currentGrowthStage,
                      growthStageLabel(context, crop.growthStage),
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
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editCrop, arguments: crop.id),
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
