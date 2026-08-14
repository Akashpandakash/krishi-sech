import { AppError } from '../../common/app-error.js';
import type { WeatherProvider, WeatherReading } from './weather-provider.js';

interface OpenMeteoResponse {
  current?: Record<string, unknown>;
  daily?: Record<string, unknown>;
}

export class OpenMeteoWeatherProvider implements WeatherProvider {
  constructor(
    private readonly fetcher: typeof fetch = fetch,
    private readonly baseUrl = 'https://api.open-meteo.com/v1/forecast',
    private readonly requestTimeoutMs = 10_000,
  ) {}

  async current(coarseLatitude: number, coarseLongitude: number): Promise<WeatherReading> {
    const uri = new URL(this.baseUrl);
    uri.searchParams.set('latitude', coarseLatitude.toString());
    uri.searchParams.set('longitude', coarseLongitude.toString());
    uri.searchParams.set('current', 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m');
    uri.searchParams.set('daily', 'temperature_2m_max,temperature_2m_min,precipitation_probability_max');
    uri.searchParams.set('forecast_days', '1');
    uri.searchParams.set('timezone', 'auto');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.requestTimeoutMs);
    try {
      const response = await this.fetcher(uri, { signal: controller.signal });
      if (!response.ok) throw new AppError(502, 'WEATHER_UPSTREAM_ERROR', `Weather provider returned HTTP ${response.status}`);
      return this.parse(await response.json() as OpenMeteoResponse);
    } catch (error) {
      if (error instanceof AppError) throw error;
      if (error instanceof Error && error.name === 'AbortError') {
        throw new AppError(504, 'WEATHER_TIMEOUT', 'Weather provider timed out');
      }
      throw new AppError(502, 'WEATHER_UPSTREAM_ERROR', 'Weather provider could not be reached');
    } finally { clearTimeout(timeout); }
  }

  private parse(body: OpenMeteoResponse): WeatherReading {
    const current = body.current;
    const daily = body.daily;
    const number = (value: unknown) => typeof value === 'number' && Number.isFinite(value) ? value : null;
    const firstNumber = (value: unknown) => Array.isArray(value) ? number(value[0]) : null;
    const temperature = number(current?.temperature_2m);
    const humidity = number(current?.relative_humidity_2m);
    const wind = number(current?.wind_speed_10m);
    const weatherCode = number(current?.weather_code);
    if (temperature == null || humidity == null || wind == null || weatherCode == null) {
      throw new AppError(502, 'WEATHER_INVALID_RESPONSE', 'Weather provider returned incomplete data');
    }
    return {
      temperatureCelsius: temperature,
      weatherCode: Math.round(weatherCode),
      humidityPercent: Math.round(humidity),
      windSpeedKmh: wind,
      feelsLikeCelsius: number(current?.apparent_temperature),
      rainProbabilityPercent: firstNumber(daily?.precipitation_probability_max),
      minimumTemperatureCelsius: firstNumber(daily?.temperature_2m_min),
      maximumTemperatureCelsius: firstNumber(daily?.temperature_2m_max),
      updatedAt: new Date(typeof current?.time === 'string' ? current.time : Date.now()),
    };
  }
}
