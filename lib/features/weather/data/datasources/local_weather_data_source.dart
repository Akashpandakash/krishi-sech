import 'dart:convert';

import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalWeatherDataSource {
  const LocalWeatherDataSource(this._preferences);

  static const _cacheKey = 'latest_weather_cache';
  final SharedPreferences _preferences;

  Future<void> save(FarmLocation location, CurrentWeather weather) =>
      _preferences.setString(
        _cacheKey,
        jsonEncode({
          'locationKey': _locationKey(location),
          'weather': {
            'temperatureCelsius': weather.temperatureCelsius,
            'weatherCode': weather.weatherCode,
            'humidityPercent': weather.humidityPercent,
            'windSpeedKmh': weather.windSpeedKmh,
            'feelsLikeCelsius': weather.feelsLikeCelsius,
            'rainProbabilityPercent': weather.rainProbabilityPercent,
            'minimumTemperatureCelsius': weather.minimumTemperatureCelsius,
            'maximumTemperatureCelsius': weather.maximumTemperatureCelsius,
            'updatedAt': weather.updatedAt?.toIso8601String(),
          },
        }),
      );

  Future<CurrentWeather?> read(FarmLocation location) async {
    final raw = _preferences.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['locationKey'] != _locationKey(location)) return null;
      final weather = json['weather'] as Map<String, dynamic>;
      return CurrentWeather(
        temperatureCelsius: (weather['temperatureCelsius'] as num).toDouble(),
        weatherCode: (weather['weatherCode'] as num).round(),
        humidityPercent: (weather['humidityPercent'] as num).round(),
        windSpeedKmh: (weather['windSpeedKmh'] as num).toDouble(),
        feelsLikeCelsius: (weather['feelsLikeCelsius'] as num?)?.toDouble(),
        rainProbabilityPercent: (weather['rainProbabilityPercent'] as num?)
            ?.round(),
        minimumTemperatureCelsius:
            (weather['minimumTemperatureCelsius'] as num?)?.toDouble(),
        maximumTemperatureCelsius:
            (weather['maximumTemperatureCelsius'] as num?)?.toDouble(),
        updatedAt: DateTime.tryParse(weather['updatedAt'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  String _locationKey(FarmLocation location) =>
      '${location.city.trim().toLowerCase()}|'
      '${location.district.trim().toLowerCase()}|'
      '${location.state.trim().toLowerCase()}|'
      '${location.country.trim().toLowerCase()}';
}
