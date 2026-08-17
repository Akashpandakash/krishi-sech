import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_theme.dart';
import 'package:krishi_sech/core/network/api_config.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/remote_ai_chat_data_source.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/ai_chat_scope.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/core/localization/app_localization_config.dart';
import 'package:krishi_sech/core/observability/analytics_service.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/login/data/repositories/in_memory_auth_repository.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/login/presentation/controllers/auth_controller.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_health_record_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_health_record_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_scope.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';
import 'package:krishi_sech/features/profile/data/repositories/in_memory_profile_repository.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';
import 'package:krishi_sech/features/profile/presentation/profile_scope.dart';
import 'package:krishi_sech/features/notifications/data/datasources/remote_app_notification_data_source.dart';
import 'package:krishi_sech/features/notifications/data/repositories/app_notification_repository_impl.dart';
import 'package:krishi_sech/features/notifications/presentation/app_notification_scope.dart';
import 'package:krishi_sech/features/notifications/presentation/controllers/app_notification_controller.dart';

class KrishiSechApp extends StatefulWidget {
  const KrishiSechApp({
    this.localeController,
    this.locationController,
    this.weatherController,
    this.seasonalAdviceController,
    this.aiChatController,
    this.cropController,
    this.cropTaskController,
    this.cropHealthRecordController,
    this.authController,
    this.profileController,
    this.notificationController,
    super.key,
  });

  final LocaleController? localeController;
  final LocationController? locationController;
  final WeatherController? weatherController;
  final SeasonalAdviceController? seasonalAdviceController;
  final AiChatController? aiChatController;
  final CropController? cropController;
  final CropTaskController? cropTaskController;
  final CropHealthRecordController? cropHealthRecordController;
  final AuthController? authController;
  final ProfileController? profileController;
  final AppNotificationController? notificationController;

  @override
  State<KrishiSechApp> createState() => _KrishiSechAppState();
}

class _KrishiSechAppState extends State<KrishiSechApp> {
  late final LocaleController _localeController;
  late final LocationController _locationController;
  late final bool _ownsController;
  late final bool _ownsLocationController;
  late final WeatherController _weatherController;
  late final bool _ownsWeatherController;
  late final SeasonalAdviceController _seasonalAdviceController;
  late final bool _ownsSeasonalAdviceController;
  late final AiChatController _aiChatController;
  late final bool _ownsAiChatController;
  late final CropController _cropController;
  late final bool _ownsCropController;
  late final CropTaskController _cropTaskController;
  late final bool _ownsCropTaskController;
  late final CropHealthRecordController _cropHealthRecordController;
  late final bool _ownsCropHealthRecordController;
  late final AuthController _authController;
  late final bool _ownsAuthController;
  late final ProfileController _profileController;
  late final bool _ownsProfileController;
  late final AppNotificationController _notificationController;
  late final bool _ownsNotificationController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.localeController == null;
    _localeController = widget.localeController ?? LocaleController.inMemory();
    _ownsLocationController = widget.locationController == null;
    _locationController =
        widget.locationController ?? LocationController.inMemory();
    _ownsWeatherController = widget.weatherController == null;
    _weatherController =
        widget.weatherController ?? WeatherController.inMemory();
    _ownsSeasonalAdviceController = widget.seasonalAdviceController == null;
    _seasonalAdviceController =
        widget.seasonalAdviceController ?? SeasonalAdviceController.inMemory();
    _ownsAiChatController = widget.aiChatController == null;
    _aiChatController =
        widget.aiChatController ??
        AiChatController(
          gateway: RemoteAiChatDataSource(
            baseUrl: ApiConfig.baseUrl,
            accessTokenProvider: ({bool forceRefresh = false}) =>
                _authController.getAccessToken(forceRefresh: forceRefresh),
          ),
          locationController: _locationController,
          weatherController: _weatherController,
        );
    _ownsCropController = widget.cropController == null;
    _cropController = widget.cropController ?? CropController.inMemory();
    _ownsCropTaskController = widget.cropTaskController == null;
    _cropTaskController =
        widget.cropTaskController ??
        CropTaskController.inMemory(cropController: _cropController);
    _ownsCropHealthRecordController = widget.cropHealthRecordController == null;
    _cropHealthRecordController =
        widget.cropHealthRecordController ??
        CropHealthRecordController.inMemory();
    _ownsAuthController = widget.authController == null;
    _authController =
        widget.authController ?? AuthController(InMemoryAuthRepository());
    _ownsProfileController = widget.profileController == null;
    _profileController =
        widget.profileController ??
        ProfileController(InMemoryProfileRepository());
    _ownsNotificationController = widget.notificationController == null;
    _notificationController =
        widget.notificationController ??
        AppNotificationController(
          AppNotificationRepositoryImpl(
            RemoteAppNotificationDataSource(
              baseUrl: ApiConfig.baseUrl,
              accessTokenProvider: ({bool forceRefresh = false}) =>
                  _authController.getAccessToken(forceRefresh: forceRefresh),
            ),
          ),
        );
    if (widget.notificationController == null) {
      _notificationController.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _localeController.dispose();
    }
    if (_ownsLocationController) {
      _locationController.dispose();
    }
    if (_ownsWeatherController) {
      _weatherController.dispose();
    }
    if (_ownsSeasonalAdviceController) {
      _seasonalAdviceController.dispose();
    }
    if (_ownsAiChatController) {
      _aiChatController.dispose();
    }
    if (_ownsCropTaskController) {
      _cropTaskController.dispose();
    }
    if (_ownsCropController) {
      _cropController.dispose();
    }
    if (_ownsCropHealthRecordController) {
      _cropHealthRecordController.dispose();
    }
    if (_ownsAuthController) {
      _authController.dispose();
    }
    if (_ownsProfileController) _profileController.dispose();
    if (_ownsNotificationController) _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: AppNotificationScope(
        controller: _notificationController,
        child: ProfileScope(
          controller: _profileController,
          child: LocationScope(
            controller: _locationController,
            child: WeatherScope(
              controller: _weatherController,
              child: SeasonalAdviceScope(
                controller: _seasonalAdviceController,
                child: AiChatScope(
                  controller: _aiChatController,
                  child: CropScope(
                    controller: _cropController,
                    child: CropTaskScope(
                      controller: _cropTaskController,
                      child: CropHealthRecordScope(
                        controller: _cropHealthRecordController,
                        child: LocaleScope(
                          controller: _localeController,
                          child: AnimatedBuilder(
                            animation: _localeController,
                            builder: (context, _) {
                              return MaterialApp(
                                navigatorKey: AppRouter.navigatorKey,
                                navigatorObservers: [
                                  ?AnalyticsService.navigatorObserver,
                                ],
                                onGenerateTitle: (context) =>
                                    AppLocalizations.of(context).appTitle,
                                debugShowCheckedModeBanner: false,
                                theme: AppTheme.light,
                                darkTheme: AppTheme.dark,
                                // RC1 uses the fully audited green-and-white theme.
                                // Re-enable system mode when every legacy surface has
                                // migrated away from hard-coded light colors.
                                themeMode: ThemeMode.light,
                                locale: _localeController.locale,
                                supportedLocales:
                                    AppLocalizations.supportedLocales,
                                localizationsDelegates:
                                    AppLocalizationConfig.delegates,
                                builder: (context, child) => Directionality(
                                  textDirection:
                                      AppLocalizationConfig.directionFor(
                                        _localeController.locale,
                                      ),
                                  child: child!,
                                ),
                                initialRoute: AppRoutes.splash,
                                onGenerateRoute: AppRouter.onGenerateRoute,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
