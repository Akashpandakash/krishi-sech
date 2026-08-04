import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';

abstract interface class WeatherRepository {
  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location);
}

abstract interface class WeatherSyncAwareRepository
    implements WeatherRepository {
  bool get isUsingCachedData;
}
