enum CropHealthRecordType {
  disease,
  fertilizer,
  irrigation,
  spray,
  scan,
  note,
  photo,
}

class CropHealthRecord {
  const CropHealthRecord({
    required this.id,
    required this.cropId,
    required this.type,
    required this.title,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.details,
    this.photoPath,
  });

  final String id;
  final String cropId;
  final CropHealthRecordType type;
  final String title;
  final String? details;
  final String? photoPath;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropHealthRecord copyWith({
    CropHealthRecordType? type,
    String? title,
    String? details,
    String? photoPath,
    DateTime? occurredAt,
    DateTime? updatedAt,
  }) => CropHealthRecord(
    id: id,
    cropId: cropId,
    type: type ?? this.type,
    title: title ?? this.title,
    details: details ?? this.details,
    photoPath: photoPath ?? this.photoPath,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
