enum AppNotificationType { weather, cropTask, market }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}
