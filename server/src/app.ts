import express from "express";

import { EmptyAiContextRepository } from "./ai/repositories/empty-ai-context-repository.js";
import { OpenAiCompletionProvider } from "./ai/providers/openai-completion-provider.js";
import { GeminiCompletionProvider } from "./ai/providers/gemini-completion-provider.js";
import { createAiContextRouter } from "./ai/routes/ai-context-routes.js";
import { AiContextService } from "./ai/services/ai-context-service.js";
import { AiChatService } from "./ai/services/ai-chat-service.js";
import { AiDiseaseScanService } from "./ai/services/ai-disease-scan-service.js";
import { createSmsProvider } from "./auth/providers/sms-provider-factory.js";
import { MongoAuthRepository } from "./auth/repositories/mongo-auth-repository.js";
import { createAuthRouter } from "./auth/routes/auth-routes.js";
import { AuthService } from "./auth/services/auth-service.js";
import { GoogleIdTokenVerifier } from "./auth/services/google-id-token-verifier.js";
import { loadAuthConfig } from "./config/auth-config.js";
import { loadAppConfig } from "./config/app-config.js";
import { MongoDatabase } from "./database/mongo-database.js";
import { MongoCalendarTaskRepository } from "./calendar/repositories/mongo-calendar-task-repository.js";
import { createCalendarTaskRouter } from "./calendar/routes/calendar-task-routes.js";
import { CalendarTaskService } from "./calendar/services/calendar-task-service.js";
import { MongoCropRepository } from "./crops/repositories/mongo-crop-repository.js";
import { createCropRouter } from "./crops/routes/crop-routes.js";
import { CropService } from "./crops/services/crop-service.js";
import {
  createErrorHandler,
  notFoundHandler,
} from "./middleware/error-handler.js";
import { requestIdMiddleware } from "./middleware/request-id.js";
import { createCorsMiddleware } from "./middleware/cors.js";
import { createRateLimiter } from "./middleware/rate-limit.js";
import { createFertilizerRecommendationRouter } from "./fertilizer/routes/fertilizer-recommendation-routes.js";
import { FertilizerRecommendationService } from "./fertilizer/services/fertilizer-recommendation-service.js";
import { RuleBasedFertilizerRecommendationProvider } from "./fertilizer/providers/rule-based-fertilizer-recommendation-provider.js";
import { MongoFertilizerRecommendationRepository } from "./fertilizer/repositories/mongo-fertilizer-recommendation-repository.js";
import { createIrrigationRecommendationRouter } from "./irrigation/routes/irrigation-recommendation-routes.js";
import { IrrigationRecommendationService } from "./irrigation/services/irrigation-recommendation-service.js";
import { RuleBasedIrrigationRecommendationProvider } from "./irrigation/providers/rule-based-irrigation-recommendation-provider.js";
import { MongoIrrigationRecommendationRepository } from "./irrigation/repositories/mongo-irrigation-recommendation-repository.js";
import { createWeatherRouter } from "./weather/routes/weather-routes.js";
import { WeatherService } from "./weather/services/weather-service.js";
import { OpenMeteoWeatherProvider } from "./weather/providers/open-meteo-weather-provider.js";
import { createProfileRouter } from "./profile/routes/profile-routes.js";
import { ProfileService } from "./profile/services/profile-service.js";
import { MongoProfileRepository } from "./profile/repositories/mongo-profile-repository.js";
import { createAdminRouter } from "./admin/routes/admin-routes.js";
import type { AdminRouterDependencies } from "./admin/routes/admin-routes.js";
import { AdminAuthService } from "./admin/services/admin-auth-service.js";
import { MongoAdminRepository } from "./admin/repositories/mongo-admin-repository.js";
import { MongoAdminAnalyticsRepository } from "./admin/repositories/mongo-admin-analytics-repository.js";
import {
  MongoAuditLogRepository,
} from "./admin/repositories/mongo-audit-log-repository.js";
import { loadAdminConfig } from "./config/admin-config.js";
import { loadTelemetryConfig } from "./config/telemetry-config.js";
import { TelemetryService } from "./telemetry/services/telemetry-service.js";
import { BroadcastService } from "./broadcasts/services/broadcast-service.js";
import { MongoBroadcastRepository } from "./broadcasts/repositories/mongo-broadcast-repository.js";
import { createNotificationRouter } from "./broadcasts/routes/notification-routes.js";
import { createPushDeliveryProvider } from "./broadcasts/providers/push-provider-factory.js";
import { BroadcastAnalyticsService } from "./broadcasts/services/broadcast-analytics-service.js";
import { AccountDeletionService } from "./account/services/account-deletion-service.js";
import { createDeviceRouter } from "./devices/routes/device-routes.js";
import { DeviceService } from "./devices/services/device-service.js";
import { MongoDeviceRepository } from "./devices/repositories/mongo-device-repository.js";
import { MongoAccountDeletionRepository } from "./account/repositories/mongo-account-deletion-repository.js";
import { createAccountRouter } from "./account/routes/account-routes.js";
import { createMandiPriceRouter } from "./mandi/routes/mandi-price-routes.js";
import { MandiPriceService } from "./mandi/services/mandi-price-service.js";
import { createMarketProductRouter } from "./market/routes/market-product-routes.js";
import { MarketProductService } from "./market/services/market-product-service.js";

interface CreateAppOptions {
  config?: ReturnType<typeof loadAppConfig>;
  readinessProbe?: () => Promise<void>;
  /** Admin panel API; omitted in tests that only exercise the app endpoints. */
  admin?: AdminRouterDependencies;
  /** In-app notification inbox fed by admin broadcasts. */
  broadcastService?: BroadcastService;
  /** Self-service account deletion required by the Play Store listing. */
  accountDeletionService?: AccountDeletionService;
  /** FCM device-token registry that gives broadcasts an audience. */
  deviceService?: DeviceService;
  /** Live AGMARKNET mandi prices; absent leaves /api/mandi unmounted. */
  mandiPriceService?: MandiPriceService;
  /** Seller product catalogue behind the Market tab. */
  marketProductService?: MarketProductService;
}

export function createApp(
  authService: AuthService,
  cropService?: CropService,
  aiContextService?: AiContextService,
  calendarTaskService?: CalendarTaskService,
  aiChatService?: AiChatService,
  aiDiseaseScanService?: AiDiseaseScanService,
  fertilizerRecommendationService?: FertilizerRecommendationService,
  irrigationRecommendationService?: IrrigationRecommendationService,
  weatherService?: WeatherService,
  options: CreateAppOptions = {},
  profileService?: ProfileService,
) {
  const runtimeConfig = options.config ?? loadAppConfig();
  const application = express();

  application.disable("x-powered-by");
  if (runtimeConfig.trustProxy) application.set("trust proxy", 1);
  application.use(requestIdMiddleware);
  application.use((_request, response, next) => {
    response.setHeader("X-Content-Type-Options", "nosniff");
    response.setHeader("X-Frame-Options", "DENY");
    response.setHeader("Referrer-Policy", "no-referrer");
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Content-Security-Policy", "default-src 'none'");
    response.setHeader(
      "Permissions-Policy",
      "camera=(), microphone=(), geolocation=()",
    );
    if (runtimeConfig.appEnv === "production") {
      response.setHeader(
        "Strict-Transport-Security",
        "max-age=31536000; includeSubDomains",
      );
    }
    next();
  });
  application.use(createCorsMiddleware(runtimeConfig.corsAllowedOrigins));
  application.use(express.json({ limit: "32kb" }));
  if (runtimeConfig.loggingEnabled && process.env.NODE_ENV !== "test") {
    application.use((request, response, next) => {
      const startedAt = performance.now();
      response.on("finish", () => {
        console.log(
          JSON.stringify({
            event: "http_request",
            requestId: response.locals.requestId,
            method: request.method,
            path: request.path,
            statusCode: response.statusCode,
            responseTimeMs: Math.round(performance.now() - startedAt),
          }),
        );
      });
      next();
    });
  }

  application.get("/api/health", (_request, response) => {
    response.status(200).json({
      success: true,
      message: "Krishi Sech Backend Running",
    });
  });
  application.get("/api/ready", async (_request, response) => {
    let timeout: NodeJS.Timeout | undefined;
    try {
      if (!options.readinessProbe)
        throw new Error("Database probe unavailable");
      await Promise.race([
        options.readinessProbe(),
        new Promise<never>(
          (_resolve, reject) =>
            (timeout = setTimeout(
              () => reject(new Error("Database probe timed out")),
              3000,
            )),
        ),
      ]);
      response.status(200).json({
        success: true,
        status: "ready",
        checks: { backend: "ok", environment: "ok", database: "ok" },
      });
    } catch {
      response.status(503).json({
        success: false,
        status: "not_ready",
        checks: {
          backend: "ok",
          environment: "ok",
          database: "unavailable",
        },
        requestId: response.locals.requestId,
      });
    } finally {
      if (timeout) clearTimeout(timeout);
    }
  });
  application.use(
    "/api/auth",
    createRateLimiter({
      windowMs: runtimeConfig.rateLimitWindowMs,
      maxRequests: runtimeConfig.authRateLimitMax,
      scope: "auth",
    }),
    createAuthRouter(authService),
  );
  if (cropService) {
    application.use("/api/crops", createCropRouter(authService, cropService));
  }
  if (aiContextService) {
    application.use(
      "/api/ai",
      createRateLimiter({
        windowMs: runtimeConfig.rateLimitWindowMs,
        maxRequests: runtimeConfig.aiRateLimitMax,
        scope: "ai",
      }),
      createAiContextRouter(
        authService,
        aiContextService,
        aiChatService,
        aiDiseaseScanService,
      ),
    );
  }
  if (calendarTaskService) {
    application.use(
      "/api/calendar",
      createCalendarTaskRouter(authService, calendarTaskService),
    );
  }
  if (fertilizerRecommendationService) {
    application.use(
      "/api/fertilizer",
      createFertilizerRecommendationRouter(
        authService,
        fertilizerRecommendationService,
      ),
    );
  }
  if (irrigationRecommendationService) {
    application.use(
      "/api/irrigation",
      createIrrigationRecommendationRouter(
        authService,
        irrigationRecommendationService,
      ),
    );
  }
  if (weatherService)
    application.use("/api/weather", createWeatherRouter(weatherService));
  if (profileService)
    application.use(
      "/api/profile",
      createProfileRouter(authService, profileService),
    );
  if (options.broadcastService)
    application.use(
      "/api/notifications",
      createNotificationRouter(authService, options.broadcastService),
    );
  if (options.accountDeletionService)
    application.use(
      "/api/account",
      // Deletion is destructive and unauthenticated up to the OTP step, so it
      // shares the stricter auth budget rather than the general one.
      createRateLimiter({
        windowMs: runtimeConfig.rateLimitWindowMs,
        maxRequests: runtimeConfig.authRateLimitMax,
        scope: "account",
      }),
      createAccountRouter(authService, options.accountDeletionService),
    );
  if (options.deviceService)
    application.use(
      "/api/devices",
      createDeviceRouter(authService, options.deviceService),
    );
  if (options.mandiPriceService)
    application.use(
      "/api/mandi",
      createMandiPriceRouter(authService, options.mandiPriceService),
    );
  if (options.marketProductService)
    application.use(
      "/api/market",
      createMarketProductRouter(authService, options.marketProductService),
    );
  if (options.admin)
    application.use(
      "/api/admin",
      createRateLimiter({
        windowMs: runtimeConfig.rateLimitWindowMs,
        maxRequests: runtimeConfig.adminRateLimitMax,
        scope: "admin",
      }),
      createAdminRouter(options.admin),
    );
  application.use(notFoundHandler);
  application.use(
    createErrorHandler({
      production: runtimeConfig.appEnv === "production",
      loggingEnabled: runtimeConfig.loggingEnabled,
    }),
  );

  return application;
}
