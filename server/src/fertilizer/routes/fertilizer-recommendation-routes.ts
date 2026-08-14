import { Router } from 'express';
import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { FertilizerRecommendationController } from '../controllers/fertilizer-recommendation-controller.js';
import type { FertilizerRecommendationService } from '../services/fertilizer-recommendation-service.js';

export function createFertilizerRecommendationRouter(authService: AuthService, service: FertilizerRecommendationService) {
  const router = Router();
  router.use(requireAuth(authService));
  router.get('/recommendation', new FertilizerRecommendationController(service).get);
  return router;
}
