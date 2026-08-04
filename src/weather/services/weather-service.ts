import type { WeatherProvider } from '../providers/weather-provider.js';

export class WeatherService {
  constructor(private readonly provider: WeatherProvider) {}
  current(latitude: number, longitude: number) {
    // City-level precision is sufficient for forecasts and avoids forwarding exact GPS.
    const coarseLatitude = Math.round(latitude * 100) / 100;
    const coarseLongitude = Math.round(longitude * 100) / 100;
    return this.provider.current(coarseLatitude, coarseLongitude);
  }
}
