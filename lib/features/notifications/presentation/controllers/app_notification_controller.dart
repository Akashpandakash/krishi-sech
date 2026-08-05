import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';
import 'package:krishi_sech/features/notifications/domain/repositories/app_notification_repository.dart';

class AppNotificationController extends ChangeNotifier {
  AppNotificationController(this._repository);

  final AppNotificationRepository _repository;
  List<AppNotification> _notifications = const [];
  bool _isLoading = false;
  Object? _error;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  Object? get error => _error;
  bool get hasUnread => _notifications.any((item) => !item.isRead);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _repository.getNotifications();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    try {
      final updated = await _repository.markAsRead(id);
      _notifications = [..._notifications]..[index] = updated;
      notifyListeners();
    } catch (error) {
      _error = error;
      notifyListeners();
    }
  }
}
