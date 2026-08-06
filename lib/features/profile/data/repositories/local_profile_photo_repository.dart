import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/profile_photo_repository.dart';

typedef ProfileDirectoryProvider = Future<Directory> Function();
typedef ProfileImagePicker = Future<XFile?> Function();

class LocalProfilePhotoRepository implements ProfilePhotoRepository {
  LocalProfilePhotoRepository({
    ImagePicker? picker,
    ProfileImagePicker? imagePicker,
    ProfileDirectoryProvider? directoryProvider,
  }) : _imagePicker =
           imagePicker ??
           (() => (picker ?? ImagePicker()).pickImage(
             source: ImageSource.gallery,
             imageQuality: 80,
             maxWidth: 1024,
           )),
       _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory;

  final ProfileImagePicker _imagePicker;
  final ProfileDirectoryProvider _directoryProvider;

  @override
  Future<String?> selectAndPersist({required String userId}) async {
    final selected = await _imagePicker();
    if (selected == null) return null;

    // Reading through XFile also supports Android picker results backed by a
    // content provider rather than relying on File(contentUri).
    final bytes = await selected.readAsBytes();
    if (bytes.isEmpty) throw const InvalidProfilePhoto();
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
    } catch (_) {
      throw const InvalidProfilePhoto();
    }

    final root = await _directoryProvider();
    final directory = Directory('${root.path}/profile_photos');
    await directory.create(recursive: true);
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destination = File(
      '${directory.path}/profile_${safeUserId}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }
}
