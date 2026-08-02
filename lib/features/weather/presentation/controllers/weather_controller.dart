import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/features/weather/domain/repositories/weather_repository.dart';

enum WeatherStatus { idle, loading, loaded, error }

class WeatherController extends ChangeNotifier {
  WeatherController({
    required this.repository,
    required this.locationController,
  }) {
    locationController!.addListener(_onLocationChanged);
    _locationKey = _keyFor(locationController!.location);
    if (locationController!.location != null) unawaited(refresh());
  }

  WeatherController.inMemory({CurrentWeather? weather})
    : repository = null,
      locationController = null {
    _weather = weather;
    _status = weather == null ? WeatherStatus.idle : WeatherStatus.loaded;
  }

  final WeatherRepository? repository;
  final LocationController? locationController;
  CurrentWeather? _weather;
  WeatherStatus _status = WeatherStatus.idle;
  String? _locationKey;
  int _requestId = 0;

  CurrentWeather? get weather => _weather;
  WeatherStatus get status => _status;

  Future<void> refresh() async {
    final location = locationController?.location;
    if (repository == null || location == null) {
      _status = WeatherStatus.idle;
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    _status = WeatherStatus.loading;
    notifyListeners();
    try {
      final weather = await repository!.fetchCurrentWeather(location);
      if (requestId != _requestId) return;
      _weather = weather;
      _status = WeatherStatus.loaded;
    } catch (_) {
      if (requestId != _requestId) return;
      _status = WeatherStatus.error;
    }
    notifyListeners();
  }

  void _onLocationChanged() {
    final nextKey = _keyFor(locationController?.location);
    if (nextKey == _locationKey) return;
    _locationKey = nextKey;
    unawaited(refresh());
  }

  String? _keyFor(FarmLocation? location) => location == null
      ? null
      : '${location.latitude}|${location.longitude}|${location.city}|'
            '${location.district}|${location.state}|${location.country}';

  @override
  void dispose() {
    locationController?.removeListener(_onLocationChanged);
    super.dispose();
  }
}
