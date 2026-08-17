import type { Response } from 'express';

import { sendSuccess } from '../../common/response.js';
import type { BroadcastService } from '../../broadcasts/services/broadcast-service.js';
import type { AdminRequest } from '../middleware/admin-auth-middleware.js';
import { clientIp } from '../middleware/admin-auth-middleware.js';
import type { AuditLogRepository } from '../repositories/audit-log-repository.js';
import {
  audienceSchema,
  broadcastCreateSchema,
  broadcastListQuerySchema,
  idParamSchema,
} from '../validation/admin-validation.js';

export class AdminBroadcastController {
  constructor(
    private readonly service: BroadcastService,
    private readonly audit: AuditLogRepository,
  ) {}

  list = async (request: AdminRequest, response: Response) => {
    const { status, limit } = broadcastListQuerySchema.parse(request.query);
    return sendSuccess(response, 200, 'Broadcasts retrieved successfully', {
      transport: this.service.pushTransport,
      broadcasts: await this.service.list(limit, status),
    });
  };

  get = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    return sendSuccess(
      response,
      200,
      'Broadcast retrieved successfully',
      await this.service.get(id),
    );
  };

  /** Shows how many devices a filter reaches before anything is sent. */
  estimate = async (request: AdminRequest, response: Response) => {
    const audience = audienceSchema.parse(request.body ?? {});
    const tokens = await this.service.estimateAudience(audience);
    return sendSuccess(response, 200, 'Audience estimated successfully', {
      deviceCount: tokens.length,
      transport: this.service.pushTransport,
    });
  };

  create = async (request: AdminRequest, response: Response) => {
    const body = broadcastCreateSchema.parse(request.body);
    const broadcast = await this.service.create(
      {
        title: body.title,
        body: body.body,
        category: body.category,
        deepLink: body.deepLink,
        audience: body.audience,
        scheduledAt: body.scheduledAt,
        createdByAdminId: request.admin!.id,
        createdByAdminEmail: request.admin!.email,
      },
      body.sendNow,
    );
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: body.sendNow ? 'broadcast.sent' : 'broadcast.created',
      targetType: 'broadcast',
      targetId: broadcast.id,
      summary: `${body.sendNow ? 'Sent' : 'Saved'} "${broadcast.title}" to ${describeAudience(broadcast.audience)}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(
      response,
      201,
      body.sendNow ? 'Broadcast sent successfully' : 'Broadcast saved successfully',
      broadcast,
    );
  };

  send = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const broadcast = await this.service.send(id);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'broadcast.sent',
      targetType: 'broadcast',
      targetId: id,
      summary: `Sent "${broadcast.title}" to ${broadcast.audienceCount} devices`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Broadcast sent successfully', broadcast);
  };

  cancel = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const broadcast = await this.service.cancel(id);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'broadcast.cancelled',
      targetType: 'broadcast',
      targetId: id,
      summary: `Cancelled "${broadcast.title}"`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(
      response,
      200,
      'Broadcast cancelled successfully',
      broadcast,
    );
  };

  delete = async (request: AdminRequest, response: Response) => {
    const { id } = idParamSchema.parse(request.params);
    const broadcast = await this.service.get(id);
    await this.service.delete(id);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'broadcast.deleted',
      targetType: 'broadcast',
      targetId: id,
      summary: `Deleted "${broadcast.title}"`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Broadcast deleted successfully');
  };
}

function describeAudience(audience: {
  language: string | null;
  state: string | null;
  farmerType: string | null;
}): string {
  const parts = [audience.language, audience.state, audience.farmerType].filter(
    Boolean,
  );
  return parts.length > 0 ? parts.join(' / ') : 'all farmers';
}
