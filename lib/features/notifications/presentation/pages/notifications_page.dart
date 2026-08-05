import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';
import 'package:krishi_sech/features/notifications/presentation/app_notification_scope.dart';
import 'package:krishi_sech/features/notifications/presentation/app_notification_text.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppNotificationScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notifications)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.isLoading && controller.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null && controller.notifications.isEmpty) {
              return _NotificationError(onRetry: controller.load);
            }
            if (controller.notifications.isEmpty) {
              return const _NotificationEmptyState();
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: controller.notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: _NotificationCard(
                    notification: controller.notifications[index],
                    onTap: () => controller.markAsRead(
                      controller.notifications[index].id,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppPressable(
      key: ValueKey('notification_${notification.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? colorScheme.surface
              : AppColors.lightGreen.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? colorScheme.outlineVariant
                : AppColors.primary.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconFor(notification.type), color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title(context),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          key: ValueKey(
                            'notification_unread_${notification.id}',
                          ),
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(notification.message(context)),
                  const SizedBox(height: 8),
                  Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(notification.createdAt)} • '
                    '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(notification.createdAt))}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.weather => Icons.cloud_outlined,
    AppNotificationType.cropTask => Icons.event_note_outlined,
    AppNotificationType.market => Icons.trending_up,
  };
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('notifications_empty_state'),
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 58,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noNotifications,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.noNotificationsDescription,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.notificationsLoadError),
        const SizedBox(height: 10),
        FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}
