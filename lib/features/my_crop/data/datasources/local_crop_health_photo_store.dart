import 'dart:io';

import 'package:krishi_sech/features/my_crop/domain/repositories/crop_health_photo_store.dart';
import 'package:path_provider/path_provider.dart';

class LocalCropHealthPhotoStore implements CropHealthPhotoStore {
  const LocalCropHealthPhotoStore();

  @override
  Future<String> savePhoto(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory('${directory.path}/crop_health_photos');
    await photoDirectory.create(recursive: true);
    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final target = File(
      '${photoDirectory.path}/${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return (await File(sourcePath).copy(target.path)).path;
  }
}
