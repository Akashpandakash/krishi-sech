import type { NextFunction, Request, Response } from 'express';

import { AppError } from '../../common/app-error.js';
import type { AuthService } from '../services/auth-service.js';

export interface AuthenticatedRequest extends Request {
  auth?: { userId: string; phone: string };
}

export function requireAuth(authService: AuthService) {
  return (
    request: AuthenticatedRequest,
    _response: Response,
    next: NextFunction,
  ): void => {
    const authorization = request.header('authorization');
    if (!authorization?.startsWith('Bearer ')) {
      next(new AppError(401, 'AUTH_REQUIRED', 'Authentication is required'));
      return;
    }
    try {
      const payload = authService.jwtService.verifyAccessToken(
        authorization.slice(7),
      );
      request.auth = { userId: payload.sub, phone: payload.phone };
      next();
    } catch (error) {
      next(error);
    }
  };
}
