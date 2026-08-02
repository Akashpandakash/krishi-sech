import 'dart:convert';

import 'package:krishi_sech/features/my_crop/data/models/crop_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCropDataSource {
  const LocalCropDataSource(this._preferences);

  static const cropsKey = 'my_crops_json';
  static const userCropsKey = 'my_crops_user_started';
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
