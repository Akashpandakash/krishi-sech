import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_task_model.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_task_repository.dart';

class CropTaskRepositoryImpl implements CropTaskRepository {
  const CropTaskRepositoryImpl(this._dataSource);

  final LocalCropTaskDataSource _dataSource;

  @override
  Future<List<CropTask>> getTasks() async =>
      (await _dataSource.getTasks()).map((model) => model.toEntity()).toList();

  @override
  Future<CropTask> addTask(CropTask task) async =>
      (await _dataSource.addTask(CropTaskModel.fromEntity(task))).toEntity();

  @override
  Future<CropTask> updateTask(CropTask task) async =>
      (await _dataSource.updateTask(CropTaskModel.fromEntity(task))).toEntity();

  @override
  Future<void> deleteTask(String id) => _dataSource.deleteTask(id);
}
