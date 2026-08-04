import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';

typedef WeatherLanguageProvider = String Function();

/// Talks only to the Krishi Sech backend. Provider credentials and upstream
/// weather API details remain on the server.
class WeatherService {
  const WeatherService({
    required this.baseUrl,
    required this.languageProvider,
    this.client,
  });

  final String baseUrl;
  final WeatherLanguageProvider languageProvider;
  final http.Client? client;

  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location) async {
    final coordinates = await _coordinatesFor(location);
    final uri = Uri.parse(baseUrl)
        .resolve('/api/weather/current')
        .replace(
          queryParameters: {
            'lat': coordinates.$1.toString(),
            'lng': coordinates.$2.toString(),
            'language': languageProvider(),
          },
        );
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(AppEnvironment.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = _backendError(response.body);
        if (kDebugMode && AppEnvironment.loggingEnabled) {
          debugPrint(
            'Weather API status=${response.statusCode} code=${error.$1 ?? 'unknown'} reason=${error.$2 ?? 'unknown'}',
          );
        }
        throw WeatherException(
          WeatherFailureType.server,
          error.$2 ?? 'Weather backend returned HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherException(WeatherFailureType.invalidResponse);
      }
      final payload = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      if (decoded.containsKey('success') && decoded['success'] != true) {
        final error = decoded['error'];
        throw WeatherException(
          WeatherFailureType.server,
          error is Map<String, dynamic>
              ? error['message']?.toString()
              : 'Weather backend rejected the request',
          response.statusCode,
        );
      }
      return _weatherFromJson(payload);
    } on WeatherException {
      rethrow;
    } on SocketException {
      throw const WeatherException(WeatherFailureType.offline);
    } on TimeoutException {
      throw const WeatherException(WeatherFailureType.offline);
    } on http.ClientException {
      throw const WeatherException(WeatherFailureType.offline);
    } on FormatException {
      throw const WeatherException(WeatherFailureType.invalidResponse);
    } catch (_) {
      throw const WeatherException(WeatherFailureType.invalidResponse);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  (String?, String?) _backendError(String body) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      return error is Map<String, dynamic>
          ? (error['code']?.toString(), error['message']?.toString())
          : (null, null);
    } catch (_) {
      return (null, null);
    }
  }

  CurrentWeather _weatherFromJson(Map<String, dynamic> json) {
    final temperature = _number(json, const [
      'temperatureCelsius',
      'temperature',
      'temp',
    ]);
    final humidity = _number(json, const ['humidityPercent', 'humidity']);
    final wind = _number(json, const [
      'windSpeedKmh',
      'windSpeed',
      'wind_speed',
    ]);
    if (temperature == null || humidity == null || wind == null) {
      throw const WeatherException(WeatherFailureType.invalidResponse);
    }
    return CurrentWeather(
      temperatureCelsius: temperature,
      weatherCode:
          _number(json, const ['weatherCode', 'weather_code'])?.round() ??
          _codeForCondition(
            (json['condition'] ?? json['weatherCondition'])?.toString(),
          ),
      humidityPercent: humidity.round(),
      windSpeedKmh: wind,
      feelsLikeCelsius: _number(json, const [
        'feelsLikeCelsius',
        'feelsLike',
        'apparentTemperature',
      ]),
      rainProbabilityPercent: _number(json, const [
        'rainProbabilityPercent',
        'rainProbability',
        'precipitationProbability',
      ])?.round(),
      minimumTemperatureCelsius: _number(json, const [
        'minimumTemperatureCelsius',
        'minTemperature',
        'minTemp',
      ]),
      maximumTemperatureCelsius: _number(json, const [
        'maximumTemperatureCelsius',
        'maxTemperature',
        'maxTemp',
      ]),
      updatedAt: DateTime.tryParse(
        (json['updatedAt'] ?? json['lastUpdated'] ?? json['createdAt'])
                ?.toString() ??
            '',
      ),
    );
  }

  double? _number(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  int _codeForCondition(String? condition) {
    final value = condition?.toLowerCase() ?? '';
    if (value.contains('thunder')) return 95;
    if (value.contains('snow')) return 71;
    if (value.contains('rain') || value.contains('drizzle')) return 61;
    if (value.contains('fog') || value.contains('mist')) return 45;
    if (value.contains('cloud') || value.contains('overcast')) return 3;
    if (value.contains('partly')) return 2;
    return 0;
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
    try {
      final matches = await Geocoding().locationFromAddress(query);
      if (matches.isEmpty) {
        throw const WeatherException(WeatherFailureType.location);
      }
      return (matches.first.latitude, matches.first.longitude);
    } catch (_) {
      throw const WeatherException(WeatherFailureType.location);
    }
  }
}

enum WeatherFailureType { offline, server, invalidResponse, location }

class WeatherException implements Exception {
  const WeatherException(this.type, [this.reason, this.statusCode]);

  final WeatherFailureType type;
  final String? reason;
  final int? statusCode;
}
