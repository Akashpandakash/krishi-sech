import type { Response } from 'express';
import { sendSuccess } from '../../common/response.js';
import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import type { ProfileService } from '../services/profile-service.js';
import {
  updateFarmProfileSchema,
  updateUserProfileSchema,
} from '../validation/profile-validation.js';

export class ProfileController {
  constructor(private readonly service: ProfileService) {}
  getUser = async (request: AuthenticatedRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Profile retrieved successfully',
      await this.service.getUser(request.auth!.userId),
    );
  updateUser = async (request: AuthenticatedRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Profile updated successfully',
      await this.service.updateUser(
        request.auth!.userId,
        updateUserProfileSchema.parse(request.body),
      ),
    );
  getFarm = async (request: AuthenticatedRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Farm profile retrieved successfully',
      await this.service.getFarm(request.auth!.userId),
    );
  updateFarm = async (request: AuthenticatedRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Farm profile updated successfully',
      await this.service.updateFarm(
        request.auth!.userId,
        updateFarmProfileSchema.parse(request.body),
      ),
    );
}
