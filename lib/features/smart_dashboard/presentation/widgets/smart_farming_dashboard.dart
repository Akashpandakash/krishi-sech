import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/smart_dashboard/presentation/controllers/smart_recommendation_controller.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';
import 'package:krishi_sech/shared/presentation/widgets/section_header.dart';

class SmartFarmingDashboard extends StatelessWidget {
  const SmartFarmingDashboard({
    required this.controller,
    required this.weather,
    required this.tasks,
    required this.currentCrop,
    super.key,
  });
  final SmartRecommendationController controller;
  final CurrentWeather? weather;
  final List<CropTask> tasks;
  final Crop? currentCrop;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final snapshot = controller.snapshot;
      final showSkeleton = controller.isLoading && snapshot == null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: context.l10n.todaysSmartFarming),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: showSkeleton
                ? const _DashboardSkeleton(key: ValueKey('smart_skeleton'))
                : _DashboardGrid(
                    key: const ValueKey('smart_content'),
                    items: _items(context),
                  ),
          ),
        ],
      );
    },
  );

  List<_DashboardItem> _items(BuildContext context) {
    final snapshot = controller.snapshot;
    final irrigation = snapshot?.irrigation;
    final fertilizer = snapshot?.fertilizer;
    final risk = _risk(context, snapshot?.diseaseSeverity);
    final pendingTasks = tasks.where((task) => !task.isCompleted).length;
    final cached = snapshot?.fromCache == true;
    return [
      _DashboardItem(
        key: 'smart_irrigation_card',
        icon: Icons.water_drop_outlined,
        title: context.l10n.smartIrrigationRecommendation,
        primary: irrigation == null
            ? context.l10n.smartDataUnavailable
            : irrigation.required
            ? context.l10n.smartIrrigationRequired(irrigation.quantityLiters)
            : context.l10n.smartNoIrrigation,
        important: irrigation == null
            ? context.l10n.retry
            : '${irrigation.method} • ${_date(irrigation.nextDate)}',
        badge: irrigation == null
            ? context.l10n.retry
            : cached
            ? context.l10n.smartCached
            : context.l10n.smartReady,
        badgeWarning: irrigation == null || snapshot?.irrigationFailed == true,
        onTap: irrigation == null
            ? () => controller.refresh(
                Localizations.localeOf(context).languageCode,
              )
            : () => Navigator.of(context).pushNamed(AppRoutes.cropCalendar),
      ),
      _DashboardItem(
        key: 'smart_fertilizer_card',
        icon: Icons.compost_outlined,
        title: context.l10n.smartFertilizerRecommendation,
        primary: fertilizer?.name ?? context.l10n.smartDataUnavailable,
        important: fertilizer == null
            ? context.l10n.retry
            : '${fertilizer.quantity} • ${_date(fertilizer.nextDate)}',
        badge: fertilizer == null
            ? context.l10n.retry
            : cached
            ? context.l10n.smartCached
            : context.l10n.smartReady,
        badgeWarning: fertilizer == null || snapshot?.fertilizerFailed == true,
        onTap: fertilizer == null
            ? () => controller.refresh(
                Localizations.localeOf(context).languageCode,
              )
            : () => Navigator.of(context).pushNamed(AppRoutes.cropCalendar),
      ),
      _DashboardItem(
        key: 'smart_tasks_card',
        icon: Icons.event_available_outlined,
        title: context.l10n.smartTodaysCropTasks,
        primary: pendingTasks == 0
            ? context.l10n.noTasksToday
            : context.l10n.smartTaskCount(pendingTasks),
        important: context.l10n.cropCalendar,
        badge: pendingTasks == 0
            ? context.l10n.smartUpToDate
            : context.l10n.today,
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.cropCalendar),
      ),
      _DashboardItem(
        key: 'smart_disease_card',
        icon: Icons.health_and_safety_outlined,
        title: context.l10n.smartDiseaseRisk,
        primary: risk,
        important: currentCrop == null
            ? context.l10n.noCropsYet
            : context.l10n.scanDisease,
        badge: risk == context.l10n.smartRiskHigh
            ? context.l10n.smartNeedsAttention
            : context.l10n.smartReady,
        badgeWarning: risk != context.l10n.smartRiskLow,
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
      ),
    ];
  }

  String _risk(BuildContext context, String? severity) {
    final value =
        severity ??
        switch (currentCrop?.health) {
          CropHealth.needsAttention => 'high',
          CropHealth.moderate => 'medium',
          _ when (weather?.humidityPercent ?? 0) >= 85 => 'medium',
          _ => 'low',
        };
    return switch (value) {
      'high' => context.l10n.smartRiskHigh,
      'medium' => context.l10n.smartRiskMedium,
      _ => context.l10n.smartRiskLow,
    };
  }

  String _date(DateTime date) => '${date.day}/${date.month}';
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.items, super.key});
  final List<_DashboardItem> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 360
          ? 1
          : constraints.maxWidth >= 760
          ? 4
          : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 1
              ? 1.7
              : columns == 4
              ? 1.05
              : 0.9,
        ),
        itemBuilder: (context, index) => TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 180 + index * 45),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 6 * (1 - value)),
              child: child,
            ),
          ),
          child: _SmartCard(item: items[index]),
        ),
      );
    },
  );
}

class _SmartCard extends StatelessWidget {
  const _SmartCard({required this.item});
  final _DashboardItem item;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.title}. ${item.primary}. ${item.important}',
    child: AppPressable(
      key: Key(item.key),
      onTap: item.onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: AppColors.primary, size: 22),
                  ),
                  const Spacer(),
                  _StatusBadge(label: item.badge, warning: item.badgeWarning),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 5),
              Text(
                item.primary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              Text(
                item.important,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.warning});
  final String label;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 86),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF1D6) : AppColors.lightGreen,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 4,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
    ),
    itemBuilder: (_, index) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonLine(width: 40),
            const SizedBox(height: 14),
            const _SkeletonLine(width: 120),
            const SizedBox(height: 10),
            const _SkeletonLine(width: 95),
            const Spacer(),
            const _SkeletonLine(width: 72),
          ],
        ),
      ),
    ),
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _DashboardItem {
  const _DashboardItem({
    required this.key,
    required this.icon,
    required this.title,
    required this.primary,
    required this.important,
    required this.badge,
    required this.onTap,
    this.badgeWarning = false,
  });
  final String key;
  final IconData icon;
  final String title;
  final String primary;
  final String important;
  final String badge;
  final VoidCallback onTap;
  final bool badgeWarning;
}
