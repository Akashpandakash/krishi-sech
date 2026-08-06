import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/core/network/api_config.dart';
import 'package:krishi_sech/features/disease_scan/data/datasources/local_disease_diagnosis_store.dart';
import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/features/notifications/presentation/widgets/home_notification_bell.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_content.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_scope.dart';
import 'package:krishi_sech/features/smart_dashboard/data/datasources/remote_smart_recommendation_data_source.dart';
import 'package:krishi_sech/features/smart_dashboard/data/datasources/smart_recommendation_cache.dart';
import 'package:krishi_sech/features/smart_dashboard/data/repositories/smart_recommendation_repository.dart';
import 'package:krishi_sech/features/smart_dashboard/presentation/controllers/smart_recommendation_controller.dart';
import 'package:krishi_sech/features/smart_dashboard/presentation/widgets/smart_farming_dashboard.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/section_header.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';
import 'package:krishi_sech/features/profile/presentation/profile_scope.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SmartRecommendationController? _smartController;
  String? _smartLanguage;
  Future<void>? _refreshInFlight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _smartController ??= SmartRecommendationController(
      SmartRecommendationRepository(
        RemoteSmartRecommendationDataSource(
          baseUrl: ApiConfig.baseUrl,
          accessTokenProvider: ({bool forceRefresh = false}) async =>
              AuthScope.maybeOf(
                context,
              )?.getAccessToken(forceRefresh: forceRefresh),
        ),
        SmartRecommendationCache(),
        LocalDiseaseDiagnosisStore(),
      ),
    );
    final language = AppLanguageCatalog.serviceCodeFor(
      Localizations.localeOf(context).languageCode,
    );
    if (_smartLanguage != language) {
      _smartLanguage = language;
      unawaited(_smartController!.refresh(language));
    }
  }

  Future<void> _refreshHome() async {
    if (_refreshInFlight != null) return _refreshInFlight!;
    final refresh = Future.wait([
      WeatherScope.of(context).refresh(),
      CropScope.of(context).refresh(),
      CropTaskScope.of(context).refresh(),
      _smartController!.refresh(
        AppLanguageCatalog.serviceCodeFor(
          Localizations.localeOf(context).languageCode,
        ),
      ),
    ]);
    _refreshInFlight = refresh;
    try {
      await refresh;
    } finally {
      _refreshInFlight = null;
    }
  }

  @override
  void dispose() {
    _smartController?.dispose();
    super.dispose();
  }

  Future<void> _showLocationSheet() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
      ),
      builder: (_) => const LocationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherController = WeatherScope.of(context);
    final cropController = CropScope.of(context);
    final cropTaskController = CropTaskScope.of(context);
    final crops = cropController.crops;
    final activeCrops = crops
        .where((crop) => crop.growthStage != GrowthStage.harvested)
        .toList(growable: false);
    final currentCrop = activeCrops.isNotEmpty
        ? activeCrops.first
        : crops.isNotEmpty
        ? crops.first
        : null;
    final marketPrices = [
      _MarketItem(context.l10n.wheat, '₹2,425', '+1.8%', Icons.grass),
      _MarketItem(context.l10n.mustard, '₹5,680', '+0.9%', Icons.local_florist),
      _MarketItem(context.l10n.tomato, '₹2,100', '-1.2%', Icons.eco),
    ];
    final tasks = cropTaskController.todaysTasks;
    final services = [
      _ServiceItem(context.l10n.cropDoctor, Icons.health_and_safety_outlined),
      _ServiceItem(context.l10n.weather, Icons.cloud_outlined),
      _ServiceItem(context.l10n.mandiRates, Icons.currency_rupee),
      _ServiceItem(context.l10n.farmTips, Icons.lightbulb_outline),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocationBar(onTap: _showLocationSheet),
                    const SizedBox(height: 22),
                    const _GreetingSection(),
                    const SizedBox(height: 22),
                    const HomeWeatherCard(),
                    const SizedBox(height: 18),
                    const _FarmingBanner(),
                    const SizedBox(height: 18),
                    const _AiAssistantCard(),
                    const SizedBox(height: 28),
                    SectionHeader(
                      title: context.l10n.myCrops,
                      action: context.l10n.viewAll,
                      onAction: () =>
                          Navigator.of(context).pushNamed(AppRoutes.myCrop),
                    ),
                    const SizedBox(height: 12),
                    _HorizontalList(
                      height: 154,
                      itemCount: crops.length,
                      itemBuilder: (index) => _CropCard(crop: crops[index]),
                    ),
                    const SizedBox(height: 28),
                    SectionHeader(
                      title: context.l10n.marketPrices,
                      action: context.l10n.viewMandi,
                    ),
                    const SizedBox(height: 12),
                    _MarketPricesCard(items: marketPrices),
                    const SizedBox(height: 28),
                    SectionHeader(
                      title: context.l10n.todaysTasks,
                      action: context.l10n.viewCalendar,
                      onAction: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.cropCalendar),
                    ),
                    const SizedBox(height: 12),
                    if (tasks.isEmpty)
                      Text(context.l10n.noTasksToday)
                    else
                      ...tasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TaskCard(
                            task: task,
                            cropName:
                                cropController.cropById(task.cropId) == null
                                ? ''
                                : cropKindLabel(
                                    context,
                                    cropController.cropById(task.cropId)!,
                                  ),
                            onChanged: () =>
                                cropTaskController.toggleCompleted(task.id),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    SectionHeader(title: context.l10n.quickServices),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 4 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: services.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.3,
                              ),
                          itemBuilder: (context, index) {
                            return _ServiceCard(service: services[index]);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    SmartFarmingDashboard(
                      controller: _smartController!,
                      weather: weatherController.weather,
                      tasks: tasks,
                      currentCrop: currentCrop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locationController = LocationScope.of(context);

    return Row(
      children: [
        AppPressable(
          haptic: AppPressableHaptic.selection,
          onTap: onTap,
          child: Material(
            color: AppColors.lightGreen,
            shape: const CircleBorder(),
            child: SizedBox.square(
              key: const Key('home_location_icon'),
              dimension: 42,
              child: const Icon(Icons.location_on, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppPressable(
            key: const Key('home_location_area'),
            haptic: AppPressableHaptic.selection,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.yourLocation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: AnimatedBuilder(
                        animation: locationController,
                        builder: (context, _) => Text(
                          locationController.location?.displayName ??
                              context.l10n.locationNotSelected,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.keyboard_arrow_down, size: 19),
                  ],
                ),
              ],
            ),
          ),
        ),
        const HomeNotificationBell(),
      ],
    );
  }
}

@visibleForTesting
class LocationBottomSheet extends StatefulWidget {
  const LocationBottomSheet({
    super.key,
    this.environment = AppEnvironment.appEnv,
  });

  final String environment;

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  bool _refreshing = false;
  LocationFailureType? _locationFailure;

  Future<void> _refreshLocation() async {
    final controller = LocationScope.of(context);
    setState(() {
      _refreshing = true;
      _locationFailure = null;
    });

    final failure = await controller.detectCurrentLocation(force: true);
    if (mounted) {
      setState(() {
        _refreshing = false;
        _locationFailure = failure;
      });
    }
  }

  Future<void> _openManualSelection() async {
    final controller = LocationScope.of(context);
    final locationBefore = controller.location;
    await Navigator.of(context).pushNamed(AppRoutes.manualLocation);
    if (mounted && !identical(locationBefore, controller.location)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = LocationScope.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final location = controller.location;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.yourLocationTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.lightGreen,
                            child: Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location?.displayName ??
                                      context.l10n.locationNotSelected,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  location == null
                                      ? context.l10n.locationPermissionHint
                                      : location.accuracyMeters == null
                                      ? context.l10n.usingSavedLocation
                                      : context.l10n.locationAccuracy(
                                          location.accuracyMeters!.round(),
                                        ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (location != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _LocationDetail(
                                label: context.l10n.city,
                                value: location.city,
                              ),
                            ),
                            Expanded(
                              child: _LocationDetail(
                                label: context.l10n.district,
                                value: location.district,
                              ),
                            ),
                            Expanded(
                              child: _LocationDetail(
                                label: context.l10n.state,
                                value: location.state,
                              ),
                            ),
                          ],
                        ),
                        if (AppEnvironment.locationDebugEnabledFor(
                              widget.environment,
                            ) &&
                            location.latitude != null &&
                            location.longitude != null) ...[
                          const SizedBox(height: 16),
                          _LocationDebugSection(location: location),
                        ],
                      ],
                      if (_locationFailure != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _locationFailureMessage(context, _locationFailure!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (_locationFailure ==
                                LocationFailureType.serviceDisabled ||
                            _locationFailure ==
                                LocationFailureType.reducedAccuracy ||
                            _locationFailure ==
                                LocationFailureType.permissionPermanentlyDenied)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                if (_locationFailure ==
                                    LocationFailureType.serviceDisabled) {
                                  controller.openLocationSettings();
                                } else {
                                  controller.openAppSettings();
                                }
                              },
                              child: Text(
                                _locationFailure ==
                                        LocationFailureType.serviceDisabled
                                    ? context.l10n.openLocationSettings
                                    : context.l10n.openAppSettings,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const Key('refresh_current_location'),
                        onPressed: _refreshing ? null : _refreshLocation,
                        icon: _refreshing
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: Text(context.l10n.refreshCurrentLocation),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        key: const Key('add_change_location'),
                        onTap: _openManualSelection,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.lightGreen,
                          child: Icon(
                            Icons.add_location_alt_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          context.l10n.addChangeLocation,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _locationFailureMessage(
  BuildContext context,
  LocationFailureType failure,
) {
  return switch (failure) {
    LocationFailureType.serviceDisabled =>
      context.l10n.locationServicesDisabled,
    LocationFailureType.reducedAccuracy => context.l10n.preciseLocationRequired,
    LocationFailureType.permissionPermanentlyDenied =>
      context.l10n.locationPermissionPermanentlyDenied,
    LocationFailureType.detectionTimedOut =>
      context.l10n.locationDetectionTimedOut,
    LocationFailureType.addressUnavailable =>
      context.l10n.locationAddressUnavailable,
    LocationFailureType.permissionDenied => context.l10n.locationDeniedFriendly,
  };
}

class _LocationDebugSection extends StatelessWidget {
  const _LocationDebugSection({required this.location});

  final FarmLocation location;

  Future<void> _copyCoordinates(BuildContext context) async {
    final coordinates = '${location.latitude}, ${location.longitude}';
    await Clipboard.setData(ClipboardData(text: coordinates));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Coordinates copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Latitude', location.latitude!.toStringAsFixed(7)),
      ('Longitude', location.longitude!.toStringAsFixed(7)),
      (
        'Accuracy',
        location.accuracyMeters == null
            ? 'Unavailable'
            : '${location.accuracyMeters!.toStringAsFixed(1)} m',
      ),
      (
        'GPS timestamp',
        location.gpsTimestamp?.toIso8601String() ?? 'Unavailable',
      ),
      ('Detected locality', location.detectedLocality ?? location.city),
      ('Detected district', location.district),
      ('Detected state', location.state),
      ('Full formatted address', location.fullAddress ?? location.displayName),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Location debug',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${row.$1}: ${row.$2}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              key: const Key('copy_location_coordinates'),
              onPressed: () => _copyCoordinates(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Coordinates'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDetail extends StatelessWidget {
  const _LocationDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.goodMorning,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${ProfileScope.maybeOf(context)?.greetingName ?? context.l10n.farmer} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.l10n.productiveFarm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: context.l10n.profile,
          child: AppPressable(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            child: const SizedBox.square(
              dimension: 56,
              child: CircleAvatar(
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.person, size: 32, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeWeatherCard extends StatelessWidget {
  const HomeWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WeatherScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final weather = controller.weather;
            final isLoading = controller.status == WeatherStatus.loading;
            final hasError = controller.status == WeatherStatus.error;
            final cached = controller.isUsingCachedData;
            final temperature = weather == null
                ? '--°C'
                : '${weather.temperatureCelsius.round()}°C';
            final condition = weather != null
                ? _weatherCondition(context, weather.weatherCode)
                : hasError
                ? kDebugMode && controller.errorReason != null
                      ? controller.errorReason!
                      : context.l10n.weatherUnavailable
                : isLoading
                ? context.l10n.loadingWeather
                : weather == null
                ? context.l10n.weatherLocationRequired
                : context.l10n.weatherUnavailable;
            final details = weather == null
                ? (hasError ? context.l10n.pullToRefresh : '')
                : context.l10n.humidityWindValues(
                    weather.humidityPercent,
                    weather.windSpeedKmh.round(),
                  );

            final VoidCallback? onTap = isLoading
                ? null
                : weather == null
                ? controller.refresh
                : () =>
                      Navigator.of(context).pushNamed(AppRoutes.weatherDetails);

            return AppPressable(
              key: const Key('weather_card'),
              enabled: onTap != null,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_outlined,
                        color: AppColors.warning,
                        size: 36,
                      ),
                    ),
                    const ColoredBox(
                      key: Key('weather_card_empty_space'),
                      color: Colors.transparent,
                      child: SizedBox(width: 16, height: 62),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final temperatureText = Text(
                                key: const Key('weather_temperature'),
                                temperature,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              );
                              final conditionText = Text(
                                condition,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                              if (constraints.maxWidth < 150) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [temperatureText, conditionText],
                                );
                              }
                              return Row(
                                children: [
                                  Flexible(child: temperatureText),
                                  const SizedBox(width: 9),
                                  Expanded(child: conditionText),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 5),
                          LayoutBuilder(
                            builder: (context, constraints) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather?.rainProbabilityPercent == null
                                      ? details
                                      : '$details • ${context.l10n.rainProbability} ${weather!.rainProbabilityPercent}%',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (cached) ...[
                                  const SizedBox(height: 4),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: _WeatherBadge(
                                      label: context.l10n.smartOfflineData,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (weather?.updatedAt != null)
                            Text(
                              '${context.l10n.lastUpdated}: ${TimeOfDay.fromDateTime(weather!.updatedAt!.toLocal()).format(context)}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            button: true,
                            label: context.l10n.refreshWeather,
                            child: IconButton(
                              key: const Key('weather_refresh_action'),
                              tooltip: context.l10n.refreshWeather,
                              onPressed: controller.refresh,
                              icon: const Icon(Icons.refresh),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            key: Key('weather_card_arrow'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  const _WeatherBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

String _weatherCondition(BuildContext context, int code) {
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

class _FarmingBanner extends StatelessWidget {
  const _FarmingBanner();

  @override
  Widget build(BuildContext context) {
    final controller = SeasonalAdviceScope.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final advice = controller.advice;
            final isLoading = controller.status == SeasonalAdviceStatus.loading;
            final hasError = controller.status == SeasonalAdviceStatus.error;
            final isReady =
                controller.status == SeasonalAdviceStatus.loaded &&
                advice != null;
            final title = isLoading
                ? context.l10n.loadingAdvice
                : hasError
                ? context.l10n.adviceUnavailable
                : advice?.title(context) ?? context.l10n.adviceLocationRequired;
            final description = isReady
                ? advice.description(context)
                : hasError
                ? context.l10n.pullToRefresh
                : context.l10n.adviceWaitingForWeather;
            void handleTap() {
              if (isReady) {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.seasonalAdviceDetails);
              } else {
                controller.refresh();
              }
            }

            return Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2F8E4C), AppColors.primaryDark],
                ),
              ),
              child: AppPressable(
                key: const Key('seasonal_advice_card'),
                enabled: !isLoading,
                onTap: isLoading ? null : handleTap,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        bottom: -18,
                        child: Icon(
                          advice?.icon ?? Icons.agriculture,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.13),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              advice?.category(context) ??
                                  context.l10n.seasonalAdvice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            key: const Key('seasonal_advice_title'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (isReady) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.updatedAtTime(
                                MaterialLocalizations.of(
                                  context,
                                ).formatTimeOfDay(
                                  TimeOfDay.fromDateTime(advice.updatedAt),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          IgnorePointer(
                            child: FilledButton(
                              key: const Key('view_seasonal_recommendation'),
                              onPressed: isLoading ? null : handleTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                              ),
                              child: isLoading
                                  ? const SizedBox.square(
                                      dimension: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(context.l10n.viewRecommendation),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF5FF),
      borderRadius: BorderRadius.circular(22),
      child: AppPressable(
        key: const Key('home_ai_assistant_card'),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF2563A8),
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.askKrishiAi,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(context.l10n.askKrishiAiSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => itemBuilder(index),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.eco, color: AppColors.primary, size: 29),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropKindLabel(context, crop),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  growthStageLabel(context, crop.growthStage),
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 3),
                Text(
                  cropHealthLabel(context, crop.health),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  cropTaskLabel(context, crop.nextTask),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketPricesCard extends StatelessWidget {
  const _MarketPricesCard({required this.items});

  final List<_MarketItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _MarketPriceRow(item: items[index]),
            if (index != items.length - 1)
              const Divider(height: 1, indent: 66, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _MarketPriceRow extends StatelessWidget {
  const _MarketPriceRow({required this.item});

  final _MarketItem item;

  @override
  Widget build(BuildContext context) {
    final isUp = item.change.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightGreen,
            child: Icon(item.icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.price,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                context.l10n.priceToday(item.change),
                style: TextStyle(
                  color: isUp ? AppColors.primary : Colors.red.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.cropName,
    required this.onChanged,
  });

  final CropTask task;
  final String cropName;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            cropTaskReminderIcon(task.type),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          cropTaskReminderLabel(context, task.type),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (cropName.isNotEmpty) cropName,
            MaterialLocalizations.of(context).formatMediumDate(task.dueDate),
          ].join(' • '),
        ),
        trailing: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onChanged(),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final _ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: AppPressable(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(service.icon, color: AppColors.primary, size: 30),
              const SizedBox(height: 8),
              Text(
                service.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketItem {
  const _MarketItem(this.name, this.price, this.change, this.icon);

  final String name;
  final String price;
  final String change;
  final IconData icon;
}

class _ServiceItem {
  const _ServiceItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
