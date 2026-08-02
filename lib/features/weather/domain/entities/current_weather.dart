class CurrentWeather {
  const CurrentWeather({
    required this.temperatureCelsius,
    required this.weatherCode,
    required this.humidityPercent,
    required this.windSpeedKmh,
    this.feelsLikeCelsius,
    this.rainProbabilityPercent,
    this.minimumTemperatureCelsius,
    this.maximumTemperatureCelsius,
    this.updatedAt,
  });

  final double temperatureCelsius;
  final int weatherCode;
  final int humidityPercent;
  final double windSpeedKmh;
  final double? feelsLikeCelsius;
  final int? rainProbabilityPercent;
  final double? minimumTemperatureCelsius;
  final double? maximumTemperatureCelsius;
  final DateTime? updatedAt;
}
