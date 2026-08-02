typedef NotificationTapCallback = void Function(String? payload);

abstract interface class NotificationService {
  Future<void> initialize({NotificationTapCallback? onTap});

  Future<bool> requestPermission();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  });

  Future<void> cancel(int id);
}

class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize({NotificationTapCallback? onTap}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}
