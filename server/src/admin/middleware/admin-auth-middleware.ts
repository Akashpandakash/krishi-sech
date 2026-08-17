import type { NextFunction, Request, Response } from 'express';

import { AppError } from '../../common/app-error.js';
import type { AdminRole, AdminUser } from '../repositories/admin-repository.js';
import type { AdminAuthService } from '../services/admin-auth-service.js';

export interface AdminRequest extends Request {
  admin?: AdminUser;
}

export function requireAdmin(service: AdminAuthService) {
  return async (
    request: AdminRequest,
    _response: Response,
    next: NextFunction,
  ): Promise<void> => {
    const authorization = request.header('authorization');
    if (!authorization?.startsWith('Bearer ')) {
      next(
        new AppError(401, 'ADMIN_AUTH_REQUIRED', 'Admin authentication is required'),
      );
      return;
    }
    try {
      request.admin = await service.authenticate(authorization.slice(7));
      next();
    } catch (error) {
      next(error);
    }
  };
}

/** Analysts get read-only access, so mutations declare the roles they need. */
export function requireRole(...roles: AdminRole[]) {
  return (
    request: AdminRequest,
    _response: Response,
    next: NextFunction,
  ): void => {
    if (!request.admin) {
      next(
        new AppError(401, 'ADMIN_AUTH_REQUIRED', 'Admin authentication is required'),
      );
      return;
    }
    if (!roles.includes(request.admin.role)) {
      next(
        new AppError(
          403,
          'ADMIN_FORBIDDEN',
          'Your role does not allow this action',
        ),
      );
      return;
    }
    next();
  };
}

export function clientIp(request: Request): string | null {
  const forwarded = request.header('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0]!.trim();
  return request.ip ?? null;
}
