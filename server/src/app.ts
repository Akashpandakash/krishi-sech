import express from "express";

import { EmptyAiContextRepository } from "./ai/repositories/empty-ai-context-repository.js";
import { OpenAiCompletionProvider } from "./ai/providers/openai-completion-provider.js";
import { GeminiCompletionProvider } from "./ai/providers/gemini-completion-provider.js";
import { createAiContextRouter } from "./ai/routes/ai-context-routes.js";
import { AiContextService } from "./ai/services/ai-context-service.js";
import { AiChatService } from "./ai/services/ai-chat-service.js";
import { AiDiseaseScanService } from "./ai/services/ai-disease-scan-service.js";
import { createSmsProvider } from "./auth/providers/sms-provider-factory.js";
import { InMemoryAuthRepository } from "./auth/repositories/in-memory-auth-repository.js";
import { MongoAuthRepository } from "./auth/repositories/mongo-auth-repository.js";
import { createAuthRouter } from "./auth/routes/auth-routes.js";
import { AuthService } from "./auth/services/auth-service.js";
import { loadAuthConfig } from "./config/auth-config.js";
import { loadAppConfig } from "./config/app-config.js";
import { MongoDatabase } from "./database/mongo-database.js";
import { MongoCalendarTaskRepository } from "./calendar/repositories/mongo-calendar-task-repository.js";
import { InMemoryCalendarTaskRepository } from "./calendar/repositories/in-memory-calendar-task-repository.js";
import { createCalendarTaskRouter } from "./calendar/routes/calendar-task-routes.js";
import { CalendarTaskService } from "./calendar/services/calendar-task-service.js";
import { MongoCropRepository } from "./crops/repositories/mongo-crop-repository.js";
import { InMemoryCropRepository } from "./crops/repositories/in-memory-crop-repository.js";
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
import { InMemoryFertilizerRecommendationRepository } from "./fertilizer/repositories/in-memory-fertilizer-recommendation-repository.js";
import { createIrrigationRecommendationRouter } from "./irrigation/routes/irrigation-recommendation-routes.js";
import { IrrigationRecommendationService } from "./irrigation/services/irrigation-recommendation-service.js";
import { RuleBasedIrrigationRecommendationProvider } from "./irrigation/providers/rule-based-irrigation-recommendation-provider.js";
import { MongoIrrigationRecommendationRepository } from "./irrigation/repositories/mongo-irrigation-recommendation-repository.js";
import { InMemoryIrrigationRecommendationRepository } from "./irrigation/repositories/in-memory-irrigation-recommendation-repository.js";
import { createWeatherRouter } from "./weather/routes/weather-routes.js";
import { WeatherService } from "./weather/services/weather-service.js";
import { OpenMeteoWeatherProvider } from "./weather/providers/open-meteo-weather-provider.js";
import { createProfileRouter } from "./profile/routes/profile-routes.js";
import { ProfileService } from "./profile/services/profile-service.js";
import { MongoProfileRepository } from "./profile/repositories/mongo-profile-repository.js";
import { InMemoryProfileRepository } from "./profile/repositories/in-memory-profile-repository.js";

interface CreateAppOptions {
  config?: ReturnType<typeof loadAppConfig>;
  readinessProbe?: () => Promise<void>;
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
  application.use(notFoundHandler);
  application.use(
    createErrorHandler({
      production: runtimeConfig.appEnv === "production",
      loggingEnabled: runtimeConfig.loggingEnabled,
    }),
  );

  return application;
}

export const appConfig = loadAppConfig();
const mongoUri = process.env.MONGODB_URI?.trim();
if (!mongoUri && appConfig.appEnv === "production") {
  throw new Error("MONGODB_URI is required in production");
}
export const mongoDatabase = mongoUri
  ? new MongoDatabase(mongoUri, process.env.MONGODB_DB_NAME)
  : null;
export const authRepository = mongoDatabase
  ? new MongoAuthRepository(mongoDatabase)
  : new InMemoryAuthRepository();
export const cropRepository = mongoDatabase
  ? new MongoCropRepository(mongoDatabase)
  : new InMemoryCropRepository();
export const profileRepository = mongoDatabase
  ? new MongoProfileRepository(mongoDatabase)
  : new InMemoryProfileRepository(authRepository);
export const profileService = new ProfileService(profileRepository);
export const calendarTaskRepository = mongoDatabase
  ? new MongoCalendarTaskRepository(mongoDatabase)
  : new InMemoryCalendarTaskRepository();
export const smsProvider = createSmsProvider(appConfig);
export const authService = new AuthService(
  authRepository,
  smsProvider,
  loadAuthConfig(),
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
    mongoDatabase
      ? new MongoFertilizerRecommendationRepository(mongoDatabase)
      : new InMemoryFertilizerRecommendationRepository(),
  );
export const irrigationRecommendationService =
  new IrrigationRecommendationService(
    cropRepository,
    aiContextService,
    new RuleBasedIrrigationRecommendationProvider(),
    mongoDatabase
      ? new MongoIrrigationRecommendationRepository(mongoDatabase)
      : new InMemoryIrrigationRecommendationRepository(),
  );
export const weatherService = new WeatherService(
  new OpenMeteoWeatherProvider(
    fetch,
    appConfig.weatherApiBaseUrl,
    appConfig.requestTimeoutMs,
  ),
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
  },
  profileService,
);
