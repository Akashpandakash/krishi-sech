import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { WeatherProvider } from '../providers/weather-provider.js';
import { OpenMeteoWeatherProvider } from '../providers/open-meteo-weather-provider.js';
import { WeatherService } from './weather-service.js';

describe('weather service', () => {
  it('rounds GPS to city-level precision before calling the provider', async () => {
    let received: [number, number] | null = null;
    const provider: WeatherProvider = {
      current: async (latitude, longitude) => {
        received = [latitude, longitude];
        return {
          temperatureCelsius: 30, weatherCode: 2, humidityPercent: 70,
          windSpeedKmh: 8, feelsLikeCelsius: 32, rainProbabilityPercent: 40,
          minimumTemperatureCelsius: 25, maximumTemperatureCelsius: 33,
          updatedAt: new Date('2026-08-04T10:00:00Z'),
        };
      },
    };
    await new WeatherService(provider).current(22.572645, 88.363892);
    assert.deepEqual(received, [22.57, 88.36]);
  });

  it('maps the upstream response to the Flutter weather contract', async () => {
    const provider = new OpenMeteoWeatherProvider(async () => new Response(JSON.stringify({
      current: {
        temperature_2m: 29.4, relative_humidity_2m: 81,
        apparent_temperature: 34.1, weather_code: 3,
        wind_speed_10m: 7.2, time: '2026-08-04T10:00',
      },
      daily: {
        temperature_2m_max: [32], temperature_2m_min: [26],
        precipitation_probability_max: [65],
      },
    }), { status: 200 }));
    const result = await provider.current(22.57, 88.36);
    assert.equal(result.temperatureCelsius, 29.4);
    assert.equal(result.humidityPercent, 81);
    assert.equal(result.rainProbabilityPercent, 65);
  });
});
