import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:krishi_sech/core/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'crop_task_reminders';
  static const _channelName = 'Crop task reminders';
  static const _channelDescription =
      'Reminders for irrigation, fertilizer, pest inspection and harvest tasks';

  final FlutterLocalNotificationsPlugin _plugin;
  bool? _permissionGranted;

  @override
  Future<void> initialize({NotificationTapCallback? onTap}) async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('ic_stat_krishi');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      onTap?.call(launchDetails?.notificationResponse?.payload);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (_permissionGranted != null) return _permissionGranted!;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidAllowed = await android?.requestNotificationsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosAllowed = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    _permissionGranted = androidAllowed ?? iosAllowed ?? true;
    return _permissionGranted!;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    final instant = tz.TZDateTime.from(scheduledAt, tz.UTC);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: instant,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
