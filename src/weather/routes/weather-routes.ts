import { Router } from 'express';
import { WeatherController } from '../controllers/weather-controller.js';
import type { WeatherService } from '../services/weather-service.js';

export function createWeatherRouter(service: WeatherService) {
  const router = Router();
  router.get('/current', new WeatherController(service).current);
  return router;
}
