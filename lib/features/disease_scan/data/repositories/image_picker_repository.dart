import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/image_repository.dart';

class ImagePickerRepository implements ImageRepository {
  ImagePickerRepository({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<String?> chooseFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    final started = Stopwatch()..start();
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (kDebugMode && AppEnvironment.loggingEnabled) {
      debugPrint(
        '[AI Vision] ${image == null ? '✗' : '✓'} step=1 image selected '
        'source=${source.name}',
      );
      if (image != null) {
        debugPrint(
          '[AI Vision] ✓ step=2 image compressed compressedBytes=${await File(image.path).length()} durationMs=${started.elapsedMilliseconds}',
        );
      }
    }
    return image?.path;
  }
}
