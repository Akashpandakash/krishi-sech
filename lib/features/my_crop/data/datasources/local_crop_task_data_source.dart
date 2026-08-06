import 'dart:convert';

import 'package:krishi_sech/features/my_crop/data/models/crop_task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCropTaskDataSource {
  const LocalCropTaskDataSource(this._preferences);

  static const tasksKey = 'crop_tasks_json';
  static const pendingOperationsKey = 'crop_tasks_pending_operations';
  final SharedPreferences _preferences;

  Future<List<CropTaskModel>> getTasks() async {
    final raw = _preferences.getString(tasksKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CropTaskModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CropTaskModel> addTask(CropTaskModel task) async {
    final tasks = (await getTasks())..add(task);
    await _save(tasks);
    return task;
  }

  Future<CropTaskModel> updateTask(CropTaskModel task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
    await _save(tasks);
    return task;
  }

  Future<void> deleteTask(String id) async {
    final tasks = (await getTasks())..removeWhere((task) => task.id == id);
    await _save(tasks);
  }

  Future<void> deleteTasksForCrop(String cropId) async {
    final tasks = await getTasks();
    final taskIds = tasks
        .where((task) => task.cropId == cropId)
        .map((task) => task.id)
        .toSet();
    tasks.removeWhere((task) => task.cropId == cropId);
    final operations = await getPendingOperations()
      ..removeWhere((operation) => taskIds.contains(operation.taskId));
    await Future.wait([_save(tasks), _savePending(operations)]);
  }

  Future<void> replaceTasks(List<CropTaskModel> tasks) => _save(tasks);

  Future<List<CropTaskSyncOperation>> getPendingOperations() async {
    final raw = _preferences.getString(pendingOperationsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(CropTaskSyncOperation.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> queueUpsert(String type, CropTaskModel task) async {
    final operations = await getPendingOperations();
    final createIndex = operations.indexWhere(
      (operation) => operation.taskId == task.id && operation.type == 'create',
    );
    if (createIndex >= 0) {
      operations[createIndex] = CropTaskSyncOperation('create', task.id, task);
    } else {
      operations.removeWhere((operation) => operation.taskId == task.id);
      operations.add(CropTaskSyncOperation(type, task.id, task));
    }
    await _savePending(operations);
  }

  Future<void> queueDelete(String id) async {
    final operations = await getPendingOperations();
    final pendingCreate = operations.any(
      (operation) => operation.taskId == id && operation.type == 'create',
    );
    operations.removeWhere((operation) => operation.taskId == id);
    if (!pendingCreate) {
      operations.add(CropTaskSyncOperation('delete', id, null));
    }
    await _savePending(operations);
  }

  Future<void> removePending(CropTaskSyncOperation operation) async {
    final operations = await getPendingOperations();
    operations.removeWhere(
      (item) => item.type == operation.type && item.taskId == operation.taskId,
    );
    await _savePending(operations);
  }

  Future<void> _savePending(List<CropTaskSyncOperation> operations) =>
      _preferences.setString(
        pendingOperationsKey,
        jsonEncode(operations.map((operation) => operation.toJson()).toList()),
      );

  Future<void> _save(List<CropTaskModel> tasks) => _preferences.setString(
    tasksKey,
    jsonEncode(tasks.map((task) => task.toJson()).toList()),
  );
}

class CropTaskSyncOperation {
  const CropTaskSyncOperation(this.type, this.taskId, this.task);

  final String type;
  final String taskId;
  final CropTaskModel? task;

  factory CropTaskSyncOperation.fromJson(Map<String, dynamic> json) =>
      CropTaskSyncOperation(
        json['type'] as String,
        json['taskId'] as String,
        json['task'] is Map<String, dynamic>
            ? CropTaskModel.fromJson(json['task'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'taskId': taskId,
    if (task != null) 'task': task!.toJson(),
  };
}
