import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { CropService } from '../services/crop-service.js';
import { cropBodySchema, cropIdSchema } from '../validation/crop-validation.js';

export class CropController {
  constructor(private readonly service: CropService) {}

  create = async (request: AuthenticatedRequest, response: Response) => {
    const crop = await this.service.create(
      request.auth!.userId,
      cropBodySchema.parse(request.body),
    );
    return sendSuccess(response, 201, 'Crop created successfully', crop);
  };

  list = async (request: AuthenticatedRequest, response: Response) => {
    const crops = await this.service.list(request.auth!.userId);
    return sendSuccess(response, 200, 'Crops retrieved successfully', crops);
  };

  get = async (request: AuthenticatedRequest, response: Response) => {
    const { id } = cropIdSchema.parse(request.params);
    const crop = await this.service.get(request.auth!.userId, id);
    return sendSuccess(response, 200, 'Crop retrieved successfully', crop);
  };

  update = async (request: AuthenticatedRequest, response: Response) => {
    const { id } = cropIdSchema.parse(request.params);
    const crop = await this.service.update(
      request.auth!.userId,
      id,
      cropBodySchema.parse(request.body),
    );
    return sendSuccess(response, 200, 'Crop updated successfully', crop);
  };

  delete = async (request: AuthenticatedRequest, response: Response) => {
    const { id } = cropIdSchema.parse(request.params);
    await this.service.delete(request.auth!.userId, id);
    return sendSuccess(response, 200, 'Crop deleted successfully');
  };
}
