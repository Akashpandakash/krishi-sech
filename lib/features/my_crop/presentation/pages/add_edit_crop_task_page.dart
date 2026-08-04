import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class AddEditCropTaskPage extends StatefulWidget {
  const AddEditCropTaskPage({this.taskId, this.initialDate, super.key});

  final String? taskId;
  final DateTime? initialDate;

  @override
  State<AddEditCropTaskPage> createState() => _AddEditCropTaskPageState();
}

class _AddEditCropTaskPageState extends State<AddEditCropTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _cropId;
  CropTaskReminderType? _type;
  DateTime? _dueDate;
  TaskReminderTime _reminderTime = TaskReminderTime.atDueTime;
  CropTask? _existing;
  bool _saving = false;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    final initialDate = widget.initialDate;
    _dueDate = initialDate == null
        ? null
        : DateTime(initialDate.year, initialDate.month, initialDate.day, 7);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing && _existing == null) {
      _existing = CropTaskScope.of(context).taskById(widget.taskId!);
      final task = _existing;
      if (task != null) {
        _cropId = task.cropId;
        _type = task.type;
        _dueDate = task.dueDate;
        _reminderTime = task.reminderTime;
        _notesController.text = task.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (result != null) {
      final current = _dueDate;
      setState(
        () => _dueDate = DateTime(
          result.year,
          result.month,
          result.day,
          current?.hour ?? 7,
          current?.minute ?? 0,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _dueDate == null
          ? const TimeOfDay(hour: 7, minute: 0)
          : TimeOfDay.fromDateTime(_dueDate!),
    );
    if (result == null || _dueDate == null) return;
    setState(
      () => _dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        result.hour,
        result.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final controller = CropTaskScope.of(context);
    final now = DateTime.now();
    final notes = _notesController.text.trim();
    if (_existing == null) {
      await controller.addTask(
        CropTask(
          id: 'task-${now.microsecondsSinceEpoch}',
          cropId: _cropId!,
          type: _type!,
          dueDate: _dueDate!,
          notes: notes.isEmpty ? null : notes,
          reminderTime: _reminderTime,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await controller.updateTask(
        _existing!.copyWith(
          cropId: _cropId,
          type: _type,
          dueDate: _dueDate,
          notes: notes,
          isCustomized: true,
          reminderTime: _reminderTime,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final crops = CropScope.of(context).savedCrops;
    final canSave =
        !_saving && _cropId != null && _type != null && _dueDate != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? context.l10n.editTask : context.l10n.addTask),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('task_crop_field'),
                  initialValue: _cropId,
                  decoration: InputDecoration(labelText: context.l10n.cropName),
                  items: crops
                      .map(
                        (crop) => DropdownMenuItem(
                          key: ValueKey('task_crop_option_${crop.id}'),
                          value: crop.id,
                          child: Text(cropKindLabel(context, crop)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _cropId = value),
                  validator: (value) =>
                      value == null ? context.l10n.selectCropForTask : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CropTaskReminderType>(
                  key: const Key('task_type_field'),
                  initialValue: _type,
                  decoration: InputDecoration(labelText: context.l10n.taskType),
                  items: CropTaskReminderType.values
                      .map(
                        (type) => DropdownMenuItem(
                          key: ValueKey('task_type_option_${type.name}'),
                          value: type,
                          child: Text(cropTaskReminderLabel(context, type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _type = value),
                  validator: (value) =>
                      value == null ? context.l10n.selectTaskType : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  key: const Key('task_due_date_field'),
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.dueDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(
                      _dueDate == null
                          ? context.l10n.selectDate
                          : MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(_dueDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  key: const Key('task_due_time_field'),
                  onTap: _dueDate == null ? null : _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.dueTime,
                      suffixIcon: const Icon(Icons.schedule_outlined),
                    ),
                    child: Text(
                      _dueDate == null
                          ? context.l10n.selectDate
                          : MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(_dueDate!),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskReminderTime>(
                  key: const Key('task_reminder_time_field'),
                  initialValue: _reminderTime,
                  decoration: InputDecoration(
                    labelText: context.l10n.reminderTime,
                  ),
                  items: TaskReminderTime.values
                      .map(
                        (reminder) => DropdownMenuItem(
                          value: reminder,
                          child: Text(taskReminderTimeLabel(context, reminder)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _reminderTime = value ?? _reminderTime),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('task_notes_field'),
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.l10n.taskNotes,
                  ),
                ),
                const SizedBox(height: 24),
                AppPressable(
                  enabled: canSave,
                  haptic: AppPressableHaptic.medium,
                  child: FilledButton.icon(
                    key: const Key('save_task_button'),
                    onPressed: canSave ? _save : null,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(context.l10n.saveTask),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
