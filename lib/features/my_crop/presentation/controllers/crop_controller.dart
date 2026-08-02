import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_repository.dart';

class CropController extends ChangeNotifier {
  CropController._({required this.repository});

  final CropRepository? repository;
  List<Crop> _crops = [];
  bool _hasUserCrops = false;
  bool _isLoading = false;
  Object? _error;

  List<Crop> get crops => List.unmodifiable(_crops);
  List<Crop> get savedCrops =>
      _hasUserCrops ? List.unmodifiable(_crops) : const [];
  bool get hasUserCrops => _hasUserCrops;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  int get totalCount => _crops.length;
  int get healthyCount =>
      _crops.where((crop) => crop.health == CropHealth.healthy).length;
  int get attentionCount =>
      _crops.where((crop) => crop.health == CropHealth.needsAttention).length;
  int get upcomingTaskCount =>
      _crops.where((crop) => crop.nextTask != CropTaskType.completed).length;

  static Future<CropController> load(CropRepository repository) async {
    final controller = CropController._(repository: repository);
    controller._hasUserCrops = await repository.hasUserCrops();
    final crops = await repository.getCrops();
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
      _hasUserCrops = await repository!.hasUserCrops();
      final saved = await repository!.getCrops();
      _crops = _hasUserCrops ? saved : _samples();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCrop(Crop crop) async {
    if (!_hasUserCrops) {
      _crops = [];
      _hasUserCrops = true;
    }
    final created = await repository?.addCrop(crop) ?? crop;
    _crops.add(created);
    notifyListeners();
  }

  Future<void> updateCrop(Crop crop) async {
    final index = _crops.indexWhere((item) => item.id == crop.id);
    if (index == -1) return;
    final existing = _crops[index];
    final updated = crop.copyWith(
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    if (!_hasUserCrops) {
      _crops = [];
      _hasUserCrops = true;
      final created = await repository?.addCrop(updated) ?? updated;
      _crops.add(created);
    } else {
      _crops[index] = await repository?.updateCrop(updated) ?? updated;
    }
    notifyListeners();
  }

  Future<void> deleteCrop(String id) async {
    if (!_hasUserCrops) {
      _crops = [];
      _hasUserCrops = true;
    } else {
      _crops.removeWhere((crop) => crop.id == id);
    }
    await repository?.deleteCrop(id);
    notifyListeners();
  }

  Future<void> setHealth(String id, CropHealth health) async {
    final crop = cropById(id);
    if (crop != null) await updateCrop(crop.copyWith(health: health));
  }

  Future<void> setGrowthStage(String id, GrowthStage stage) async {
    final crop = cropById(id);
    if (crop != null) await updateCrop(crop.copyWith(growthStage: stage));
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
