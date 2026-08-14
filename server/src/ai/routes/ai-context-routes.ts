import { Router } from 'express';
import multer from 'multer';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { AiContextController } from '../controllers/ai-context-controller.js';
import { AiChatController } from '../controllers/ai-chat-controller.js';
import type { AiChatService } from '../services/ai-chat-service.js';
import { AiDiseaseScanController } from '../controllers/ai-disease-scan-controller.js';
import type { AiDiseaseScanService } from '../services/ai-disease-scan-service.js';
import type { AiContextService } from '../services/ai-context-service.js';
import { AppError } from '../../common/app-error.js';

export function createAiContextRouter(
  authService: AuthService,
  contextService: AiContextService,
  chatService?: AiChatService,
  diseaseScanService?: AiDiseaseScanService,
): Router {
  const router = Router();
  const controller = new AiContextController(contextService);
  router.use(requireAuth(authService));
  router.get('/context', controller.get);
  if (chatService) {
    router.post('/chat', new AiChatController(chatService).chat);
  }
  if (diseaseScanService) {
    const upload = multer({
      storage: multer.memoryStorage(),
      limits: { fileSize: 2 * 1024 * 1024, files: 1 },
      fileFilter: (_request, file, callback) => {
        if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
          callback(new AppError(400, 'INVALID_IMAGE_TYPE', 'Use a JPEG, PNG, or WebP crop image'));
          return;
        }
        callback(null, true);
      },
    });
    router.post(
      '/disease-scan',
      upload.single('image'),
      new AiDiseaseScanController(diseaseScanService).scan,
    );
  }
  return router;
}
