import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';

abstract interface class CropRepository {
  Future<List<Crop>> getCrops();
  Future<Crop> addCrop(Crop crop);
  Future<Crop> updateCrop(Crop crop);
  Future<void> deleteCrop(String id);

  Future<bool> hasUserCrops();
}

enum CropSyncIssue { offline, unauthorized, server }

abstract interface class CropSyncAwareRepository implements CropRepository {
  CropSyncIssue? get lastSyncIssue;
  bool get hasPendingChanges;
}
