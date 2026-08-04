import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/image_picker_repository.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/image_repository.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_health_photo_store.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_health_photo_store.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class DiseaseScanPage extends StatefulWidget {
  const DiseaseScanPage({
    super.key,
    required this.arguments,
    this.imageRepository,
    this.photoStore = const LocalCropHealthPhotoStore(),
  });

  final DiseaseScanImageArguments arguments;
  final ImageRepository? imageRepository;
  final CropHealthPhotoStore photoStore;

  @override
  State<DiseaseScanPage> createState() => _DiseaseScanPageState();
}

class _DiseaseScanPageState extends State<DiseaseScanPage> {
  late String _imagePath = widget.arguments.imagePath;
  bool _isPicking = false;

  ImageRepository get _repository =>
      widget.imageRepository ?? ImagePickerRepository();

  Future<void> _replaceImage({required bool camera}) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final path = camera
          ? await _repository.takePhoto()
          : await _repository.chooseFromGallery();
      if (path != null) {
        final savedPath = widget.arguments.cropId == null
            ? path
            : await widget.photoStore.savePhoto(path);
        if (mounted) setState(() => _imagePath = savedPath);
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      final denied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            denied
                ? context.l10n.imagePermissionDenied
                : context.l10n.imageCouldNotBeOpened,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imageCouldNotBeOpened)),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _analyze() {
    Navigator.of(context).pushNamed(
      AppRoutes.diseaseProcessing,
      arguments: DiseaseScanImageArguments(
        imagePath: _imagePath,
        cropId: widget.arguments.cropId,
        cropName: widget.arguments.cropName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.imagePreview)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Image.file(
                    File(_imagePath),
                    key: ValueKey(_imagePath),
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth:
                        (MediaQuery.sizeOf(context).width *
                                MediaQuery.devicePixelRatioOf(context))
                            .ceil(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('disease_retake'),
                          onPressed: _isPicking
                              ? null
                              : () => _replaceImage(camera: true),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(context.l10n.retake),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('disease_choose_another'),
                          onPressed: _isPicking
                              ? null
                              : () => _replaceImage(camera: false),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(context.l10n.chooseAnother),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppPressable(
                    enabled: !_isPicking,
                    haptic: AppPressableHaptic.medium,
                    child: FilledButton.icon(
                      key: const Key('analyze_crop_image'),
                      onPressed: _isPicking ? null : _analyze,
                      icon: _isPicking
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(context.l10n.analyze),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiseaseScanImageArguments {
  const DiseaseScanImageArguments({
    required this.imagePath,
    this.cropId,
    this.cropName,
  });

  final String imagePath;
  final String? cropId;
  final String? cropName;
}
