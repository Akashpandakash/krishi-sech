import 'package:image_picker/image_picker.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/support_attachment_repository.dart';

class ImagePickerSupportAttachmentRepository
    implements SupportAttachmentRepository {
  ImagePickerSupportAttachmentRepository({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> chooseScreenshot() async => (await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 75,
    maxWidth: 1600,
    maxHeight: 1600,
  ))?.path;
}
