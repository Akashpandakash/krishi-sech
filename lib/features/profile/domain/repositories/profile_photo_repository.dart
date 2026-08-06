abstract interface class ProfilePhotoRepository {
  /// Returns the app-owned file path, or null when selection was cancelled.
  Future<String?> selectAndPersist({required String userId});
}

class InvalidProfilePhoto implements Exception {
  const InvalidProfilePhoto();
}
