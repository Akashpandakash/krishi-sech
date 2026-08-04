abstract interface class ImageRepository {
  Future<String?> takePhoto();

  Future<String?> chooseFromGallery();
}
