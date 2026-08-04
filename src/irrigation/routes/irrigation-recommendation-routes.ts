import { Router } from 'express';
import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { IrrigationRecommendationController } from '../controllers/irrigation-recommendation-controller.js';
import type { IrrigationRecommendationService } from '../services/irrigation-recommendation-service.js';

export function createIrrigationRecommendationRouter(authService: AuthService, service: IrrigationRecommendationService) {
  const router = Router();
  router.use(requireAuth(authService));
  router.get('/recommendation', new IrrigationRecommendationController(service).get);
  return router;
}
