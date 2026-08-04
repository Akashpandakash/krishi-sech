export interface WeatherReading {
  temperatureCelsius: number;
  weatherCode: number;
  humidityPercent: number;
  windSpeedKmh: number;
  feelsLikeCelsius: number | null;
  rainProbabilityPercent: number | null;
  minimumTemperatureCelsius: number | null;
  maximumTemperatureCelsius: number | null;
  updatedAt: Date;
}

export interface WeatherProvider {
  current(coarseLatitude: number, coarseLongitude: number): Promise<WeatherReading>;
}
