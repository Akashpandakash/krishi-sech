import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krishi_sech/app/app.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/notifications/local_notification_service.dart';
import 'package:krishi_sech/core/notifications/notification_service.dart';
import 'package:krishi_sech/features/ai_assistant/data/repositories/local_ai_response_repository.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/features/location/data/repositories/location_repository_impl.dart';
import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/crop_repository_impl.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/crop_task_repository_impl.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeServices());
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
                  CropRepositoryImpl(LocalCropDataSource(preferences)),
                ),
                const Duration(seconds: 4),
              ) ??
              CropController.inMemory();

    final cropTaskController = preferences == null
        ? CropTaskController.inMemory(cropController: cropController)
        : await _safeLoad(
                'crop task repository',
                () => CropTaskController.load(
                  repository: CropTaskRepositoryImpl(
                    LocalCropTaskDataSource(preferences),
                  ),
                  cropController: cropController,
                  notificationService: notificationService,
                  languageCodeProvider: () =>
                      localeController.locale.languageCode,
                ),
                const Duration(seconds: 6),
              ) ??
              CropTaskController.inMemory(cropController: cropController);

    final weatherController = WeatherController(
      repository: const WeatherRepositoryImpl(WeatherService()),
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
    );

    if (!mounted) {
      cropTaskController.dispose();
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
      _revision++;
    });
  }

  void _handleNotificationTap(String? payload) {
    if (!(payload?.startsWith('crop-task:') ?? false)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.cropCalendar);
    });
  }

  Future<T?> _safeLoad<T>(
    String name,
    Future<T> Function() load,
    Duration timeout,
  ) async {
    try {
      return await load().timeout(timeout);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Startup service failed: $name: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  @override
  void dispose() {
    _cropTaskController?.dispose();
    _cropController?.dispose();
    _aiChatController?.dispose();
    _seasonalAdviceController?.dispose();
    _weatherController?.dispose();
    _locationController?.dispose();
    _localeController?.dispose();
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
  );
}
