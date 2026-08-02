import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';

class WeatherService {
  const WeatherService({this.client});

  final http.Client? client;

  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location) async {
    final coordinates = await _coordinatesFor(location);
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': coordinates.$1.toString(),
      'longitude': coordinates.$2.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,'
          'weather_code,wind_speed_10m,precipitation_probability',
      'daily': 'temperature_2m_max,temperature_2m_min',
      'wind_speed_unit': 'kmh',
      'timezone': 'auto',
    });
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const WeatherException();
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final current = payload['current'] as Map<String, dynamic>?;
      final daily = payload['daily'] as Map<String, dynamic>?;
      if (current == null) throw const WeatherException();

      return CurrentWeather(
        temperatureCelsius: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        humidityPercent: (current['relative_humidity_2m'] as num).round(),
        windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
        feelsLikeCelsius: (current['apparent_temperature'] as num?)?.toDouble(),
        rainProbabilityPercent: (current['precipitation_probability'] as num?)
            ?.round(),
        maximumTemperatureCelsius: _firstDailyValue(
          daily?['temperature_2m_max'],
        ),
        minimumTemperatureCelsius: _firstDailyValue(
          daily?['temperature_2m_min'],
        ),
        updatedAt: DateTime.tryParse(current['time'] as String? ?? ''),
      );
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw const WeatherException();
    } finally {
      if (client == null) requestClient.close();
    }
  }

  double? _firstDailyValue(Object? values) {
    if (values is! List || values.isEmpty || values.first is! num) return null;
    return (values.first as num).toDouble();
  }

  Future<(double, double)> _coordinatesFor(FarmLocation location) async {
    if (location.latitude != null && location.longitude != null) {
      return (location.latitude!, location.longitude!);
    }

    final query = {
      location.city,
      location.district,
      location.state,
      location.country,
    }.join(', ');
    final matches = await Geocoding().locationFromAddress(query);
    if (matches.isEmpty) throw const WeatherException();
    return (matches.first.latitude, matches.first.longitude);
  }
}

class WeatherException implements Exception {
  const WeatherException();
}
