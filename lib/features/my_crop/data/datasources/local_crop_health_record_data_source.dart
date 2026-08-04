import 'dart:convert';

import 'package:krishi_sech/features/my_crop/data/models/crop_health_record_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCropHealthRecordDataSource {
  const LocalCropHealthRecordDataSource(this._preferences);

  static const recordsKey = 'crop_health_records_json';
  final SharedPreferences _preferences;

  Future<List<CropHealthRecordModel>> getRecords() async {
    final raw = _preferences.getString(recordsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CropHealthRecordModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CropHealthRecordModel> addRecord(CropHealthRecordModel record) async {
    final records = (await getRecords())..add(record);
    await _save(records);
    return record;
  }

  Future<CropHealthRecordModel> updateRecord(
    CropHealthRecordModel record,
  ) async {
    final records = await getRecords();
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _save(records);
    return record;
  }

  Future<void> deleteRecord(String id) async {
    final records = (await getRecords())
      ..removeWhere((record) => record.id == id);
    await _save(records);
  }

  Future<void> _save(List<CropHealthRecordModel> records) {
    return _preferences.setString(
      recordsKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }
}
