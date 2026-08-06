import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:krishi_sech/core/notifications/notification_service.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_task_repository.dart';
import 'package:krishi_sech/features/my_crop/domain/services/crop_task_rule_service.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_notification_content.dart';

class CropTaskController extends ChangeNotifier {
  CropTaskController._({
    required this.cropController,
    required this.notificationService,
    required this.languageCodeProvider,
    required this.operationTimeout,
    this.repository,
  });

  final CropController cropController;
  final CropTaskRepository? repository;
  final NotificationService notificationService;
  final String Function() languageCodeProvider;
  final Duration operationTimeout;
  final CropTaskRuleService _ruleService = const CropTaskRuleService();
  final List<CropTask> _tasks = [];
  bool _syncing = false;
  bool _syncAgain = false;
  bool _isLoading = false;
  Object? _error;

  List<CropTask> get tasks {
    final result = _tasks.where((task) => !task.isDeleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return List.unmodifiable(result);
  }

  List<CropTask> get todaysTasks {
    final now = DateTime.now();
    return tasks
        .where((task) => !task.isCompleted && _sameDay(task.dueDate, now))
        .toList(growable: false);
  }

  List<CropTask> get upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks
        .where((task) => !task.isCompleted && task.dueDate.isAfter(today))
        .take(5)
        .toList(growable: false);
  }

  List<CropTask> get completedTasks => tasks
      .where((task) => task.isCompleted)
      .toList(growable: false)
      .reversed
      .toList(growable: false);

  int get upcomingCount =>
      _tasks.where((task) => !task.isCompleted && !task.isDeleted).length;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  static Future<CropTaskController> load({
    required CropTaskRepository repository,
    required CropController cropController,
    NotificationService notificationService = const NoopNotificationService(),
    String Function()? languageCodeProvider,
    Duration operationTimeout = const Duration(seconds: 8),
  }) async {
    final controller = CropTaskController._(
      cropController: cropController,
      repository: repository,
      notificationService: notificationService,
      languageCodeProvider: languageCodeProvider ?? () => 'en',
      operationTimeout: operationTimeout,
    );
    controller._tasks.addAll(await repository.getTasks());
    cropController.addListener(controller._onCropsChanged);
    await controller._synchronizeGeneratedTasks();
    unawaited(controller.reschedulePendingNotifications());
    return controller;
  }

  factory CropTaskController.inMemory({
    required CropController cropController,
    List<CropTask> tasks = const [],
    bool generateTasks = true,
    NotificationService notificationService = const NoopNotificationService(),
    String Function()? languageCodeProvider,
    Duration operationTimeout = const Duration(seconds: 8),
  }) {
    final controller = CropTaskController._(
      cropController: cropController,
      notificationService: notificationService,
      languageCodeProvider: languageCodeProvider ?? () => 'en',
      operationTimeout: operationTimeout,
    ).._tasks.addAll(tasks);
    cropController.addListener(controller._onCropsChanged);
    if (generateTasks) controller._generateInMemory();
    return controller;
  }

  CropTask? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  List<CropTask> tasksForDate(DateTime date) => tasks
      .where((task) => _sameDay(task.dueDate, date))
      .toList(growable: false);

  List<CropTask> tasksForCrop(String cropId) =>
      tasks.where((task) => task.cropId == cropId).toList(growable: false);

  Future<void> refresh() async {
    if (repository == null) return;
    _isLoading = true;
    _error = null;
    _logRefresh('loading');
    notifyListeners();
    try {
      await _waitForSynchronization();
      _tasks
        ..clear()
        ..addAll(await repository!.getTasks().timeout(operationTimeout));
      await _synchronizeGeneratedTasks().timeout(operationTimeout);
      _logRefresh('success count=${tasks.length}');
    } catch (error) {
      _error = error;
      _logRefresh('error type=${error.runtimeType}');
    } finally {
      _isLoading = false;
      _logRefresh('complete loading=false');
      notifyListeners();
    }
  }

  void _logRefresh(String transition) {
    if (kDebugMode) debugPrint('CropTaskController.refresh: $transition');
  }

  Future<void> addTask(CropTask task) async {
    var saved = await repository?.addTask(task) ?? task;
    saved = await _ensureNotificationId(saved);
    _tasks.add(saved);
    await _scheduleReminder(saved);
    notifyListeners();
  }

  Future<void> updateTask(CropTask task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    await _cancelReminder(_tasks[index]);
    var updated = task.copyWith(updatedAt: DateTime.now());
    updated = await _ensureNotificationId(updated);
    _tasks[index] = await repository?.updateTask(updated) ?? updated;
    await _scheduleReminder(_tasks[index]);
    notifyListeners();
  }

  Future<void> toggleCompleted(String id) async {
    final task = taskById(id);
    if (task != null) {
      await updateTask(task.copyWith(isCompleted: !task.isCompleted));
    }
  }

  Future<void> deleteTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final task = _tasks[index];
    await _cancelReminder(task);
    if (task.isGenerated) {
      final deleted = task.copyWith(isDeleted: true, updatedAt: DateTime.now());
      _tasks[index] = await repository?.updateTask(deleted) ?? deleted;
    } else {
      _tasks.removeAt(index);
      await repository?.deleteTask(id);
    }
    notifyListeners();
  }

  Future<void> removeTasksForDeletedCrop(String cropId) async {
    final related = _tasks
        .where((task) => task.cropId == cropId)
        .toList(growable: false);
    for (final task in related) {
      await _cancelReminder(task);
    }
    _tasks.removeWhere((task) => task.cropId == cropId);
    await repository?.deleteTasksForCrop(cropId);
    if (_syncing) _syncAgain = true;
    notifyListeners();
  }

  Future<void> _waitForSynchronization() async {
    if (!_syncing) return;
    final deadline = DateTime.now().add(operationTimeout);
    while (_syncing) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Crop task synchronization timed out');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> reschedulePendingNotifications() async {
    for (var index = 0; index < _tasks.length; index++) {
      var task = _tasks[index];
      task = await _ensureNotificationId(task);
      _tasks[index] = task;
      await _scheduleReminder(task);
    }
  }

  void _onCropsChanged() {
    if (repository == null) {
      _generateInMemory();
    } else {
      unawaited(_synchronizeAfterCropChange());
    }
  }

  Future<void> _synchronizeAfterCropChange() async {
    try {
      await _synchronizeGeneratedTasks();
      _error = null;
    } catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  void _generateInMemory() {
    final validIds = cropController.crops.map((crop) => crop.id).toSet();
    _tasks.removeWhere((task) => !validIds.contains(task.cropId));
    for (final crop in cropController.crops) {
      for (final generated in _ruleService.generate(crop)) {
        final index = _tasks.indexWhere((task) => task.id == generated.id);
        if (index == -1) {
          _tasks.add(generated);
        } else if (!_tasks[index].isCustomized && !_tasks[index].isDeleted) {
          _tasks[index] = generated.copyWith(
            isCompleted: _tasks[index].isCompleted,
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> _synchronizeGeneratedTasks() async {
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        final validIds = cropController.crops.map((crop) => crop.id).toSet();
        final orphanCropIds = _tasks
            .where((task) => !validIds.contains(task.cropId))
            .map((task) => task.cropId)
            .toSet();
        for (final cropId in orphanCropIds) {
          final related = _tasks
              .where((task) => task.cropId == cropId)
              .toList(growable: false);
          for (final task in related) {
            await _cancelReminder(task);
          }
          _tasks.removeWhere((task) => task.cropId == cropId);
          await repository!.deleteTasksForCrop(cropId);
        }
        for (final crop in cropController.crops) {
          for (final generated in _ruleService.generate(crop)) {
            final index = _tasks.indexWhere((task) => task.id == generated.id);
            if (index == -1) {
              var saved = await repository!.addTask(generated);
              saved = await _ensureNotificationId(saved);
              _tasks.add(saved);
              await _scheduleReminder(saved);
            } else if (!_tasks[index].isCustomized &&
                !_tasks[index].isDeleted &&
                (_tasks[index].dueDate != generated.dueDate ||
                    _tasks[index].type != generated.type)) {
              final updated = generated.copyWith(
                isCompleted: _tasks[index].isCompleted,
                updatedAt: DateTime.now(),
              );
              await _cancelReminder(_tasks[index]);
              var saved = await repository!.updateTask(updated);
              saved = await _ensureNotificationId(saved);
              _tasks[index] = saved;
              await _scheduleReminder(saved);
            }
          }
        }
      } while (_syncAgain);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Future<CropTask> _ensureNotificationId(CropTask task) async {
    if (task.reminderTime == TaskReminderTime.none ||
        task.notificationId != null) {
      return task;
    }
    final updated = task.copyWith(notificationId: _notificationIdFor(task.id));
    return await repository?.updateTask(updated) ?? updated;
  }

  Future<void> _scheduleReminder(CropTask task) async {
    final notificationId = task.notificationId;
    if (notificationId == null ||
        task.reminderTime == TaskReminderTime.none ||
        task.isCompleted ||
        task.isDeleted) {
      return;
    }
    final scheduledAt = task.dueDate.subtract(
      _reminderOffset(task.reminderTime),
    );
    if (!scheduledAt.isAfter(DateTime.now())) return;
    final crop = cropController.cropById(task.cropId);
    if (crop == null || !await notificationService.requestPermission()) return;
    final content = buildCropTaskNotificationContent(
      crop: crop,
      task: task,
      languageCode: languageCodeProvider(),
    );
    await notificationService.schedule(
      id: notificationId,
      title: content.title,
      body: content.body,
      scheduledAt: scheduledAt,
      payload: 'crop-task:${task.id}',
    );
  }

  Future<void> _cancelReminder(CropTask task) async {
    final id = task.notificationId;
    if (id != null) await notificationService.cancel(id);
  }

  static Duration _reminderOffset(TaskReminderTime reminder) =>
      switch (reminder) {
        TaskReminderTime.atDueTime || TaskReminderTime.none => Duration.zero,
        TaskReminderTime.thirtyMinutesBefore => const Duration(minutes: 30),
        TaskReminderTime.oneHourBefore => const Duration(hours: 1),
        TaskReminderTime.oneDayBefore => const Duration(days: 1),
      };

  static int _notificationIdFor(String taskId) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  @override
  void dispose() {
    cropController.removeListener(_onCropsChanged);
    super.dispose();
  }
}
