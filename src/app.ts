import express from 'express';
import { PrismaClient } from '@prisma/client';

import { EmptyAiContextRepository } from './ai/repositories/empty-ai-context-repository.js';
import { OpenAiCompletionProvider } from './ai/providers/openai-completion-provider.js';
import { createAiContextRouter } from './ai/routes/ai-context-routes.js';
import { AiContextService } from './ai/services/ai-context-service.js';
import { AiChatService } from './ai/services/ai-chat-service.js';
import { AiDiseaseScanService } from './ai/services/ai-disease-scan-service.js';
import { createSmsProvider } from './auth/providers/sms-provider-factory.js';
import { InMemoryAuthRepository } from './auth/repositories/in-memory-auth-repository.js';
import { PrismaAuthRepository } from './auth/repositories/prisma-auth-repository.js';
import { createAuthRouter } from './auth/routes/auth-routes.js';
import { AuthService } from './auth/services/auth-service.js';
import { loadAuthConfig } from './config/auth-config.js';
import { loadAppConfig } from './config/app-config.js';
import { PrismaCalendarTaskRepository } from './calendar/repositories/prisma-calendar-task-repository.js';
import { createCalendarTaskRouter } from './calendar/routes/calendar-task-routes.js';
import { CalendarTaskService } from './calendar/services/calendar-task-service.js';
import { PrismaCropRepository } from './crops/repositories/prisma-crop-repository.js';
import { createCropRouter } from './crops/routes/crop-routes.js';
import { CropService } from './crops/services/crop-service.js';
import {
  createErrorHandler,
  notFoundHandler,
} from './middleware/error-handler.js';
import { requestIdMiddleware } from './middleware/request-id.js';
import { createCorsMiddleware } from './middleware/cors.js';
import { createRateLimiter } from './middleware/rate-limit.js';
import { createFertilizerRecommendationRouter } from './fertilizer/routes/fertilizer-recommendation-routes.js';
import { FertilizerRecommendationService } from './fertilizer/services/fertilizer-recommendation-service.js';
import { RuleBasedFertilizerRecommendationProvider } from './fertilizer/providers/rule-based-fertilizer-recommendation-provider.js';
import { PrismaFertilizerRecommendationRepository } from './fertilizer/repositories/prisma-fertilizer-recommendation-repository.js';
import { createIrrigationRecommendationRouter } from './irrigation/routes/irrigation-recommendation-routes.js';
import { IrrigationRecommendationService } from './irrigation/services/irrigation-recommendation-service.js';
import { RuleBasedIrrigationRecommendationProvider } from './irrigation/providers/rule-based-irrigation-recommendation-provider.js';
import { PrismaIrrigationRecommendationRepository } from './irrigation/repositories/prisma-irrigation-recommendation-repository.js';
import { createWeatherRouter } from './weather/routes/weather-routes.js';
import { WeatherService } from './weather/services/weather-service.js';
import { OpenMeteoWeatherProvider } from './weather/providers/open-meteo-weather-provider.js';
import { createProfileRouter } from './profile/routes/profile-routes.js';
import { ProfileService } from './profile/services/profile-service.js';
import { PrismaProfileRepository } from './profile/repositories/prisma-profile-repository.js';
import { InMemoryProfileRepository } from './profile/repositories/in-memory-profile-repository.js';

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

  application.disable('x-powered-by');
  if (runtimeConfig.trustProxy) application.set('trust proxy', 1);
  application.use(requestIdMiddleware);
  application.use((_request, response, next) => {
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('X-Frame-Options', 'DENY');
    response.setHeader('Referrer-Policy', 'no-referrer');
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('Content-Security-Policy', "default-src 'none'");
    response.setHeader(
      'Permissions-Policy',
      'camera=(), microphone=(), geolocation=()',
    );
    if (runtimeConfig.appEnv === 'production') {
      response.setHeader(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains',
      );
    }
    next();
  });
  application.use(createCorsMiddleware(runtimeConfig.corsAllowedOrigins));
  application.use(express.json({ limit: '32kb' }));
  if (runtimeConfig.loggingEnabled && process.env.NODE_ENV !== 'test') {
    application.use((request, response, next) => {
      const startedAt = performance.now();
      response.on('finish', () => {
        console.log(
          JSON.stringify({
            event: 'http_request',
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

  application.get('/api/health', (_request, response) => {
    response.status(200).json({
      success: true,
      message: 'Krishi Sech Backend Running',
    });
  });
  application.get('/api/ready', async (_request, response) => {
    let timeout: NodeJS.Timeout | undefined;
    try {
      if (!options.readinessProbe)
        throw new Error('Database probe unavailable');
      await Promise.race([
        options.readinessProbe(),
        new Promise<never>(
          (_resolve, reject) =>
            (timeout = setTimeout(
              () => reject(new Error('Database probe timed out')),
              3000,
            )),
        ),
      ]);
      response.status(200).json({
        success: true,
        status: 'ready',
        checks: { backend: 'ok', environment: 'ok', database: 'ok' },
      });
    } catch {
      response.status(503).json({
        success: false,
        status: 'not_ready',
        checks: {
          backend: 'ok',
          environment: 'ok',
          database: 'unavailable',
        },
        requestId: response.locals.requestId,
      });
    } finally {
      if (timeout) clearTimeout(timeout);
    }
  });
  application.use(
    '/api/auth',
    createRateLimiter({
      windowMs: runtimeConfig.rateLimitWindowMs,
      maxRequests: runtimeConfig.authRateLimitMax,
      scope: 'auth',
    }),
    createAuthRouter(authService),
  );
  if (cropService) {
    application.use('/api/crops', createCropRouter(authService, cropService));
  }
  if (aiContextService) {
    application.use(
      '/api/ai',
      createRateLimiter({
        windowMs: runtimeConfig.rateLimitWindowMs,
        maxRequests: runtimeConfig.aiRateLimitMax,
        scope: 'ai',
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
      '/api/calendar',
      createCalendarTaskRouter(authService, calendarTaskService),
    );
  }
  if (fertilizerRecommendationService) {
    application.use(
      '/api/fertilizer',
      createFertilizerRecommendationRouter(
        authService,
        fertilizerRecommendationService,
      ),
    );
  }
  if (irrigationRecommendationService) {
    application.use(
      '/api/irrigation',
      createIrrigationRecommendationRouter(
        authService,
        irrigationRecommendationService,
      ),
    );
  }
  if (weatherService)
    application.use('/api/weather', createWeatherRouter(weatherService));
  if (profileService)
    application.use(
      '/api/profile',
      createProfileRouter(authService, profileService),
    );
  application.use(notFoundHandler);
  application.use(
    createErrorHandler({
      production: runtimeConfig.appEnv === 'production',
      loggingEnabled: runtimeConfig.loggingEnabled,
    }),
  );

  return application;
}

export const prisma = new PrismaClient();
export const appConfig = loadAppConfig();
export const authRepository = process.env.DATABASE_URL
  ? new PrismaAuthRepository(prisma)
  : appConfig.appEnv === 'production'
    ? (() => {
        throw new Error('DATABASE_URL is required in production');
      })()
    : new InMemoryAuthRepository();
export const cropRepository = new PrismaCropRepository(prisma);
export const profileRepository = process.env.DATABASE_URL
  ? new PrismaProfileRepository(prisma)
  : new InMemoryProfileRepository(authRepository);
export const profileService = new ProfileService(profileRepository);
export const calendarTaskRepository = new PrismaCalendarTaskRepository(prisma);
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
export const openAiProvider = new OpenAiCompletionProvider(
  process.env.OPENAI_API_KEY?.trim(),
  process.env.OPENAI_MODEL?.trim() || 'gpt-4o-mini',
  appConfig.openAiEnabled,
  appConfig.requestTimeoutMs,
  appConfig.loggingEnabled,
);
export const aiChatService = new AiChatService(
  aiContextService,
  openAiProvider,
);
export const aiDiseaseScanService = new AiDiseaseScanService(
  aiContextService,
  openAiProvider,
);
export const fertilizerRecommendationService =
  new FertilizerRecommendationService(
    cropRepository,
    aiContextService,
    new RuleBasedFertilizerRecommendationProvider(),
    new PrismaFertilizerRecommendationRepository(prisma),
  );
export const irrigationRecommendationService =
  new IrrigationRecommendationService(
    cropRepository,
    aiContextService,
    new RuleBasedIrrigationRecommendationProvider(),
    new PrismaIrrigationRecommendationRepository(prisma),
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
      await prisma.$queryRaw`SELECT 1`;
    },
  },
  profileService,
);
