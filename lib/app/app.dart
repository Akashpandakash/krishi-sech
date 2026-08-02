import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_theme.dart';
import 'package:krishi_sech/features/ai_assistant/data/repositories/local_ai_response_repository.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/ai_chat_scope.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_scope.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

class KrishiSechApp extends StatefulWidget {
  const KrishiSechApp({
    this.localeController,
    this.locationController,
    this.weatherController,
    this.seasonalAdviceController,
    this.aiChatController,
    this.cropController,
    this.cropTaskController,
    super.key,
  });

  final LocaleController? localeController;
  final LocationController? locationController;
  final WeatherController? weatherController;
  final SeasonalAdviceController? seasonalAdviceController;
  final AiChatController? aiChatController;
  final CropController? cropController;
  final CropTaskController? cropTaskController;

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
          repository: const LocalAiResponseRepository(),
          locationController: _locationController,
          weatherController: _weatherController,
        );
    _ownsCropController = widget.cropController == null;
    _cropController = widget.cropController ?? CropController.inMemory();
    _ownsCropTaskController = widget.cropTaskController == null;
    _cropTaskController =
        widget.cropTaskController ??
        CropTaskController.inMemory(cropController: _cropController);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocationScope(
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
                child: LocaleScope(
                  controller: _localeController,
                  child: AnimatedBuilder(
                    animation: _localeController,
                    builder: (context, _) {
                      return MaterialApp(
                        navigatorKey: AppRouter.navigatorKey,
                        onGenerateTitle: (context) =>
                            AppLocalizations.of(context).appTitle,
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.light,
                        darkTheme: AppTheme.dark,
                        themeMode: ThemeMode.system,
                        locale: _localeController.locale,
                        supportedLocales: AppLocalizations.supportedLocales,
                        localizationsDelegates: const [
                          AppLocalizations.delegate,
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
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
    );
  }
}
