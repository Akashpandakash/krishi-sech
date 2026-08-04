import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/data/datasources/local_weather_data_source.dart';
import 'package:krishi_sech/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const location = FarmLocation(
    city: 'Kolkata',
    district: 'Kolkata',
    state: 'West Bengal',
    latitude: 22.5726,
    longitude: 88.3639,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'weather requests only the backend with location and language',
    () async {
      late Uri requestedUri;
      final service = WeatherService(
        baseUrl: 'https://backend.example',
        languageProvider: () => 'bn',
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'temperature': 29.5,
                'weatherCode': 3,
                'humidity': 78,
                'windSpeed': 12.4,
                'updatedAt': '2026-08-03T10:00:00.000Z',
              },
            }),
            200,
          );
        }),
      );

      final weather = await service.fetchCurrentWeather(location);

      expect(requestedUri.path, '/api/weather/current');
      expect(requestedUri.queryParameters['lat'], '22.5726');
      expect(requestedUri.queryParameters['lng'], '88.3639');
      expect(requestedUri.queryParameters['language'], 'bn');
      expect(weather.temperatureCelsius, 29.5);
    },
  );

  test('repository returns matching cached weather when offline', () async {
    final preferences = await SharedPreferences.getInstance();
    final cache = LocalWeatherDataSource(preferences);
    final onlineRepository = WeatherRepositoryImpl(
      WeatherService(
        baseUrl: 'https://backend.example',
        languageProvider: () => 'en',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'temperatureCelsius': 31,
                'weatherCode': 1,
                'humidityPercent': 65,
                'windSpeedKmh': 8,
              },
            }),
            200,
          ),
        ),
      ),
      cache,
    );
    await onlineRepository.fetchCurrentWeather(location);

    final offlineRepository = WeatherRepositoryImpl(
      WeatherService(
        baseUrl: 'https://backend.example',
        languageProvider: () => 'en',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      cache,
    );
    final cached = await offlineRepository.fetchCurrentWeather(location);

    expect(cached.temperatureCelsius, 31);
    expect(offlineRepository.isUsingCachedData, isTrue);
  });
}
