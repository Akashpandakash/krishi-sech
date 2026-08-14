import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { AppError } from '../../common/app-error.js';
import { sendSuccess } from '../../common/response.js';
import type { AiDiseaseScanService } from '../services/ai-disease-scan-service.js';

export class AiDiseaseScanController {
  constructor(private readonly service: AiDiseaseScanService) {}

  scan = async (request: AuthenticatedRequest, response: Response) => {
    if (!request.file) {
      throw new AppError(400, 'IMAGE_REQUIRED', 'Crop image is required');
    }
    if (
      process.env.LOGGING_ENABLED === 'true' &&
      process.env.NODE_ENV !== 'test'
    ) {
      console.log(
        `[AI Vision] ✓ step=4 backend received image bytes=${request.file.size}`,
      );
      console.log(
        `[AI Vision] ✓ step=5 file validated mime=${request.file.mimetype} bytes=${request.file.size}`,
      );
    }
    const requestedLanguage = request.body.language;
    const language = ['bn', 'en', 'hi'].includes(requestedLanguage)
      ? requestedLanguage as 'bn' | 'en' | 'hi'
      : 'en';
    const result = await this.service.scan(
      request.auth!.userId,
      request.file,
      language,
    );
    return sendSuccess(response, 200, 'Crop image analyzed successfully', result);
  };
}
