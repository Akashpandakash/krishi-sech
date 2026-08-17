import 'package:krishi_sech/features/notifications/data/datasources/remote_app_notification_data_source.dart';
import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';
import 'package:krishi_sech/features/notifications/domain/repositories/app_notification_repository.dart';

class AppNotificationRepositoryImpl implements AppNotificationRepository {
  AppNotificationRepositoryImpl(this._dataSource);

  final RemoteAppNotificationDataSource _dataSource;
  List<AppNotification> _cached = const [];

  @override
  Future<List<AppNotification>> getNotifications() async {
    _cached = await _dataSource.getNotifications();
    return _cached;
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    await _dataSource.markAsRead(id);
    final index = _cached.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Notification not found');
    // The read receipt is stored server-side; the local copy is updated so the
    // list does not need a full refetch to drop its unread badge.
    final updated = _cached[index].copyWith(isRead: true);
    _cached = [..._cached]..[index] = updated;
    return updated;
  }
}
