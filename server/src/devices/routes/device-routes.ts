import { Router } from 'express';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { DeviceController } from '../controllers/device-controller.js';
import type { DeviceService } from '../services/device-service.js';

export function createDeviceRouter(
  authService: AuthService,
  deviceService: DeviceService,
): Router {
  const router = Router();
  const controller = new DeviceController(deviceService);

  router.use(requireAuth(authService));
  router.post('/', controller.register);
  router.get('/', controller.list);
  router.delete('/', controller.unregister);
  return router;
}
