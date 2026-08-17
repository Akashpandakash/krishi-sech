import { Router } from 'express';

import { sendSuccess } from '../../common/response.js';

import type { AccountDeletionService } from '../../account/services/account-deletion-service.js';
import type { BroadcastService } from '../../broadcasts/services/broadcast-service.js';
import { AdminAuthController } from '../controllers/admin-auth-controller.js';
import { AdminBroadcastController } from '../controllers/admin-broadcast-controller.js';
import { AdminMetricsController } from '../controllers/admin-metrics-controller.js';
import { AdminUserController } from '../controllers/admin-user-controller.js';
import {
  requireAdmin,
  requireRole,
} from '../middleware/admin-auth-middleware.js';
import type { AdminAnalyticsRepository } from '../repositories/admin-analytics-repository.js';
import type { AuditLogRepository } from '../repositories/audit-log-repository.js';
import type { AdminAuthService } from '../services/admin-auth-service.js';
import type { TelemetryService } from '../../telemetry/services/telemetry-service.js';
import type { BroadcastAnalyticsService } from '../../broadcasts/services/broadcast-analytics-service.js';
import { telemetryQuerySchema } from '../validation/admin-validation.js';
import { AdminMarketProductController } from '../../market/controllers/admin-market-product-controller.js';
import type { MarketProductService } from '../../market/services/market-product-service.js';
import { AdminMandiPriceController } from '../../mandi/controllers/admin-mandi-price-controller.js';
import type { MandiPriceService } from '../../mandi/services/mandi-price-service.js';

export interface AdminRouterDependencies {
  authService: AdminAuthService;
  analytics: AdminAnalyticsRepository;
  audit: AuditLogRepository;
  broadcasts: BroadcastService;
  deletion: AccountDeletionService;
  telemetry: TelemetryService;
  broadcastAnalytics: BroadcastAnalyticsService;
  /** Catalogue management; without it the Market tab has nothing to list. */
  products?: MarketProductService;
  /** Mandi price management: browse the feed, correct it, add missing markets. */
  mandi?: MandiPriceService;
}

/**
 * Role model: `analyst` reads everything, `admin` also acts on farmers and
 * broadcasts, `owner` additionally manages admin accounts.
 */
export function createAdminRouter(
  dependencies: AdminRouterDependencies,
): Router {
  const router = Router();
  const {
    authService,
    analytics,
    audit,
    broadcasts,
    deletion,
    telemetry,
    broadcastAnalytics,
    products,
    mandi,
  } = dependencies;
  const authController = new AdminAuthController(authService, audit);
  const metricsController = new AdminMetricsController(analytics, audit);
  const userController = new AdminUserController(analytics, audit, deletion);
  const broadcastController = new AdminBroadcastController(broadcasts, audit);
  const authenticated = requireAdmin(authService);
  const canWrite = requireRole('owner', 'admin');
  const ownerOnly = requireRole('owner');

  router.post('/auth/login', authController.login);
  router.post('/auth/refresh', authController.refresh);
  router.post('/auth/logout', authController.logout);
  router.get('/auth/me', authenticated, authController.me);
  router.post(
    '/auth/change-password',
    authenticated,
    authController.changePassword,
  );

  router.get('/metrics/overview', authenticated, metricsController.overview);
  router.get('/metrics/growth', authenticated, metricsController.growth);
  router.get(
    '/metrics/distributions',
    authenticated,
    metricsController.distributions,
  );
  router.get('/metrics/activity', authenticated, metricsController.activity);
  router.get('/metrics/filters', authenticated, metricsController.filters);
  router.get('/audit-log', authenticated, metricsController.auditLog);

  // Firebase telemetry is read-only, so analysts get it too.
  router.get('/telemetry/analytics', authenticated, async (request, response) => {
    const { days } = telemetryQuerySchema.parse(request.query);
    return sendSuccess(
      response,
      200,
      'Analytics retrieved successfully',
      await telemetry.analyticsReport(days),
    );
  });

  router.get('/telemetry/crashes', authenticated, async (request, response) => {
    const { days } = telemetryQuerySchema.parse(request.query);
    return sendSuccess(
      response,
      200,
      'Crash report retrieved successfully',
      await telemetry.crashReport(days),
    );
  });

  router.get('/users', authenticated, userController.list);
  router.get('/users/:id', authenticated, userController.get);
  router.patch(
    '/users/:id/status',
    authenticated,
    canWrite,
    userController.setStatus,
  );
  router.delete('/users/:id', authenticated, canWrite, userController.delete);

  router.get('/broadcasts', authenticated, broadcastController.list);
  router.get('/broadcasts/analytics', authenticated, async (request, response) => {
    const { days } = telemetryQuerySchema.parse(request.query);
    return sendSuccess(
      response,
      200,
      'Broadcast analytics retrieved successfully',
      await broadcastAnalytics.report(days),
    );
  });
  router.post(
    '/broadcasts/estimate',
    authenticated,
    broadcastController.estimate,
  );
  router.get('/broadcasts/:id', authenticated, broadcastController.get);
  router.post('/broadcasts', authenticated, canWrite, broadcastController.create);
  router.post(
    '/broadcasts/:id/send',
    authenticated,
    canWrite,
    broadcastController.send,
  );
  router.post(
    '/broadcasts/:id/cancel',
    authenticated,
    canWrite,
    broadcastController.cancel,
  );
  router.delete(
    '/broadcasts/:id',
    authenticated,
    canWrite,
    broadcastController.delete,
  );

  if (products) {
    const productController = new AdminMarketProductController(products, audit);
    router.get('/products', authenticated, productController.list);
    router.post('/products', authenticated, canWrite, productController.create);
    router.put(
      '/products/:id',
      authenticated,
      canWrite,
      productController.update,
    );
    router.delete(
      '/products/:id',
      authenticated,
      canWrite,
      productController.delete,
    );
  }

  if (mandi) {
    const mandiController = new AdminMandiPriceController(mandi, audit);
    router.get('/mandi/filters', authenticated, mandiController.filters);
    router.get('/mandi/prices', authenticated, mandiController.list);
    router.post(
      '/mandi/prices',
      authenticated,
      canWrite,
      mandiController.create,
    );
    router.put(
      '/mandi/prices/:id',
      authenticated,
      canWrite,
      mandiController.update,
    );
    router.delete(
      '/mandi/prices/:id',
      authenticated,
      canWrite,
      mandiController.delete,
    );
  }

  router.get('/admins', authenticated, ownerOnly, authController.listAdmins);
  router.post('/admins', authenticated, ownerOnly, authController.createAdmin);
  router.patch(
    '/admins/:id',
    authenticated,
    ownerOnly,
    authController.updateAdmin,
  );
  router.post(
    '/admins/:id/reset-password',
    authenticated,
    ownerOnly,
    authController.resetPassword,
  );

  return router;
}
