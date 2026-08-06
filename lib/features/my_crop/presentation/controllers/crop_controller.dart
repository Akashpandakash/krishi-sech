import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_repository.dart';

class CropController extends ChangeNotifier {
  CropController._({required this.repository});

  final CropRepository? repository;
  List<Crop> _crops = [];
  bool _hasUserCrops = false;
  bool _isLoading = false;
  bool _isMutationInProgress = false;
  Object? _error;

  List<Crop> get crops => List.unmodifiable(_crops);
  List<Crop> get savedCrops =>
      _hasUserCrops ? List.unmodifiable(_crops) : const [];
  bool get hasUserCrops => _hasUserCrops;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  CropSyncIssue? get syncIssue => repository is CropSyncAwareRepository
      ? (repository! as CropSyncAwareRepository).lastSyncIssue
      : null;
  bool get hasPendingChanges =>
      repository is CropSyncAwareRepository &&
      (repository! as CropSyncAwareRepository).hasPendingChanges;
  int get totalCount => _crops.length;
  int get healthyCount =>
      _crops.where((crop) => crop.health == CropHealth.healthy).length;
  int get attentionCount =>
      _crops.where((crop) => crop.health == CropHealth.needsAttention).length;
  int get upcomingTaskCount =>
      _crops.where((crop) => crop.nextTask != CropTaskType.completed).length;

  static Future<CropController> load(CropRepository repository) async {
    final controller = CropController._(repository: repository);
    final crops = await repository.getCrops();
    controller._hasUserCrops = await repository.hasUserCrops();
    controller._crops = controller._hasUserCrops ? crops : _samples();
    return controller;
  }

  factory CropController.inMemory({List<Crop>? crops, bool samples = true}) {
    final controller = CropController._(repository: null);
    controller._hasUserCrops = crops != null || !samples;
    controller._crops = crops ?? (samples ? _samples() : []);
    return controller;
  }

  Crop? cropById(String id) {
    for (final crop in _crops) {
      if (crop.id == id) return crop;
    }
    return null;
  }

  Future<void> refresh() async {
    if (repository == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await repository!.getCrops();
      _hasUserCrops = await repository!.hasUserCrops();
      _crops = _hasUserCrops ? saved : _samples();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCrop(Crop crop) async {
    _startMutation();
    try {
      final created = await repository?.addCrop(crop) ?? crop;
      if (!_hasUserCrops) _crops = [];
      _hasUserCrops = true;
      _crops.add(created);
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _finishMutation();
    }
  }

  Future<bool> updateCrop(Crop crop) async {
    if (_isMutationInProgress) return false;
    final index = _crops.indexWhere((item) => item.id == crop.id);
    if (index == -1) return false;
    final existing = _crops[index];
    final updated = crop.copyWith(
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _isMutationInProgress = true;
    _startMutation();
    try {
      final result = await repository?.updateCrop(updated) ?? updated;
      final currentIndex = _crops.indexWhere((item) => item.id == crop.id);
      if (currentIndex == -1) return false;
      _crops[currentIndex] = result;
      _hasUserCrops = true;
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _isMutationInProgress = false;
      _finishMutation();
    }
  }

  Future<bool> deleteCrop(String id) async {
    _startMutation();
    try {
      await repository?.deleteCrop(id);
      _crops.removeWhere((crop) => crop.id == id);
      _hasUserCrops = true;
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _finishMutation();
    }
  }

  Future<void> setHealth(String id, CropHealth health) async {
    final crop = cropById(id);
    if (crop != null) await updateCrop(crop.copyWith(health: health));
  }

  Future<void> setGrowthStage(String id, GrowthStage stage) async {
    final crop = cropById(id);
    if (crop != null) await updateCrop(crop.copyWith(growthStage: stage));
  }

  void _startMutation() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _finishMutation() {
    _isLoading = false;
    notifyListeners();
  }

  static List<Crop> _samples() {
    final now = DateTime.now();
    return [
      Crop(
        id: 'sample-wheat',
        kind: CropKind.wheat,
        variety: 'HD 2967',
        sowingDate: now.subtract(const Duration(days: 45)),
        landArea: 2,
        landAreaUnit: LandAreaUnit.acre,
        growthStage: GrowthStage.vegetative,
        irrigationType: IrrigationType.flood,
      ),
      Crop(
        id: 'sample-mustard',
        kind: CropKind.mustard,
        variety: 'Pusa Bold',
        sowingDate: now.subtract(const Duration(days: 28)),
        landArea: 1.5,
        landAreaUnit: LandAreaUnit.acre,
        growthStage: GrowthStage.flowering,
        irrigationType: IrrigationType.rainFed,
        health: CropHealth.needsAttention,
      ),
      Crop(
        id: 'sample-tomato',
        kind: CropKind.tomato,
        variety: 'Pusa Ruby',
        sowingDate: now.subtract(const Duration(days: 62)),
        landArea: 0.75,
        landAreaUnit: LandAreaUnit.acre,
        growthStage: GrowthStage.fruiting,
        irrigationType: IrrigationType.drip,
      ),
    ];
  }
}
