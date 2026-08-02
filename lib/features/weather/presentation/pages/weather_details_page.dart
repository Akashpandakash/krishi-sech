import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class WeatherDetailsPage extends StatelessWidget {
  const WeatherDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WeatherScope.of(context);
    final location = LocationScope.of(context).location;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.weatherDetails)),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final weather = controller.weather;
          if (controller.status == WeatherStatus.loading && weather == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (weather == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.weatherUnavailable,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.refreshWeather),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  location?.displayName ?? context.l10n.locationNotSelected,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      color: AppColors.warning,
                      size: 52,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${weather.temperatureCelsius.round()}°C',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _condition(context, weather.weatherCode),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _WeatherDetail(
                  icon: Icons.device_thermostat,
                  label: context.l10n.feelsLike,
                  value: _temperature(weather.feelsLikeCelsius),
                ),
                _WeatherDetail(
                  icon: Icons.water_drop_outlined,
                  label: context.l10n.humidity,
                  value: '${weather.humidityPercent}%',
                ),
                _WeatherDetail(
                  icon: Icons.air,
                  label: context.l10n.windSpeed,
                  value: '${weather.windSpeedKmh.round()} km/h',
                ),
                _WeatherDetail(
                  icon: Icons.umbrella_outlined,
                  label: context.l10n.rainProbability,
                  value: weather.rainProbabilityPercent == null
                      ? context.l10n.notAvailable
                      : '${weather.rainProbabilityPercent}%',
                ),
                _WeatherDetail(
                  icon: Icons.thermostat,
                  label: context.l10n.todayMinMax,
                  value:
                      '${_temperature(weather.minimumTemperatureCelsius)} / '
                      '${_temperature(weather.maximumTemperatureCelsius)}',
                ),
                _WeatherDetail(
                  icon: Icons.schedule,
                  label: context.l10n.lastUpdated,
                  value: _updatedAt(context, weather.updatedAt),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: controller.status == WeatherStatus.loading
                      ? null
                      : controller.refresh,
                  icon: controller.status == WeatherStatus.loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(context.l10n.refreshWeather),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _temperature(double? value) =>
      value == null ? '—' : '${value.round()}°C';

  String _updatedAt(BuildContext context, DateTime? value) {
    if (value == null) return context.l10n.notAvailable;
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(value)} • '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  String _condition(BuildContext context, int code) {
    if (code == 0) return context.l10n.weatherClear;
    if (code == 1) return context.l10n.weatherMainlyClear;
    if (code == 2) return context.l10n.partlyCloudy;
    if (code == 3) return context.l10n.weatherOvercast;
    if (code == 45 || code == 48) return context.l10n.weatherFog;
    if (code >= 51 && code <= 57) return context.l10n.weatherDrizzle;
    if (code >= 71 && code <= 77 || code >= 85 && code <= 86) {
      return context.l10n.weatherSnow;
    }
    if (code >= 61 && code <= 82) return context.l10n.weatherRain;
    if (code >= 95) return context.l10n.weatherThunderstorm;
    return context.l10n.weatherUnavailable;
  }
}

class _WeatherDetail extends StatelessWidget {
  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.lightGreen,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
