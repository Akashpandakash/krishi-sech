import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { AiChatService } from '../services/ai-chat-service.js';
import { aiChatSchema } from '../validation/ai-chat-validation.js';

export class AiChatController {
  constructor(private readonly service: AiChatService) {}

  chat = async (request: AuthenticatedRequest, response: Response) => {
    const result = await this.service.chat(
      request.auth!.userId,
      aiChatSchema.parse(request.body),
    );
    return sendSuccess(response, 200, 'AI response generated successfully', result);
  };
}
