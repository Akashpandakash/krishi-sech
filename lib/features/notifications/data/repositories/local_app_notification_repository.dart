import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';
import 'package:krishi_sech/features/notifications/domain/repositories/app_notification_repository.dart';

class LocalAppNotificationRepository implements AppNotificationRepository {
  LocalAppNotificationRepository({List<AppNotification>? notifications})
    : _notifications = List.of(notifications ?? demoNotifications());

  final List<AppNotification> _notifications;

  static List<AppNotification> demoNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'weather-rain',
        type: AppNotificationType.weather,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      AppNotification(
        id: 'crop-irrigation',
        type: AppNotificationType.cropTask,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'market-price',
        type: AppNotificationType.market,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<List<AppNotification>> getNotifications() async =>
      List.unmodifiable(_notifications);

  @override
  Future<AppNotification> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Notification not found');
    final updated = _notifications[index].copyWith(isRead: true);
    _notifications[index] = updated;
    return updated;
  }
}
