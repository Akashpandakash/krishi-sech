import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_content.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_scope.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class SeasonalAdviceDetailsPage extends StatelessWidget {
  const SeasonalAdviceDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SeasonalAdviceScope.of(context);
    final weatherController = WeatherScope.of(context);
    final location = LocationScope.of(context).location;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.seasonalAdviceDetails)),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final advice = controller.advice;
          final weather = weatherController.weather;
          if (controller.status == SeasonalAdviceStatus.loading &&
              advice == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (advice == null || weather == null) {
            return _AdviceUnavailable(controller: controller);
          }

          final material = MaterialLocalizations.of(context);
          final updated =
              '${material.formatMediumDate(advice.updatedAt)} • '
              '${material.formatTimeOfDay(TimeOfDay.fromDateTime(advice.updatedAt))}';
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  location?.displayName ?? context.l10n.locationNotSelected,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _DetailTile(
                  icon: Icons.cloud_outlined,
                  title: context.l10n.currentWeatherSummary,
                  value: context.l10n.adviceWeatherSummary(
                    weather.temperatureCelsius.round(),
                    weather.humidityPercent,
                    weather.windSpeedKmh.round(),
                  ),
                ),
                _DetailTile(
                  icon: advice.icon,
                  title: context.l10n.todaysRecommendation,
                  value: advice.description(context),
                ),
                _DetailTile(
                  icon: Icons.help_outline,
                  title: context.l10n.recommendationReason,
                  value: advice.reason(context),
                ),
                _DetailTile(
                  icon: Icons.task_alt,
                  title: context.l10n.recommendedAction,
                  value: advice.action(context),
                ),
                _DetailTile(
                  icon: Icons.warning_amber,
                  title: context.l10n.warningLevel,
                  value: advice.warningLabel(context),
                ),
                _DetailTile(
                  icon: Icons.schedule,
                  title: context.l10n.lastUpdated,
                  value: updated,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.status == SeasonalAdviceStatus.loading
                      ? null
                      : controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.refreshAdvice),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdviceUnavailable extends StatelessWidget {
  const _AdviceUnavailable({required this.controller});

  final SeasonalAdviceController controller;

  @override
  Widget build(BuildContext context) {
    final message = controller.status == SeasonalAdviceStatus.error
        ? context.l10n.adviceUnavailable
        : context.l10n.adviceLocationRequired;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.refreshAdvice),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightGreen,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }
}
