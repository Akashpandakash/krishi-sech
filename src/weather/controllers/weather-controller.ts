import type { Request, Response } from 'express';
import { sendSuccess } from '../../common/response.js';
import type { WeatherService } from '../services/weather-service.js';
import { currentWeatherQuerySchema } from '../validation/weather-validation.js';

export class WeatherController {
  constructor(private readonly service: WeatherService) {}
  current = async (request: Request, response: Response) => {
    const query = currentWeatherQuerySchema.parse(request.query);
    return sendSuccess(response, 200, 'Current weather retrieved successfully', await this.service.current(query.lat, query.lng));
  };
}
