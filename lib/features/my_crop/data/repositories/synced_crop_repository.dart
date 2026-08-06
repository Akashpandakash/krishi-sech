import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_model.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_repository.dart';

class SyncedCropRepository implements CropSyncAwareRepository {
  SyncedCropRepository(this.local, this.remote);

  final LocalCropDataSource local;
  final RemoteCropDataSource remote;

  @override
  CropSyncIssue? lastSyncIssue;
  @override
  bool hasPendingChanges = false;

  @override
  Future<List<Crop>> getCrops() async {
    final cached = await local.getCrops();
    await _syncPending();
    if (hasPendingChanges && lastSyncIssue != null) {
      return (await local.getCrops()).map((crop) => crop.toEntity()).toList();
    }
    try {
      final remoteCrops = await remote.getCrops();
      final merged = remoteCrops
          .map(
            (remoteCrop) =>
                remoteCrop.mergeLocalProfile(_findCrop(cached, remoteCrop.id)),
          )
          .toList();
      await local.replaceCrops(merged);
      lastSyncIssue = null;
      return merged.map((crop) => crop.toEntity()).toList();
    } on CropRemoteFailure catch (failure) {
      lastSyncIssue = _issue(failure.type);
      return (await local.getCrops()).map((crop) => crop.toEntity()).toList();
    }
  }

  @override
  Future<Crop> addCrop(Crop crop) async {
    await _syncPending();
    final model = CropModel.fromEntity(crop);
    try {
      final created = (await remote.addCrop(model)).mergeLocalProfile(model);
      await local.addCrop(created);
      await _updatePendingState();
      lastSyncIssue = null;
      return created.toEntity();
    } on CropRemoteFailure catch (failure) {
      if (failure.type != CropRemoteFailureType.offline) rethrow;
      await local.addCrop(model);
      await local.queueUpsert('create', model);
      await _updatePendingState();
      lastSyncIssue = CropSyncIssue.offline;
      return crop;
    }
  }

  @override
  Future<Crop> updateCrop(Crop crop) async {
    await _syncPending();
    final model = CropModel.fromEntity(crop);
    try {
      final response = await remote.updateCrop(model);
      final updated = response.acceptSuccessfulUpdate(model);
      await local.updateCrop(updated);
      await _updatePendingState();
      lastSyncIssue = null;
      return updated.toEntity();
    } on CropRemoteFailure catch (failure) {
      if (failure.type != CropRemoteFailureType.offline) rethrow;
      await local.updateCrop(model);
      await local.queueUpsert('update', model);
      await _updatePendingState();
      lastSyncIssue = CropSyncIssue.offline;
      return crop;
    }
  }

  @override
  Future<void> deleteCrop(String id) async {
    await _syncPending();
    try {
      await remote.deleteCrop(id);
      await local.deleteCrop(id);
      await _updatePendingState();
      lastSyncIssue = null;
    } on CropRemoteFailure catch (failure) {
      if (failure.type == CropRemoteFailureType.notFound) {
        await local.deleteCrop(id);
        await _updatePendingState();
        lastSyncIssue = null;
        return;
      }
      if (failure.type != CropRemoteFailureType.offline) rethrow;
      await local.deleteCrop(id);
      await local.queueDelete(id);
      await _updatePendingState();
      lastSyncIssue = CropSyncIssue.offline;
    }
  }

  @override
  Future<bool> hasUserCrops() async => true;

  Future<void> _syncPending() async {
    final operations = await local.getPendingOperations();
    hasPendingChanges = operations.isNotEmpty;
    for (final operation in operations) {
      try {
        switch (operation.type) {
          case 'create':
            final localCrop = operation.crop!;
            final created = (await remote.addCrop(
              localCrop,
            )).mergeLocalProfile(localCrop);
            await local.deleteCrop(localCrop.id);
            await local.addCrop(created);
            break;
          case 'update':
            final localCrop = operation.crop!;
            final response = await remote.updateCrop(localCrop);
            final updated = response.acceptSuccessfulUpdate(localCrop);
            await local.updateCrop(updated);
            break;
          case 'delete':
            try {
              await remote.deleteCrop(operation.cropId);
            } on CropRemoteFailure catch (failure) {
              if (failure.type != CropRemoteFailureType.notFound) rethrow;
            }
            break;
        }
        await local.removePending(operation);
      } on CropRemoteFailure catch (failure) {
        lastSyncIssue = _issue(failure.type);
        break;
      }
    }
    await _updatePendingState();
  }

  Future<void> _updatePendingState() async {
    hasPendingChanges = (await local.getPendingOperations()).isNotEmpty;
  }

  CropSyncIssue _issue(CropRemoteFailureType type) => switch (type) {
    CropRemoteFailureType.offline => CropSyncIssue.offline,
    CropRemoteFailureType.unauthorized => CropSyncIssue.unauthorized,
    CropRemoteFailureType.notFound => CropSyncIssue.server,
    CropRemoteFailureType.server => CropSyncIssue.server,
  };

  CropModel? _findCrop(List<CropModel> crops, String id) {
    for (final crop in crops) {
      if (crop.id == id) return crop;
    }
    return null;
  }
}
