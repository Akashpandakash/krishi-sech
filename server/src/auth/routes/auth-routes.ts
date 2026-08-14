import { Router } from 'express';

import { AuthController } from '../controllers/auth-controller.js';
import { requireAuth } from '../middleware/auth-middleware.js';
import type { AuthService } from '../services/auth-service.js';

export function createAuthRouter(authService: AuthService): Router {
  const router = Router();
  const controller = new AuthController(authService);

  router.post('/send-otp', controller.sendOtp);
  router.post('/verify-otp', controller.verifyOtp);
  router.post('/refresh', controller.refresh);
  router.post('/logout', controller.logout);
  router.get('/me', requireAuth(authService), controller.me);

  return router;
}
