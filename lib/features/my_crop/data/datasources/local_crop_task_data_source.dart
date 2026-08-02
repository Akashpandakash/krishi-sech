import 'dart:convert';

import 'package:krishi_sech/features/my_crop/data/models/crop_task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCropTaskDataSource {
  const LocalCropTaskDataSource(this._preferences);

  static const tasksKey = 'crop_tasks_json';
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

  Future<void> _save(List<CropTaskModel> tasks) => _preferences.setString(
    tasksKey,
    jsonEncode(tasks.map((task) => task.toJson()).toList()),
  );
}
