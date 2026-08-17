import { Router } from 'express';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { MandiPriceController } from '../controllers/mandi-price-controller.js';
import type { MandiPriceService } from '../services/mandi-price-service.js';

/**
 * Authenticated even though mandi prices are public data: every miss costs a
 * call against the shared data.gov.in quota, and the Market tab is behind
 * login anyway.
 */
export function createMandiPriceRouter(
  authService: AuthService,
  service: MandiPriceService,
): Router {
  const router = Router();
  router.use(requireAuth(authService));
  router.get('/prices', new MandiPriceController(service).list);
  return router;
}
