import { Router } from 'express';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { CropController } from '../controllers/crop-controller.js';
import type { CropService } from '../services/crop-service.js';

export function createCropRouter(
  authService: AuthService,
  cropService: CropService,
): Router {
  const router = Router();
  const controller = new CropController(cropService);

  router.use(requireAuth(authService));
  router.post('/', controller.create);
  router.get('/', controller.list);
  router.get('/:id', controller.get);
  router.put('/:id', controller.update);
  router.delete('/:id', controller.delete);
  return router;
}
