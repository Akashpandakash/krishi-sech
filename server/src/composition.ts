/**
 * Composition root.
 *
 * Every singleton the running server needs is constructed here, and ONLY here.
 * `app.ts` holds the `createApp` factory and must stay free of side effects, so
 * that importing it — from a test, a script, or a tool — never opens a database
 * connection or requires configuration.
 */
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
import { createApp } from './app.js';
import { loadMandiConfig } from './config/mandi-config.js';
import { DataGovMandiPriceProvider } from './mandi/providers/data-gov-mandi-price-provider.js';
import { MongoMandiPriceRepository } from './mandi/repositories/mongo-mandi-price-repository.js';
import { MandiPriceService } from './mandi/services/mandi-price-service.js';
import { MongoMarketProductRepository } from './market/repositories/mongo-market-product-repository.js';
import { MarketProductService } from './market/services/market-product-service.js';

export const appConfig = loadAppConfig();
const mongoUri = process.env.MONGODB_URI?.trim();
if (!mongoUri) {
  // There is no in-memory fallback any more. A server that boots without a
  // database used to serve confidently wrong numbers — zero broadcast reach,
  // zero deletion counts — which is worse than refusing to start.
  throw new Error(
    "MONGODB_URI is required. The server has no in-memory fallback; set it to a MongoDB connection string.",
  );
}
export const mongoDatabase = new MongoDatabase(
  mongoUri,
  process.env.MONGODB_DB_NAME,
);
export const authRepository = new MongoAuthRepository(mongoDatabase);
export const cropRepository = new MongoCropRepository(mongoDatabase);
export const profileRepository = new MongoProfileRepository(mongoDatabase);
export const profileService = new ProfileService(profileRepository);
export const calendarTaskRepository = new MongoCalendarTaskRepository(mongoDatabase);
export const smsProvider = createSmsProvider(appConfig);
export const googleIdTokenVerifier = new GoogleIdTokenVerifier(
  appConfig.googleClientIds,
  appConfig.requestTimeoutMs,
);
export const authService = new AuthService(
  authRepository,
  smsProvider,
  loadAuthConfig(),
  // undefined keeps the default JwtService and OtpService.
  undefined,
  undefined,
  googleIdTokenVerifier,
);
export const cropService = new CropService(cropRepository);
export const aiContextService = new AiContextService(
  authRepository,
  cropRepository,
  new EmptyAiContextRepository(),
);
export const calendarTaskService = new CalendarTaskService(
  calendarTaskRepository,
  cropRepository,
);
export const aiProvider =
  appConfig.aiProvider === "gemini"
    ? new GeminiCompletionProvider(
        process.env.GEMINI_API_KEY?.trim(),
        process.env.GEMINI_MODEL?.trim() || "gemini-flash-latest",
        appConfig.aiEnabled,
        appConfig.requestTimeoutMs,
        appConfig.loggingEnabled,
      )
    : new OpenAiCompletionProvider(
        process.env.OPENAI_API_KEY?.trim(),
        process.env.OPENAI_MODEL?.trim() || "gpt-4o-mini",
        appConfig.aiEnabled,
        appConfig.requestTimeoutMs,
        appConfig.loggingEnabled,
      );
export const aiChatService = new AiChatService(aiContextService, aiProvider);
export const aiDiseaseScanService = new AiDiseaseScanService(
  aiContextService,
  aiProvider,
);
export const fertilizerRecommendationService =
  new FertilizerRecommendationService(
    cropRepository,
    aiContextService,
    new RuleBasedFertilizerRecommendationProvider(),
    new MongoFertilizerRecommendationRepository(mongoDatabase),
  );
export const irrigationRecommendationService =
  new IrrigationRecommendationService(
    cropRepository,
    aiContextService,
    new RuleBasedIrrigationRecommendationProvider(),
    new MongoIrrigationRecommendationRepository(mongoDatabase),
  );
export const weatherService = new WeatherService(
  new OpenMeteoWeatherProvider(
    fetch,
    appConfig.weatherApiBaseUrl,
    appConfig.requestTimeoutMs,
  ),
);
/** Reads Firebase Analytics (GA4 Data API) and Crashlytics (BigQuery export).
 *  Degrades to a reported "not configured" state when credentials are absent. */
export const telemetryService = new TelemetryService(loadTelemetryConfig());

export const adminRepository = new MongoAdminRepository(mongoDatabase);
export const adminAnalyticsRepository = new MongoAdminAnalyticsRepository(mongoDatabase);
export const auditLogRepository = new MongoAuditLogRepository(mongoDatabase);
export const adminAuthService = new AdminAuthService(
  adminRepository,
  loadAdminConfig(),
);
export const broadcastRepository = new MongoBroadcastRepository(mongoDatabase);
/** Shared transport: broadcasts today, task reminders when those land. */
export const pushDeliveryProvider = createPushDeliveryProvider({
  serviceAccount: process.env.FCM_SERVICE_ACCOUNT,
  timeoutMs: appConfig.requestTimeoutMs,
  loggingEnabled: appConfig.loggingEnabled,
  production: appConfig.appEnv === "production",
});
export const broadcastService = new BroadcastService(
  broadcastRepository,
  pushDeliveryProvider,
  appConfig.loggingEnabled,
);
export const accountDeletionService = new AccountDeletionService(
  authService,
  new MongoAccountDeletionRepository(mongoDatabase),
  appConfig.loggingEnabled,
);
export const deviceRepository = new MongoDeviceRepository(mongoDatabase);
export const deviceService = new DeviceService(deviceRepository);

/** Delivery reporting for the admin panel's broadcaster screen. */
export const broadcastAnalyticsService = new BroadcastAnalyticsService(
  broadcastRepository,
  deviceRepository,
  pushDeliveryProvider,
);
export const mandiConfig = loadMandiConfig();
export const mandiPriceService = new MandiPriceService(
  new DataGovMandiPriceProvider(mandiConfig),
  new MongoMandiPriceRepository(mongoDatabase),
  mandiConfig,
);
export const marketProductService = new MarketProductService(
  new MongoMarketProductRepository(mongoDatabase),
);
export const app = createApp(
  authService,
  cropService,
  aiContextService,
  calendarTaskService,
  aiChatService,
  aiDiseaseScanService,
  fertilizerRecommendationService,
  irrigationRecommendationService,
  weatherService,
  {
    config: appConfig,
    readinessProbe: async () => {
      if (!mongoDatabase) throw new Error("MONGODB_URI is not configured");
      await mongoDatabase.ping();
    },
    admin: {
      authService: adminAuthService,
      analytics: adminAnalyticsRepository,
      audit: auditLogRepository,
      broadcasts: broadcastService,
      deletion: accountDeletionService,
      telemetry: telemetryService,
      broadcastAnalytics: broadcastAnalyticsService,
      products: marketProductService,
      mandi: mandiPriceService,
    },
    broadcastService,
    accountDeletionService,
    deviceService,
    mandiPriceService,
    marketProductService,
  },
  profileService,
);
