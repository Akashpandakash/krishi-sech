import 'dart:convert';

import 'package:krishi_sech/features/my_crop/data/models/crop_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCropDataSource {
  const LocalCropDataSource(this._preferences);

  static const cropsKey = 'my_crops_json';
  static const userCropsKey = 'my_crops_user_started';
  static const pendingOperationsKey = 'my_crops_pending_operations';
  final SharedPreferences _preferences;

  Future<List<CropModel>> getCrops() async {
    final raw = _preferences.getString(cropsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(CropModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> hasUserCrops() async =>
      _preferences.getBool(userCropsKey) ?? false;

  Future<CropModel> addCrop(CropModel crop) async {
    final crops = (await getCrops())..add(crop);
    await _save(crops);
    return crop;
  }

  Future<CropModel> updateCrop(CropModel crop) async {
    final crops = await getCrops();
    final index = crops.indexWhere((item) => item.id == crop.id);
    if (index == -1) {
      crops.add(crop);
    } else {
      crops[index] = crop;
    }
    await _save(crops);
    return crop;
  }

  Future<void> deleteCrop(String id) async {
    final crops = (await getCrops())..removeWhere((crop) => crop.id == id);
    await _save(crops);
  }

  Future<void> replaceCrops(List<CropModel> crops) => _save(crops);

  Future<List<CropSyncOperation>> getPendingOperations() async {
    final raw = _preferences.getString(pendingOperationsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(CropSyncOperation.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> queueUpsert(String type, CropModel crop) async {
    final operations = await getPendingOperations();
    final createIndex = operations.indexWhere(
      (operation) => operation.cropId == crop.id && operation.type == 'create',
    );
    if (createIndex >= 0) {
      operations[createIndex] = CropSyncOperation('create', crop.id, crop);
    } else {
      operations.removeWhere(
        (operation) => operation.cropId == crop.id && operation.type == type,
      );
      operations.add(CropSyncOperation(type, crop.id, crop));
    }
    await _savePending(operations);
  }

  Future<bool> queueDelete(String id) async {
    final operations = await getPendingOperations();
    final pendingCreate = operations.any(
      (operation) => operation.cropId == id && operation.type == 'create',
    );
    operations.removeWhere((operation) => operation.cropId == id);
    if (!pendingCreate) operations.add(CropSyncOperation('delete', id, null));
    await _savePending(operations);
    return pendingCreate;
  }

  Future<void> removePending(CropSyncOperation operation) async {
    final operations = await getPendingOperations();
    final index = operations.indexWhere(
      (item) => item.type == operation.type && item.cropId == operation.cropId,
    );
    if (index >= 0) operations.removeAt(index);
    await _savePending(operations);
  }

  Future<void> _savePending(List<CropSyncOperation> operations) =>
      _preferences.setString(
        pendingOperationsKey,
        jsonEncode(operations.map((operation) => operation.toJson()).toList()),
      );

  Future<void> _save(List<CropModel> crops) async {
    await Future.wait([
      _preferences.setBool(userCropsKey, true),
      _preferences.setString(
        cropsKey,
        jsonEncode(crops.map((crop) => crop.toJson()).toList()),
      ),
    ]);
  }
}

class CropSyncOperation {
  const CropSyncOperation(this.type, this.cropId, this.crop);

  final String type;
  final String cropId;
  final CropModel? crop;

  factory CropSyncOperation.fromJson(Map<String, dynamic> json) =>
      CropSyncOperation(
        json['type'] as String,
        json['cropId'] as String,
        json['crop'] is Map<String, dynamic>
            ? CropModel.fromJson(json['crop'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'cropId': cropId,
    if (crop != null) 'crop': crop!.toJson(),
  };
}
