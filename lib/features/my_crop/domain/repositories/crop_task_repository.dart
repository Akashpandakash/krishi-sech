import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';

abstract interface class CropTaskRepository {
  Future<List<CropTask>> getTasks();
  Future<CropTask> addTask(CropTask task);
  Future<CropTask> updateTask(CropTask task);
  Future<void> deleteTask(String id);
  Future<void> deleteTasksForCrop(String cropId);
}
