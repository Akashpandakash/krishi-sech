import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_health_record_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_health_record_model.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_health_record_repository.dart';

class CropHealthRecordRepositoryImpl implements CropHealthRecordRepository {
  const CropHealthRecordRepositoryImpl(this._dataSource);

  final LocalCropHealthRecordDataSource _dataSource;

  @override
  Future<List<CropHealthRecord>> getRecords() async =>
      (await _dataSource.getRecords()).map((item) => item.toEntity()).toList();

  @override
  Future<CropHealthRecord> addRecord(CropHealthRecord record) async =>
      (await _dataSource.addRecord(
        CropHealthRecordModel.fromEntity(record),
      )).toEntity();

  @override
  Future<CropHealthRecord> updateRecord(CropHealthRecord record) async =>
      (await _dataSource.updateRecord(
        CropHealthRecordModel.fromEntity(record),
      )).toEntity();

  @override
  Future<void> deleteRecord(String id) => _dataSource.deleteRecord(id);
}
