import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/data/datasources/local_weather_data_source.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/features/weather/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherSyncAwareRepository {
  WeatherRepositoryImpl(this._service, this._cache);

  final WeatherService _service;
  final LocalWeatherDataSource _cache;

  @override
  bool isUsingCachedData = false;

  @override
  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location) async {
    try {
      final weather = await _service.fetchCurrentWeather(location);
      await _cache.save(location, weather);
      isUsingCachedData = false;
      return weather;
    } on WeatherException {
      final cached = await _cache.read(location);
      if (cached == null) rethrow;
      isUsingCachedData = true;
      return cached;
    }
  }
}
