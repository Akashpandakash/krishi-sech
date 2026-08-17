import { Router } from 'express';
import { z } from 'zod';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { sendSuccess } from '../../common/response.js';
import type { BroadcastService } from '../services/broadcast-service.js';

const inboxQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(30),
});
const idParamSchema = z.object({ id: z.string().min(1).max(100) });

/**
 * The in-app notification inbox. Push delivery is best effort, so the app
 * always reads the authoritative list from here.
 */
export function createNotificationRouter(
  authService: AuthService,
  broadcasts: BroadcastService,
): Router {
  const router = Router();
  router.use(requireAuth(authService));

  router.get('/', async (request: AuthenticatedRequest, response) => {
    const { limit } = inboxQuerySchema.parse(request.query);
    const items = await broadcasts.inbox(request.auth!.userId, limit);
    return sendSuccess(response, 200, 'Notifications retrieved successfully', {
      notifications: items,
      unreadCount: items.filter((item) => !item.read).length,
    });
  });

  router.get('/unread-count', async (request: AuthenticatedRequest, response) =>
    sendSuccess(response, 200, 'Unread count retrieved successfully', {
      unreadCount: await broadcasts.countUnread(request.auth!.userId),
    }),
  );

  router.post('/:id/read', async (request: AuthenticatedRequest, response) => {
    const { id } = idParamSchema.parse(request.params);
    await broadcasts.markRead(id, request.auth!.userId);
    return sendSuccess(response, 200, 'Notification marked as read');
  });

  return router;
}
