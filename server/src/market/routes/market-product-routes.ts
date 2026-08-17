import { Router } from 'express';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { MarketProductController } from '../controllers/market-product-controller.js';
import type { MarketProductService } from '../services/market-product-service.js';

export function createMarketProductRouter(
  authService: AuthService,
  service: MarketProductService,
): Router {
  const router = Router();
  const controller = new MarketProductController(service);

  router.use(requireAuth(authService));
  router.get('/products', controller.list);
  router.get('/products/:id', controller.get);
  return router;
}
