import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { AiContextService } from '../services/ai-context-service.js';

export class AiContextController {
  constructor(private readonly service: AiContextService) {}

  get = async (request: AuthenticatedRequest, response: Response) => {
    const context = await this.service.getContext(request.auth!.userId);
    return sendSuccess(
      response,
      200,
      'AI context retrieved successfully',
      context,
    );
  };
}
