import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_health_record_repository.dart';

class CropHealthRecordController extends ChangeNotifier {
  CropHealthRecordController._({this.repository});

  final CropHealthRecordRepository? repository;
  final List<CropHealthRecord> _records = [];

  static Future<CropHealthRecordController> load(
    CropHealthRecordRepository repository,
  ) async {
    final controller = CropHealthRecordController._(repository: repository);
    controller._records.addAll(await repository.getRecords());
    return controller;
  }

  factory CropHealthRecordController.inMemory({
    List<CropHealthRecord> records = const [],
  }) => CropHealthRecordController._().._records.addAll(records);

  List<CropHealthRecord> recordsForCrop(String cropId) {
    final records = _records.where((item) => item.cropId == cropId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(records);
  }

  CropHealthRecord? recordById(String id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<void> addRecord(CropHealthRecord record) async {
    _records.add(await repository?.addRecord(record) ?? record);
    notifyListeners();
  }

  Future<void> updateRecord(CropHealthRecord record) async {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) return;
    final updated = record.copyWith(updatedAt: DateTime.now());
    _records[index] = await repository?.updateRecord(updated) ?? updated;
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((item) => item.id == id);
    await repository?.deleteRecord(id);
    notifyListeners();
  }
}
