import type { Response } from 'express';
import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { IrrigationRecommendationService } from '../services/irrigation-recommendation-service.js';
import { irrigationRecommendationQuerySchema } from '../validation/irrigation-recommendation-validation.js';

export class IrrigationRecommendationController {
  constructor(private readonly service: IrrigationRecommendationService) {}
  get = async (request: AuthenticatedRequest, response: Response) => {
    const query = irrigationRecommendationQuerySchema.parse(request.query);
    const result = await this.service.getRecommendation(
      request.auth!.userId, query.cropId, query.language, query.landType,
    );
    return sendSuccess(response, 200, 'Irrigation recommendation generated successfully', result);
  };
}
