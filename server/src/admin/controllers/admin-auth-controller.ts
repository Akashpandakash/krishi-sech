import type { Response } from 'express';

import { sendSuccess } from '../../common/response.js';
import type { AuditLogRepository } from '../repositories/audit-log-repository.js';
import type { AdminRequest } from '../middleware/admin-auth-middleware.js';
import { clientIp } from '../middleware/admin-auth-middleware.js';
import type { AdminAuthService } from '../services/admin-auth-service.js';
import { toPublicAdmin } from '../repositories/admin-repository.js';
import {
  adminCreateSchema,
  adminLoginSchema,
  adminRefreshSchema,
  adminUpdateSchema,
  changePasswordSchema,
  idParamSchema,
  resetPasswordSchema,
} from '../validation/admin-validation.js';

export class AdminAuthController {
  constructor(
    private readonly service: AdminAuthService,
    private readonly audit: AuditLogRepository,
  ) {}

  login = async (request: AdminRequest, response: Response) => {
    const body = adminLoginSchema.parse(request.body);
    const session = await this.service.login(body.email, body.password);
    await this.audit.record({
      adminId: session.admin.id,
      adminEmail: session.admin.email,
      action: 'admin.login',
      targetType: null,
      targetId: null,
      summary: 'Signed in to the admin panel',
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Signed in successfully', session);
  };

  refresh = async (request: AdminRequest, response: Response) => {
    const body = adminRefreshSchema.parse(request.body);
    return sendSuccess(
      response,
      200,
      'Session refreshed successfully',
      await this.service.refresh(body.refreshToken),
    );
  };

  logout = async (request: AdminRequest, response: Response) => {
    const body = adminRefreshSchema.parse(request.body);
    await this.service.logout(body.refreshToken);
    return sendSuccess(response, 200, 'Signed out successfully');
  };

  me = async (request: AdminRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Admin retrieved successfully',
      toPublicAdmin(request.admin!),
    );

  changePassword = async (request: AdminRequest, response: Response) => {
    const body = changePasswordSchema.parse(request.body);
    await this.service.changePassword(
      request.admin!.id,
      body.currentPassword,
      body.newPassword,
    );
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'admin.password_changed',
      targetType: 'admin',
      targetId: request.admin!.id,
      summary: 'Changed their own password',
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Password updated successfully');
  };

  listAdmins = async (_request: AdminRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Admins retrieved successfully',
      await this.service.listAdmins(),
    );

  createAdmin = async (request: AdminRequest, response: Response) => {
    const body = adminCreateSchema.parse(request.body);
    const created = await this.service.createAdmin(body);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'admin.created',
      targetType: 'admin',
      targetId: created.id,
      summary: `Created ${created.role} account ${created.email}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 201, 'Admin created successfully', created);
  };

  updateAdmin = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const changes = adminUpdateSchema.parse(request.body);
    const updated = await this.service.updateAdmin(id, changes);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'admin.updated',
      targetType: 'admin',
      targetId: id,
      summary: `Updated ${updated.email}: ${Object.keys(changes).join(', ')}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Admin updated successfully', updated);
  };

  resetPassword = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const body = resetPasswordSchema.parse(request.body);
    await this.service.resetPassword(id, body.newPassword);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'admin.password_reset',
      targetType: 'admin',
      targetId: id,
      summary: 'Reset another admin password',
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Password reset successfully');
  };
}
