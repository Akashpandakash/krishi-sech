import { Router } from 'express';
import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { ProfileController } from '../controllers/profile-controller.js';
import type { ProfileService } from '../services/profile-service.js';

export function createProfileRouter(
  auth: AuthService,
  service: ProfileService,
) {
  const router = Router();
  const controller = new ProfileController(service);
  router.use(requireAuth(auth));
  router.get('/', controller.getUser);
  router.put('/', controller.updateUser);
  router.get('/farm', controller.getFarm);
  router.put('/farm', controller.updateFarm);
  return router;
}
