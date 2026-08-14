import { Router } from 'express';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { CalendarTaskController } from '../controllers/calendar-task-controller.js';
import type { CalendarTaskService } from '../services/calendar-task-service.js';

export function createCalendarTaskRouter(
  authService: AuthService,
  service: CalendarTaskService,
): Router {
  const router = Router();
  const controller = new CalendarTaskController(service);
  router.use(requireAuth(authService));
  router.post('/tasks', controller.create);
  router.get('/tasks', controller.list);
  router.put('/tasks/:id', controller.update);
  router.delete('/tasks/:id', controller.delete);
  return router;
}
