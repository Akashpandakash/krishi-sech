import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';

abstract interface class AppNotificationRepository {
  Future<List<AppNotification>> getNotifications();

  Future<AppNotification> markAsRead(String id);
}
