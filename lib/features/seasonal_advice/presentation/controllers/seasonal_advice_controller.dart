import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/domain/entities/seasonal_advice.dart';
import 'package:krishi_sech/features/seasonal_advice/domain/services/seasonal_advice_service.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';

enum SeasonalAdviceStatus { empty, loading, loaded, error }

class SeasonalAdviceController extends ChangeNotifier {
  SeasonalAdviceController({
    required this.weatherController,
    required this.locationController,
    this.service = const SeasonalAdviceService(),
  }) {
    weatherController!.addListener(_updateFromWeather);
    locationController!.addListener(_updateFromWeather);
    _updateFromWeather();
  }

  SeasonalAdviceController.inMemory({SeasonalAdvice? advice})
    : weatherController = null,
      locationController = null,
      service = const SeasonalAdviceService(),
      _advice = advice,
      _status = advice == null
          ? SeasonalAdviceStatus.empty
          : SeasonalAdviceStatus.loaded;

  final WeatherController? weatherController;
  final LocationController? locationController;
  final SeasonalAdviceService service;
  SeasonalAdvice? _advice;
  late SeasonalAdviceStatus _status;

  SeasonalAdvice? get advice => _advice;
  SeasonalAdviceStatus get status => _status;

  Future<void> refresh() async {
    await weatherController?.refresh();
    _updateFromWeather();
  }

  void _updateFromWeather() {
    final weather = weatherController?.weather;
    _status = switch (weatherController?.status) {
      WeatherStatus.loading => SeasonalAdviceStatus.loading,
      WeatherStatus.error => SeasonalAdviceStatus.error,
      WeatherStatus.loaded when weather != null => SeasonalAdviceStatus.loaded,
      _ => SeasonalAdviceStatus.empty,
    };
    if (_status == SeasonalAdviceStatus.loaded && weather != null) {
      _advice = service.generate(weather);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    weatherController?.removeListener(_updateFromWeather);
    locationController?.removeListener(_updateFromWeather);
    super.dispose();
  }
}
