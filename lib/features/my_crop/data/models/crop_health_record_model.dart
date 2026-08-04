import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';

class CropHealthRecordModel {
  const CropHealthRecordModel({
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
  final String type;
  final String title;
  final String? details;
  final String? photoPath;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CropHealthRecordModel.fromEntity(CropHealthRecord record) =>
      CropHealthRecordModel(
        id: record.id,
        cropId: record.cropId,
        type: record.type.name,
        title: record.title,
        details: record.details,
        photoPath: record.photoPath,
        occurredAt: record.occurredAt,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      );

  factory CropHealthRecordModel.fromJson(Map<String, dynamic> json) =>
      CropHealthRecordModel(
        id: json['id'] as String,
        cropId: json['cropId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        details: json['details'] as String?,
        photoPath: json['photoPath'] as String?,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropId': cropId,
    'type': type,
    'title': title,
    'details': details,
    'photoPath': photoPath,
    'occurredAt': occurredAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  CropHealthRecord toEntity() => CropHealthRecord(
    id: id,
    cropId: cropId,
    type: CropHealthRecordType.values.byName(type),
    title: title,
    details: details,
    photoPath: photoPath,
    occurredAt: occurredAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
