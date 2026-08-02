import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';

class CropTaskModel {
  const CropTaskModel({
    required this.id,
    required this.userId,
    required this.cropId,
    required this.taskType,
    required this.dueDate,
    required this.isCompleted,
    required this.isGenerated,
    required this.isCustomized,
    required this.isDeleted,
    required this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.notificationId,
  });

  final String id;
  final String userId;
  final String cropId;
  final String taskType;
  final DateTime dueDate;
  final String? notes;
  final bool isCompleted;
  final bool isGenerated;
  final bool isCustomized;
  final bool isDeleted;
  final String reminderTime;
  final int? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CropTaskModel.fromEntity(CropTask task) => CropTaskModel(
    id: task.id,
    userId: task.userId,
    cropId: task.cropId,
    taskType: task.type.name,
    dueDate: task.dueDate,
    notes: task.notes,
    isCompleted: task.isCompleted,
    isGenerated: task.isGenerated,
    isCustomized: task.isCustomized,
    isDeleted: task.isDeleted,
    reminderTime: task.reminderTime.name,
    notificationId: task.notificationId,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
  );

  factory CropTaskModel.fromJson(Map<String, dynamic> json) => CropTaskModel(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? 'local-user',
    cropId: json['cropId'] as String,
    taskType: json['taskType'] as String,
    dueDate: DateTime.parse(json['dueDate'] as String),
    notes: json['notes'] as String?,
    isCompleted: json['isCompleted'] as bool? ?? false,
    isGenerated: json['isGenerated'] as bool? ?? false,
    isCustomized: json['isCustomized'] as bool? ?? false,
    isDeleted: json['isDeleted'] as bool? ?? false,
    reminderTime:
        json['reminderTime'] as String? ?? TaskReminderTime.atDueTime.name,
    notificationId: json['notificationId'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'cropId': cropId,
    'taskType': taskType,
    'dueDate': dueDate.toIso8601String(),
    'notes': notes,
    'isCompleted': isCompleted,
    'isGenerated': isGenerated,
    'isCustomized': isCustomized,
    'isDeleted': isDeleted,
    'reminderTime': reminderTime,
    'notificationId': notificationId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  CropTask toEntity() => CropTask(
    id: id,
    userId: userId,
    cropId: cropId,
    type: CropTaskReminderType.values.byName(taskType),
    dueDate: dueDate,
    notes: notes,
    isCompleted: isCompleted,
    isGenerated: isGenerated,
    isCustomized: isCustomized,
    isDeleted: isDeleted,
    reminderTime: TaskReminderTime.values.byName(reminderTime),
    notificationId: notificationId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
