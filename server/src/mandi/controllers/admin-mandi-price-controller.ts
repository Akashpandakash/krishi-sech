import type { Response } from 'express';

import {
  clientIp,
  type AdminRequest,
} from '../../admin/middleware/admin-auth-middleware.js';
import type { AuditLogRepository } from '../../admin/repositories/audit-log-repository.js';
import { sendSuccess } from '../../common/response.js';
import type { MandiPriceService } from '../services/mandi-price-service.js';
import {
  adminMandiIdSchema,
  adminMandiListQuerySchema,
  adminMandiPriceBodySchema,
} from '../validation/mandi-price-validation.js';

function describe(quote: {
  commodity: string;
  market: string;
  modalPrice: number;
}): string {
  return `${quote.commodity} at ${quote.market} — ₹${quote.modalPrice}/quintal`;
}

export class AdminMandiPriceController {
  constructor(
    private readonly service: MandiPriceService,
    private readonly audit: AuditLogRepository,
  ) {}

  list = async (request: AdminRequest, response: Response) => {
    const query = adminMandiListQuerySchema.parse(request.query);
    const prices = await this.service.listRecords(query);
    return sendSuccess(response, 200, 'Mandi prices retrieved successfully', {
      prices,
      count: prices.length,
    });
  };

  filters = async (_request: AdminRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Mandi filters retrieved successfully',
      await this.service.filterOptions(),
    );

  create = async (request: AdminRequest, response: Response) => {
    const body = adminMandiPriceBodySchema.parse(request.body);
    const record = await this.service.saveManual(body);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'mandi.price.created',
      targetType: 'mandi_price',
      targetId: record.id,
      summary: `Added ${describe(record)}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 201, 'Mandi price saved successfully', record);
  };

  update = async (request: AdminRequest, response: Response) => {
    const { id } = adminMandiIdSchema.parse(request.params);
    const body = adminMandiPriceBodySchema.parse(request.body);
    const record = await this.service.updateManual(id, body);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'mandi.price.updated',
      targetType: 'mandi_price',
      targetId: record.id,
      summary: `Updated ${describe(record)}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(
      response,
      200,
      'Mandi price updated successfully',
      record,
    );
  };

  delete = async (request: AdminRequest, response: Response) => {
    const { id } = adminMandiIdSchema.parse(request.params);
    await this.service.deleteRecord(id);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'mandi.price.deleted',
      targetType: 'mandi_price',
      targetId: id,
      summary: `Removed mandi price ${id}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Mandi price deleted successfully');
  };
}
