import type { Response } from 'express';

import { AppError } from '../../common/app-error.js';
import { sendSuccess } from '../../common/response.js';
import type { AccountDeletionService } from '../../account/services/account-deletion-service.js';
import type { AdminRequest } from '../middleware/admin-auth-middleware.js';
import { clientIp } from '../middleware/admin-auth-middleware.js';
import type { AdminAnalyticsRepository } from '../repositories/admin-analytics-repository.js';
import type { AuditLogRepository } from '../repositories/audit-log-repository.js';
import {
  deleteUserSchema,
  idParamSchema,
  userListQuerySchema,
  userStatusSchema,
} from '../validation/admin-validation.js';

export class AdminUserController {
  constructor(
    private readonly analytics: AdminAnalyticsRepository,
    private readonly audit: AuditLogRepository,
    private readonly deletion: AccountDeletionService,
  ) {}

  list = async (request: AdminRequest, response: Response) => {
    const query = userListQuerySchema.parse(request.query);
    return sendSuccess(response, 200, 'Users retrieved successfully', {
      source: this.analytics.source,
      ...(await this.analytics.listUsers(query)),
    });
  };

  get = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const user = await this.analytics.getUser(id);
    if (!user) throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    return sendSuccess(response, 200, 'User retrieved successfully', user);
  };

  setStatus = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const { isActive } = userStatusSchema.parse(request.body);
    const user = await this.analytics.getUser(id);
    if (!user) throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    await this.analytics.setUserActive(id, isActive);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: isActive ? 'user.unblocked' : 'user.blocked',
      targetType: 'user',
      targetId: id,
      summary: `${isActive ? 'Unblocked' : 'Blocked'} account ${maskPhone(user.phone)}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(
      response,
      200,
      isActive ? 'User unblocked successfully' : 'User blocked successfully',
      await this.analytics.getUser(id),
    );
  };

  delete = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const { reason } = deleteUserSchema.parse(request.body);
    const user = await this.analytics.getUser(id);
    if (!user) throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    const outcome = await this.deletion.deleteByAdmin(id, reason);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'user.deleted',
      targetType: 'user',
      targetId: id,
      summary: `Deleted account ${maskPhone(user.phone)} — ${reason}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(
      response,
      200,
      'Account deleted permanently',
      outcome.summary,
    );
  };
}

/** Audit entries outlive the account, so only the last digits are kept. */
function maskPhone(phone: string | null): string {
  if (!phone) return 'google account';
  return phone.length <= 4
    ? phone
    : `••••${phone.slice(-4)}`;
}
