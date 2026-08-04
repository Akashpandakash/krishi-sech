import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';

abstract interface class CropHealthRecordRepository {
  Future<List<CropHealthRecord>> getRecords();
  Future<CropHealthRecord> addRecord(CropHealthRecord record);
  Future<CropHealthRecord> updateRecord(CropHealthRecord record);
  Future<void> deleteRecord(String id);
}
