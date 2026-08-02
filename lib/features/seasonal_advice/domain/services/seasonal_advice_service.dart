import 'package:krishi_sech/features/seasonal_advice/domain/entities/seasonal_advice.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';

class SeasonalAdviceService {
  const SeasonalAdviceService();

  SeasonalAdvice generate(CurrentWeather weather, {DateTime? now}) {
    final updatedAt = now ?? DateTime.now();
    if ((weather.rainProbabilityPercent ?? 0) >= 60) {
      return SeasonalAdvice(
        type: SeasonalAdviceType.rain,
        warningLevel: AdviceWarningLevel.high,
        updatedAt: updatedAt,
      );
    }
    if (weather.humidityPercent >= 85) {
      return SeasonalAdvice(
        type: SeasonalAdviceType.humidity,
        warningLevel: AdviceWarningLevel.high,
        updatedAt: updatedAt,
      );
    }
    if (weather.temperatureCelsius >= 35) {
      return SeasonalAdvice(
        type: SeasonalAdviceType.heat,
        warningLevel: AdviceWarningLevel.high,
        updatedAt: updatedAt,
      );
    }
    if (weather.windSpeedKmh >= 25) {
      return SeasonalAdvice(
        type: SeasonalAdviceType.wind,
        warningLevel: AdviceWarningLevel.medium,
        updatedAt: updatedAt,
      );
    }
    return SeasonalAdvice(
      type: SeasonalAdviceType.normal,
      warningLevel: AdviceWarningLevel.low,
      updatedAt: updatedAt,
    );
  }
}
