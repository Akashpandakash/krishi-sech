import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_model.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_repository.dart';

class CropRepositoryImpl implements CropRepository {
  const CropRepositoryImpl(this._localDataSource);

  final LocalCropDataSource _localDataSource;

  @override
  Future<List<Crop>> getCrops() async => (await _localDataSource.getCrops())
      .map((model) => model.toEntity())
      .toList();

  @override
  Future<Crop> addCrop(Crop crop) async =>
      (await _localDataSource.addCrop(CropModel.fromEntity(crop))).toEntity();

  @override
  Future<Crop> updateCrop(Crop crop) async =>
      (await _localDataSource.updateCrop(
        CropModel.fromEntity(crop),
      )).toEntity();

  @override
  Future<void> deleteCrop(String id) => _localDataSource.deleteCrop(id);

  @override
  Future<bool> hasUserCrops() => _localDataSource.hasUserCrops();
}
