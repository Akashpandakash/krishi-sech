import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class CropCalendarPage extends StatefulWidget {
  const CropCalendarPage({super.key});

  @override
  State<CropCalendarPage> createState() => _CropCalendarPageState();
}

class _CropCalendarPageState extends State<CropCalendarPage> {
  late DateTime _selectedDate;
  bool _loadStarted = false;
  bool _initialRefreshFinished = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    final cropController = CropScope.of(context);
    final taskController = CropTaskScope.of(context);
    try {
      await cropController.refresh();
      if (!mounted || cropController.savedCrops.isEmpty) return;
      await taskController.refresh();
    } finally {
      if (mounted) setState(() => _initialRefreshFinished = true);
    }
  }

  Future<void> _openAddCrop() async {
    await Navigator.of(context).pushNamed(AppRoutes.addCrop);
    if (mounted) await _refresh();
  }

  Future<void> _delete(CropTask task) async {
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
    if (confirmed == true && mounted) {
      await CropTaskScope.of(context).deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropController = CropScope.of(context);
    final taskController = CropTaskScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cropCalendar)),
      floatingActionButton: AnimatedBuilder(
        animation: Listenable.merge([cropController, taskController]),
        builder: (context, _) {
          final loading = cropController.isLoading || taskController.isLoading;
          final error = cropController.error ?? taskController.error;
          if (cropController.savedCrops.isEmpty || loading || error != null) {
            return const SizedBox.shrink();
          }
          return AppPressable(
            child: FloatingActionButton.extended(
              key: const Key('add_crop_task_button'),
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.addCropTask, arguments: _selectedDate),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addTask),
            ),
          );
        },
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([cropController, taskController]),
          builder: (context, _) {
            final savedCrops = cropController.savedCrops;
            if (savedCrops.isEmpty &&
                (!_initialRefreshFinished || cropController.isLoading)) {
              return _CalendarMessage(
                key: const Key('crop_calendar_empty_state'),
                icon: Icons.eco_outlined,
                message: context.l10n.noCropsYet,
                buttonLabel: context.l10n.addCrop,
                onPressed: _openAddCrop,
              );
            }
            if (cropController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (cropController.error != null) {
              return _CalendarMessage(
                icon: Icons.error_outline,
                message: context.l10n.cropCalendarLoadError,
                buttonLabel: context.l10n.retry,
                onPressed: _refresh,
              );
            }
            if (savedCrops.isEmpty) {
              return _CalendarMessage(
                key: const Key('crop_calendar_empty_state'),
                icon: Icons.eco_outlined,
                message: context.l10n.noCropsYet,
                buttonLabel: context.l10n.addCrop,
                onPressed: _openAddCrop,
              );
            }
            if (taskController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (taskController.error != null) {
              return _CalendarMessage(
                icon: Icons.error_outline,
                message: context.l10n.cropCalendarLoadError,
                buttonLabel: context.l10n.retry,
                onPressed: _refresh,
              );
            }

            final selectedTasks = taskController.tasksForDate(_selectedDate);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ResponsiveContent(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  children: [
                    if (taskController.tasks.isEmpty) ...[
                      Card(
                        key: const Key('crop_calendar_no_tasks_state'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.l10n.noCropTasksScheduled,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _TaskCalendar(
                      selectedDate: _selectedDate,
                      tasks: taskController.tasks,
                      onDateSelected: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                    const SizedBox(height: 22),
                    _TaskSection(
                      key: const Key('selected_date_tasks'),
                      itemKeyPrefix: 'selected',
                      title: context.l10n.tasksForSelectedDate,
                      tasks: selectedTasks,
                      emptyMessage: context.l10n.noTasksForDate,
                      onToggle: taskController.toggleCompleted,
                      onEdit: (task) => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editCropTask, arguments: task.id),
                      onDelete: _delete,
                    ),
                    const SizedBox(height: 22),
                    _TaskSection(
                      title: context.l10n.todaysTasks,
                      tasks: taskController.todaysTasks,
                      emptyMessage: context.l10n.noTasksToday,
                      onToggle: taskController.toggleCompleted,
                      onEdit: (task) => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editCropTask, arguments: task.id),
                      onDelete: _delete,
                    ),
                    const SizedBox(height: 22),
                    _TaskSection(
                      title: context.l10n.upcomingCropTasks,
                      tasks: taskController.upcomingTasks,
                      emptyMessage: context.l10n.noUpcomingCropTasks,
                      onToggle: taskController.toggleCompleted,
                      onEdit: (task) => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editCropTask, arguments: task.id),
                      onDelete: _delete,
                    ),
                    const SizedBox(height: 22),
                    _TaskSection(
                      title: context.l10n.completedTasks,
                      tasks: taskController.completedTasks,
                      emptyMessage: context.l10n.noCompletedTasks,
                      onToggle: taskController.toggleCompleted,
                      onEdit: (task) => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editCropTask, arguments: task.id),
                      onDelete: _delete,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _TaskCalendar extends StatefulWidget {
  const _TaskCalendar({
    required this.selectedDate,
    required this.tasks,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<CropTask> tasks;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<_TaskCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateUtils.addMonthsToMonthDate(_visibleMonth, delta);
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    setState(() => _visibleMonth = DateTime(date.year, date.month));
    widget.onDateSelected(date);
  }

  bool _hasTasks(DateTime date) =>
      widget.tasks.any((task) => DateUtils.isSameDay(task.dueDate, date));

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    final weekdays = List.generate(
      7,
      (index) => localizations.narrowWeekdays[(firstDayIndex + index) % 7],
    );
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final leadingDays = (firstOfMonth.weekday % 7 - firstDayIndex + 7) % 7;
    final firstCell = firstOfMonth.subtract(Duration(days: leadingDays));

    return Card(
      key: const Key('crop_task_calendar'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('calendar_previous_month'),
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    localizations.formatMonthYear(_visibleMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  key: const Key('calendar_today_button'),
                  onPressed: _goToToday,
                  child: Text(context.l10n.today),
                ),
                IconButton(
                  key: const Key('calendar_next_month'),
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1.05,
              children: [
                ...weekdays.map(
                  (day) => Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
                ...List.generate(42, (index) {
                  final date = firstCell.add(Duration(days: index));
                  final inMonth = date.month == _visibleMonth.month;
                  final selected = DateUtils.isSameDay(
                    date,
                    widget.selectedDate,
                  );
                  final hasTasks = _hasTasks(date);
                  return AppPressable(
                    key: ValueKey(
                      'calendar_day_${date.year}_${date.month}_${date.day}',
                    ),
                    haptic: AppPressableHaptic.selection,
                    onTap: () => widget.onDateSelected(date),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? AppColors.primary : null,
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : inMonth
                                  ? null
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.45),
                              fontWeight: selected ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                          child: hasTasks
                              ? Container(
                                  key: ValueKey(
                                    'task_indicator_${date.year}_${date.month}_${date.day}',
                                  ),
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.tasks,
    required this.emptyMessage,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.itemKeyPrefix = 'task',
    super.key,
  });

  final String title;
  final List<CropTask> tasks;
  final String emptyMessage;
  final ValueChanged<String> onToggle;
  final ValueChanged<CropTask> onEdit;
  final ValueChanged<CropTask> onDelete;
  final String itemKeyPrefix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      if (tasks.isEmpty)
        _EmptyTasks(message: emptyMessage)
      else
        ...tasks.map(
          (task) => _CropTaskTile(
            widgetKey: ValueKey('${itemKeyPrefix}_${task.id}'),
            task: task,
            onToggle: () => onToggle(task.id),
            onEdit: () => onEdit(task),
            onDelete: () => onDelete(task),
          ),
        ),
    ],
  );
}

class _CropTaskTile extends StatelessWidget {
  const _CropTaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.widgetKey,
  });

  final CropTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Key? widgetKey;

  @override
  Widget build(BuildContext context) {
    final crop = CropScope.of(context).cropById(task.cropId);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: AppPressable(
        key: widgetKey ?? ValueKey('crop_task_${task.id}'),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 4, 7),
          child: Row(
            children: [
              Checkbox(value: task.isCompleted, onChanged: (_) => onToggle()),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cropTaskReminderIcon(task.type),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropTaskReminderLabel(context, task.type),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      [
                        if (crop != null) cropKindLabel(context, crop),
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(task.dueDate),
                        if (task.isCompleted) context.l10n.taskCompleted,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if ((task.notes ?? '').isNotEmpty)
                      Text(
                        task.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.deleteTask,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.lightGreen.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_available_outlined, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _CalendarMessage extends StatelessWidget {
  const _CalendarMessage({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          AppPressable(
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    ),
  );
}
