import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/features/weather/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  const WeatherRepositoryImpl(this._service);

  final WeatherService _service;

  @override
  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location) =>
      _service.fetchCurrentWeather(location);
}
