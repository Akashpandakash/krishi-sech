import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/notifications/presentation/controllers/app_notification_controller.dart';

class AppNotificationScope
    extends InheritedNotifier<AppNotificationController> {
  const AppNotificationScope({
    super.key,
    required AppNotificationController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppNotificationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppNotificationScope>();
    assert(scope != null, 'AppNotificationScope is missing');
    return scope!.notifier!;
  }

  static AppNotificationController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppNotificationScope>()
      ?.notifier;
}
