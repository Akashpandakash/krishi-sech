import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/notifications/domain/repositories/app_notification_repository.dart';
import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';
import 'package:krishi_sech/features/notifications/presentation/app_notification_scope.dart';
import 'package:krishi_sech/features/notifications/presentation/controllers/app_notification_controller.dart';
import 'package:krishi_sech/features/notifications/presentation/pages/notifications_page.dart';
import 'package:krishi_sech/features/notifications/presentation/widgets/home_notification_bell.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

AppNotification _notification({bool isRead = false}) => AppNotification(
  id: 'test-weather',
  type: AppNotificationType.weather,
  // Title and body are operator-authored and delivered by the backend, so the
  // test supplies them the same way a real broadcast would.
  title: 'Rain expected today',
  message: 'Heavy rain is likely in your district this afternoon.',
  createdAt: DateTime(2026, 8, 6, 9, 30),
  isRead: isRead,
);

/// Stands in for the backend inbox so the widget tests stay offline.
class _FakeNotificationRepository implements AppNotificationRepository {
  _FakeNotificationRepository(List<AppNotification> notifications)
    : _notifications = List.of(notifications);

  final List<AppNotification> _notifications;

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

Future<AppNotificationController> _pumpNotifications(
  WidgetTester tester, {
  required List<AppNotification> notifications,
}) async {
  final controller = AppNotificationController(
    _FakeNotificationRepository(notifications),
  );
  await controller.load();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    AppNotificationScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: Center(child: HomeNotificationBell())),
        routes: {AppRoutes.notifications: (_) => const NotificationsPage()},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('bell tap opens Notifications page', (tester) async {
    await _pumpNotifications(tester, notifications: [_notification()]);

    await tester.tap(find.byKey(const Key('home_notification_bell')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Rain expected today'), findsOneWidget);
  });

  testWidgets('badge is visible only while unread notifications exist', (
    tester,
  ) async {
    await _pumpNotifications(tester, notifications: [_notification()]);
    expect(
      tester
          .widget<Badge>(find.byKey(const Key('home_notification_badge')))
          .isLabelVisible,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpNotifications(
      tester,
      notifications: [_notification(isRead: true)],
    );
    expect(
      tester
          .widget<Badge>(find.byKey(const Key('home_notification_badge')))
          .isLabelVisible,
      isFalse,
    );
  });

  testWidgets('tapping a notification marks it as read', (tester) async {
    final controller = await _pumpNotifications(
      tester,
      notifications: [_notification()],
    );
    await tester.tap(find.byKey(const Key('home_notification_bell')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notification_test-weather')));
    await tester.pumpAndSettle();

    expect(controller.notifications.single.isRead, isTrue);
    expect(
      find.byKey(const ValueKey('notification_unread_test-weather')),
      findsNothing,
    );
  });

  testWidgets('empty repository shows the notification empty state', (
    tester,
  ) async {
    await _pumpNotifications(tester, notifications: const []);
    await tester.tap(find.byKey(const Key('home_notification_bell')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_empty_state')), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('back navigation returns from Notifications to Home', (
    tester,
  ) async {
    await _pumpNotifications(tester, notifications: [_notification()]);
    await tester.tap(find.byKey(const Key('home_notification_bell')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_notification_bell')), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
  });
}
