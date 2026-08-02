enum CropTaskReminderType { irrigation, fertilizer, pestInspection, harvest }

enum TaskReminderTime {
  atDueTime,
  thirtyMinutesBefore,
  oneHourBefore,
  oneDayBefore,
  none,
}

class CropTask {
  const CropTask({
    required this.id,
    required this.cropId,
    required this.type,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.userId = 'local-user',
    this.notes,
    this.isCompleted = false,
    this.isGenerated = false,
    this.isCustomized = false,
    this.isDeleted = false,
    this.reminderTime = TaskReminderTime.atDueTime,
    this.notificationId,
  });

  final String id;
  final String userId;
  final String cropId;
  final CropTaskReminderType type;
  final DateTime dueDate;
  final String? notes;
  final bool isCompleted;
  final bool isGenerated;
  final bool isCustomized;
  final bool isDeleted;
  final TaskReminderTime reminderTime;
  final int? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropTask copyWith({
    String? cropId,
    CropTaskReminderType? type,
    DateTime? dueDate,
    String? notes,
    bool? isCompleted,
    bool? isGenerated,
    bool? isCustomized,
    bool? isDeleted,
    TaskReminderTime? reminderTime,
    int? notificationId,
    DateTime? updatedAt,
  }) => CropTask(
    id: id,
    userId: userId,
    cropId: cropId ?? this.cropId,
    type: type ?? this.type,
    dueDate: dueDate ?? this.dueDate,
    notes: notes ?? this.notes,
    isCompleted: isCompleted ?? this.isCompleted,
    isGenerated: isGenerated ?? this.isGenerated,
    isCustomized: isCustomized ?? this.isCustomized,
    isDeleted: isDeleted ?? this.isDeleted,
    reminderTime: reminderTime ?? this.reminderTime,
    notificationId: notificationId ?? this.notificationId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
