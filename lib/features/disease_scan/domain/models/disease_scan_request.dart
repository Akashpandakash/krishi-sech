class DiseaseScanRequest {
  const DiseaseScanRequest({
    required this.imagePath,
    this.cropName,
    this.cropId,
    this.growthStage,
    this.location,
    this.weatherSummary,
    this.language,
    this.notes,
    this.onUploadProgress,
  });

  final String imagePath;
  final String? cropName;
  final String? cropId;
  final String? growthStage;
  final String? location;
  final String? weatherSummary;
  final String? language;
  final String? notes;
  final void Function(double progress)? onUploadProgress;

  Map<String, String> toFields() => {
    'cropId': cropId?.trim() ?? '',
    'cropName': cropName?.trim() ?? '',
    'growthStage': growthStage?.trim() ?? '',
    'location': location?.trim() ?? '',
    'weatherSummary': weatherSummary?.trim() ?? '',
    'language': language?.trim() ?? '',
    'notes': notes?.trim() ?? '',
  };

  DiseaseScanRequest withUploadProgress(
    void Function(double progress) callback,
  ) => DiseaseScanRequest(
    imagePath: imagePath,
    cropName: cropName,
    cropId: cropId,
    growthStage: growthStage,
    location: location,
    weatherSummary: weatherSummary,
    language: language,
    notes: notes,
    onUploadProgress: callback,
  );
}
