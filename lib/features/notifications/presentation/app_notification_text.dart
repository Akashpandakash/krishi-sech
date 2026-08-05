import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';
import 'package:krishi_sech/l10n/l10n.dart';

extension AppNotificationText on AppNotification {
  String title(BuildContext context) => switch (type) {
    AppNotificationType.weather => context.l10n.notificationWeatherTitle,
    AppNotificationType.cropTask => context.l10n.notificationCropTaskTitle,
    AppNotificationType.market => context.l10n.notificationMarketTitle,
  };

  String message(BuildContext context) => switch (type) {
    AppNotificationType.weather => context.l10n.notificationWeatherMessage,
    AppNotificationType.cropTask => context.l10n.notificationCropTaskMessage,
    AppNotificationType.market => context.l10n.notificationMarketMessage,
  };
}
