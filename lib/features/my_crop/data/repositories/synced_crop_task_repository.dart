import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_task_model.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_task_repository.dart';

class SyncedCropTaskRepository implements CropTaskRepository {
  SyncedCropTaskRepository(this.local, this.remote);

  final LocalCropTaskDataSource local;
  final RemoteCropTaskDataSource remote;

  @override
  Future<List<CropTask>> getTasks() async {
    await _syncPending();
    final cached = await local.getTasks();
    try {
      final remoteTasks = await remote.getTasks();
      final merged = remoteTasks
          .map((task) => task.mergeLocalMetadata(_find(cached, task.id)))
          .toList();
      await local.replaceTasks(merged);
      return merged.map((task) => task.toEntity()).toList();
    } on CropTaskRemoteFailure {
      return cached.map((task) => task.toEntity()).toList();
    }
  }

  @override
  Future<CropTask> addTask(CropTask task) async {
    await _syncPending();
    final model = CropTaskModel.fromEntity(task);
    try {
      final saved = (await remote.addTask(model)).mergeLocalMetadata(model);
      await local.addTask(saved);
      return saved.toEntity();
    } on CropTaskRemoteFailure catch (failure) {
      if (failure.type != CropTaskRemoteFailureType.offline) rethrow;
      await local.addTask(model);
      await local.queueUpsert('create', model);
      return task;
    }
  }

  @override
  Future<CropTask> updateTask(CropTask task) async {
    await _syncPending();
    final model = CropTaskModel.fromEntity(task);
    try {
      final saved = (await remote.updateTask(model)).mergeLocalMetadata(model);
      await local.updateTask(saved);
      return saved.toEntity();
    } on CropTaskRemoteFailure catch (failure) {
      if (failure.type != CropTaskRemoteFailureType.offline) rethrow;
      await local.updateTask(model);
      await local.queueUpsert('update', model);
      return task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await _syncPending();
    try {
      await remote.deleteTask(id);
      await local.deleteTask(id);
    } on CropTaskRemoteFailure catch (failure) {
      if (failure.type != CropTaskRemoteFailureType.offline) rethrow;
      await local.deleteTask(id);
      await local.queueDelete(id);
    }
  }

  @override
  Future<void> deleteTasksForCrop(String cropId) =>
      local.deleteTasksForCrop(cropId);

  Future<void> _syncPending() async {
    for (final operation in await local.getPendingOperations()) {
      try {
        switch (operation.type) {
          case 'create':
            final localTask = operation.task!;
            final created = (await remote.addTask(
              localTask,
            )).mergeLocalMetadata(localTask);
            await local.updateTask(created);
            break;
          case 'update':
            final localTask = operation.task!;
            final updated = (await remote.updateTask(
              localTask,
            )).mergeLocalMetadata(localTask);
            await local.updateTask(updated);
            break;
          case 'delete':
            await remote.deleteTask(operation.taskId);
            break;
        }
        await local.removePending(operation);
      } on CropTaskRemoteFailure {
        break;
      }
    }
  }

  CropTaskModel? _find(List<CropTaskModel> tasks, String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}
