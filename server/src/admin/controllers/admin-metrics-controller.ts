import type { Response } from 'express';

import { sendSuccess } from '../../common/response.js';
import type { AdminRequest } from '../middleware/admin-auth-middleware.js';
import type { AdminAnalyticsRepository } from '../repositories/admin-analytics-repository.js';
import type { AuditLogRepository } from '../repositories/audit-log-repository.js';
import {
  activityQuerySchema,
  auditQuerySchema,
  growthQuerySchema,
} from '../validation/admin-validation.js';

export class AdminMetricsController {
  constructor(
    private readonly analytics: AdminAnalyticsRepository,
    private readonly audit: AuditLogRepository,
  ) {}

  overview = async (_request: AdminRequest, response: Response) =>
    sendSuccess(response, 200, 'Overview metrics retrieved successfully', {
      source: this.analytics.source,
      metrics: await this.analytics.overview(),
    });

  growth = async (request: AdminRequest, response: Response) => {
    const { days } = growthQuerySchema.parse(request.query);
    return sendSuccess(response, 200, 'Growth metrics retrieved successfully', {
      source: this.analytics.source,
      days,
      series: await this.analytics.growth(days),
    });
  };

  distributions = async (_request: AdminRequest, response: Response) =>
    sendSuccess(response, 200, 'Distribution metrics retrieved successfully', {
      source: this.analytics.source,
      distributions: await this.analytics.distributions(),
    });

  activity = async (request: AdminRequest, response: Response) => {
    const { limit } = activityQuerySchema.parse(request.query);
    return sendSuccess(response, 200, 'Recent activity retrieved successfully', {
      source: this.analytics.source,
      activity: await this.analytics.recentActivity(limit),
    });
  };

  filters = async (_request: AdminRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Filter options retrieved successfully',
      await this.analytics.filterOptions(),
    );

  auditLog = async (request: AdminRequest, response: Response) => {
    const { action, limit } = auditQuerySchema.parse(request.query);
    return sendSuccess(
      response,
      200,
      'Audit log retrieved successfully',
      await this.audit.list(limit, action),
    );
  };
}
