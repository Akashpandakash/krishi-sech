import type { Response } from 'express';
import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { FertilizerRecommendationService } from '../services/fertilizer-recommendation-service.js';
import { fertilizerRecommendationQuerySchema } from '../validation/fertilizer-recommendation-validation.js';

export class FertilizerRecommendationController {
  constructor(private readonly service: FertilizerRecommendationService) {}

  get = async (request: AuthenticatedRequest, response: Response) => {
    const query = fertilizerRecommendationQuerySchema.parse(request.query);
    const recommendation = await this.service.getRecommendation(
      request.auth!.userId,
      query.cropId,
      query.language,
    );
    return sendSuccess(response, 200, 'Fertilizer recommendation generated successfully', recommendation);
  };
}
