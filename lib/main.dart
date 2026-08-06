import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krishi_sech/app/app.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/core/network/api_config.dart';
import 'package:krishi_sech/core/notifications/local_notification_service.dart';
import 'package:krishi_sech/core/notifications/notification_service.dart';
import 'package:krishi_sech/features/ai_assistant/data/repositories/local_ai_response_repository.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/local_ai_chat_history_store.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/remote_ai_chat_data_source.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/features/location/data/repositories/location_repository_impl.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_token_storage.dart';
import 'package:krishi_sech/features/login/data/repositories/auth_repository_impl.dart';
import 'package:krishi_sech/features/login/presentation/controllers/auth_controller.dart';
import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_health_record_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/crop_health_record_repository_impl.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/synced_crop_repository.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/synced_crop_task_repository.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_health_record_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:krishi_sech/features/weather/data/datasources/local_weather_data_source.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_sech/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:krishi_sech/features/profile/data/datasources/remote_profile_data_source.dart';
import 'package:krishi_sech/features/profile/data/repositories/in_memory_profile_repository.dart';
import 'package:krishi_sech/features/profile/data/repositories/synced_profile_repository.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.validate();
  PaintingBinding.instance.imageCache
    ..maximumSize = 150
    ..maximumSizeBytes = 64 * 1024 * 1024;
  runApp(const _KrishiSechBootstrap());
}

class _KrishiSechBootstrap extends StatefulWidget {
  const _KrishiSechBootstrap();

  @override
  State<_KrishiSechBootstrap> createState() => _KrishiSechBootstrapState();
}

class _KrishiSechBootstrapState extends State<_KrishiSechBootstrap> {
  LocaleController? _localeController;
  LocationController? _locationController;
  WeatherController? _weatherController;
  SeasonalAdviceController? _seasonalAdviceController;
  AiChatController? _aiChatController;
  CropController? _cropController;
  CropTaskController? _cropTaskController;
  CropHealthRecordController? _cropHealthRecordController;
  AuthController? _authController;
  ProfileController? _profileController;
  String? _loadedProfileUserId;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(ApiConfig.checkDevelopmentConnectivity());
      await _initializeAuthentication();
      await _initializeServices();
    });
  }

  Future<void> _initializeAuthentication() async {
    final controller = AuthController(
      AuthRepositoryImpl(
        AuthRemoteDataSource(baseUrl: ApiConfig.baseUrl),
        const SecureAuthTokenStorage(),
      ),
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    controller.addListener(_handleAuthChange);
    setState(() {
      _authController?.removeListener(_handleAuthChange);
      _authController?.dispose();
      _authController = controller;
      _revision++;
    });
    await _safeLoad(
      'authentication',
      controller.initialize,
      const Duration(seconds: 8),
    );
  }

  Future<void> _initializeServices() async {
    final localeController =
        await _safeLoad(
          'localization',
          LocaleController.load,
          const Duration(seconds: 4),
        ) ??
        LocaleController.inMemory();

    final preferences = await _safeLoad(
      'shared preferences',
      SharedPreferences.getInstance,
      const Duration(seconds: 4),
    );

    final profileController = ProfileController(
      preferences == null
          ? InMemoryProfileRepository()
          : SyncedProfileRepository(
              LocalProfileDataSource(preferences),
              RemoteProfileDataSource(
                baseUrl: ApiConfig.baseUrl,
                accessTokenProvider: ({bool forceRefresh = false}) =>
                    _authController?.getAccessToken(
                      forceRefresh: forceRefresh,
                    ) ??
                    Future<String?>.value(),
              ),
            ),
      demoMode:
          AppEnvironment.demoModeEnabled &&
          _authController?.session?.user.phone == '+919999999999',
    );
    if (_authController?.isAuthenticated == true) {
      await _safeLoad(
        'profile',
        profileController.load,
        const Duration(seconds: 6),
      );
      _loadedProfileUserId = _authController?.session?.user.id;
    }

    NotificationService notificationService = const NoopNotificationService();
    final localNotifications = LocalNotificationService();
    final notificationsReady = await _safeLoad('local notifications', () async {
      await localNotifications.initialize(onTap: _handleNotificationTap);
      return true;
    }, const Duration(seconds: 4));
    if (notificationsReady == true) notificationService = localNotifications;

    final locationController = preferences == null
        ? LocationController.inMemory()
        : await _safeLoad(
                'saved location',
                () => LocationController.load(
                  LocationRepositoryImpl(
                    preferences: preferences,
                    locationService: const LocationService(),
                  ),
                ),
                const Duration(seconds: 4),
              ) ??
              LocationController.inMemory();

    final cropController = preferences == null
        ? CropController.inMemory()
        : await _safeLoad(
                'crop repository',
                () => CropController.load(
                  SyncedCropRepository(
                    LocalCropDataSource(preferences),
                    RemoteCropDataSource(
                      baseUrl: ApiConfig.baseUrl,
                      accessTokenProvider: ({bool forceRefresh = false}) =>
                          _authController?.getAccessToken(
                            forceRefresh: forceRefresh,
                          ) ??
                          Future<String?>.value(),
                    ),
                  ),
                ),
                const Duration(seconds: 4),
              ) ??
              CropController.inMemory();

    final cropTaskController = preferences == null
        ? CropTaskController.inMemory(cropController: cropController)
        : await _safeLoad(
                'crop task repository',
                () => CropTaskController.load(
                  repository: SyncedCropTaskRepository(
                    LocalCropTaskDataSource(preferences),
                    RemoteCropTaskDataSource(
                      baseUrl: ApiConfig.baseUrl,
                      accessTokenProvider: ({bool forceRefresh = false}) =>
                          _authController?.getAccessToken(
                            forceRefresh: forceRefresh,
                          ) ??
                          Future<String?>.value(),
                    ),
                  ),
                  cropController: cropController,
                  notificationService: notificationService,
                  languageCodeProvider: () =>
                      localeController.locale.languageCode,
                ),
                const Duration(seconds: 6),
              ) ??
              CropTaskController.inMemory(cropController: cropController);

    final cropHealthRecordController = preferences == null
        ? CropHealthRecordController.inMemory()
        : await _safeLoad(
                'crop health record repository',
                () => CropHealthRecordController.load(
                  CropHealthRecordRepositoryImpl(
                    LocalCropHealthRecordDataSource(preferences),
                  ),
                ),
                const Duration(seconds: 4),
              ) ??
              CropHealthRecordController.inMemory();

    final weatherController = WeatherController(
      repository: preferences == null
          ? null
          : WeatherRepositoryImpl(
              WeatherService(
                baseUrl: ApiConfig.baseUrl,
                languageProvider: () => AppLanguageCatalog.serviceCodeFor(
                  localeController.locale.languageCode,
                ),
              ),
              LocalWeatherDataSource(preferences),
            ),
      locationController: locationController,
    );
    final seasonalAdviceController = SeasonalAdviceController(
      weatherController: weatherController,
      locationController: locationController,
    );
    final aiChatController = AiChatController(
      repository: const LocalAiResponseRepository(),
      locationController: locationController,
      weatherController: weatherController,
      gateway: RemoteAiChatDataSource(
        baseUrl: ApiConfig.baseUrl,
        accessTokenProvider: ({bool forceRefresh = false}) =>
            _authController?.getAccessToken(forceRefresh: forceRefresh) ??
            Future<String?>.value(),
      ),
      historyStore: preferences == null
          ? null
          : LocalAiChatHistoryStore(preferences),
      languageProvider: () => AppLanguageCatalog.serviceCodeFor(
        localeController.locale.languageCode,
      ),
    );
    await aiChatController.restoreHistory();

    if (!mounted) {
      cropTaskController.dispose();
      cropHealthRecordController.dispose();
      cropController.dispose();
      aiChatController.dispose();
      seasonalAdviceController.dispose();
      weatherController.dispose();
      locationController.dispose();
      localeController.dispose();
      return;
    }
    setState(() {
      _localeController = localeController;
      _locationController = locationController;
      _weatherController = weatherController;
      _seasonalAdviceController = seasonalAdviceController;
      _aiChatController = aiChatController;
      _cropController = cropController;
      _cropTaskController = cropTaskController;
      _cropHealthRecordController = cropHealthRecordController;
      _profileController = profileController;
      _revision++;
    });
  }

  void _handleNotificationTap(String? payload) {
    if (!(payload?.startsWith('crop-task:') ?? false)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.cropCalendar);
    });
  }

  void _handleAuthChange() {
    final session = _authController?.session;
    final userId = session?.user.id;
    if (_profileController == null) {
      return;
    }
    if (userId == null) {
      _loadedProfileUserId = null;
      _profileController!.clearSession();
      return;
    }
    if (userId == _loadedProfileUserId) return;
    _loadedProfileUserId = userId;
    if (AppEnvironment.demoModeEnabled && userId == 'demo-farmer') {
      _profileController!.enterDemoMode();
      return;
    }
    unawaited(
      _safeLoad(
        'profile after login',
        _profileController!.load,
        const Duration(seconds: 6),
      ),
    );
  }

  Future<T?> _safeLoad<T>(
    String name,
    Future<T> Function() load,
    Duration timeout,
  ) async {
    try {
      return await load().timeout(timeout);
    } catch (error, stackTrace) {
      if (kDebugMode && AppEnvironment.loggingEnabled) {
        debugPrint('Startup service failed: $name: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  @override
  void dispose() {
    _cropTaskController?.dispose();
    _cropHealthRecordController?.dispose();
    _cropController?.dispose();
    _aiChatController?.dispose();
    _seasonalAdviceController?.dispose();
    _weatherController?.dispose();
    _locationController?.dispose();
    _localeController?.dispose();
    _authController?.removeListener(_handleAuthChange);
    _authController?.dispose();
    _profileController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KrishiSechApp(
    key: ValueKey(_revision),
    localeController: _localeController,
    locationController: _locationController,
    weatherController: _weatherController,
    seasonalAdviceController: _seasonalAdviceController,
    aiChatController: _aiChatController,
    cropController: _cropController,
    cropTaskController: _cropTaskController,
    cropHealthRecordController: _cropHealthRecordController,
    authController: _authController,
    profileController: _profileController,
  );
}
