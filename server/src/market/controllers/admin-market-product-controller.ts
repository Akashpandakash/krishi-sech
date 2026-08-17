import type { Response } from 'express';

import { sendSuccess } from '../../common/response.js';
import type { AdminRequest } from '../../admin/middleware/admin-auth-middleware.js';
import { clientIp } from '../../admin/middleware/admin-auth-middleware.js';
import type { AuditLogRepository } from '../../admin/repositories/audit-log-repository.js';
import type { MarketProductService } from '../services/market-product-service.js';
import {
  marketProductBodySchema,
  marketProductIdSchema,
} from '../validation/market-product-validation.js';

/**
 * Catalogue management. Without this the market has no legitimate way to be
 * populated, which is what pushed the app to ship invented products before.
 */
export class AdminMarketProductController {
  constructor(
    private readonly service: MarketProductService,
    private readonly audit: AuditLogRepository,
  ) {}

  list = async (_request: AdminRequest, response: Response) =>
    sendSuccess(response, 200, 'Products retrieved successfully', {
      products: await this.service.listAll(),
    });

  create = async (request: AdminRequest, response: Response) => {
    const body = marketProductBodySchema.parse(request.body);
    const product = await this.service.create(body);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'product.created',
      targetType: 'product',
      targetId: product.id,
      summary: `Added "${product.name.en}" from ${product.vendor}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 201, 'Product created successfully', product);
  };

  update = async (request: AdminRequest, response: Response) => {
    const { id } = marketProductIdSchema.parse(request.params);
    const body = marketProductBodySchema.parse(request.body);
    const product = await this.service.update(id, body);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'product.updated',
      targetType: 'product',
      targetId: product.id,
      summary: `Updated "${product.name.en}"`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Product updated successfully', product);
  };

  delete = async (request: AdminRequest, response: Response) => {
    const { id } = marketProductIdSchema.parse(request.params);
    await this.service.delete(id);
    await this.audit.record({
      adminId: request.admin!.id,
      adminEmail: request.admin!.email,
      action: 'product.deleted',
      targetType: 'product',
      targetId: id,
      summary: `Removed product ${id}`,
      ipAddress: clientIp(request),
    });
    return sendSuccess(response, 200, 'Product deleted successfully');
  };
}
