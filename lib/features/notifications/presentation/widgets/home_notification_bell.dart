import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/notifications/presentation/app_notification_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class HomeNotificationBell extends StatelessWidget {
  const HomeNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppNotificationScope.maybeOf(context);
    final icon = IconButton.filledTonal(
      key: const Key('home_notification_bell'),
      tooltip: context.l10n.notifications,
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
      icon: Badge(
        key: const Key('home_notification_badge'),
        isLabelVisible: controller?.hasUnread ?? false,
        child: const Icon(Icons.notifications_none),
      ),
    );
    return AppPressable(child: icon);
  }
}
