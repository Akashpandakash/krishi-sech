import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import request from 'supertest';
import express from 'express';

import { DummySmsProvider } from './auth/providers/dummy-sms-provider.js';
import type {
  AuthOtp,
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
  GoogleUserInput,
} from './auth/repositories/auth-repository.js';
import { AuthService } from './auth/services/auth-service.js';
import type {
  CalendarTaskInput,
  CalendarTaskRecord,
  CalendarTaskRepository,
} from './calendar/repositories/calendar-task-repository.js';
import { CalendarTaskService } from './calendar/services/calendar-task-service.js';
import type {
  AiCompletionMessage,
  AiCompletionProvider,
} from './ai/providers/ai-completion-provider.js';
import { EmptyAiContextRepository } from './ai/repositories/empty-ai-context-repository.js';
import { AiChatService } from './ai/services/ai-chat-service.js';
import { AiContextService } from './ai/services/ai-context-service.js';
import { createApp } from './app.js';
import type { AuthConfig } from './config/auth-config.js';
import type {
  CropInput,
  CropRecord,
  CropRepository,
} from './crops/repositories/crop-repository.js';
import { CropService } from './crops/services/crop-service.js';
import { loadAppConfig } from './config/app-config.js';
import { AppError } from './common/app-error.js';
import { requestIdMiddleware } from './middleware/request-id.js';
import { createErrorHandler } from './middleware/error-handler.js';
import { ProfileService } from './profile/services/profile-service.js';
import { supportedAppLocaleCodes } from './localization/supported-locales.js';
import { updateUserProfileSchema } from './profile/validation/profile-validation.js';
import { InMemoryProfileRepository } from './testing/repository-fakes.js';

describe('profile language validation', () => {
  const profile = (preferredLanguage: unknown) => ({
    name: 'Akash Farmer',
    preferredLanguage,
    state: 'West Bengal',
    district: 'Kolkata',
    village: 'New Town',
  });

  it('uses the exact 22 Scheduled Language codes plus English', () => {
    assert.deepEqual(supportedAppLocaleCodes, [
      'as',
      'bn',
      'brx',
      'doi',
      'gu',
      'hi',
      'kn',
      'ks',
      'kok',
      'mai',
      'ml',
      'mni',
      'mr',
      'ne',
      'or',
      'pa',
      'sa',
      'sat',
      'sd',
      'ta',
      'te',
      'ur',
      'en',
    ]);
    assert.equal(new Set(supportedAppLocaleCodes).size, 23);
  });

  it('accepts English, Bangla, and Hindi', () => {
    for (const code of ['en', 'bn', 'hi']) {
      assert.equal(updateUserProfileSchema.safeParse(profile(code)).success, true);
    }
  });

  it('accepts representative English-fallback languages', () => {
    for (const code of ['gu', 'ta', 'as']) {
      assert.equal(updateUserProfileSchema.safeParse(profile(code)).success, true);
    }
  });

  it('accepts Urdu, Kashmiri, and Sindhi', () => {
    for (const code of ['ur', 'ks', 'sd']) {
      assert.equal(updateUserProfileSchema.safeParse(profile(code)).success, true);
    }
  });

  it('rejects unsupported and malformed locale values', () => {
    for (const value of ['fr', 'en-US', 'EN', '', 'unknown', 123, null]) {
      assert.equal(
        updateUserProfileSchema.safeParse(profile(value)).success,
        false,
      );
    }
  });
});

describe('GET /api/health', () => {
  it('preserves the backend health endpoint', async () => {
    // Built locally rather than importing the composed app: app.ts is now a
    // side-effect-free factory, and the composition root requires a database.
    const { app: healthApp } = authenticationFixture();
    const response = await request(healthApp).get('/api/health').expect(200);
    assert.deepEqual(response.body, {
      success: true,
      message: 'Krishi Sech Backend Running',
    });
    assert.equal(response.headers['x-content-type-options'], 'nosniff');
    assert.equal(response.headers['x-frame-options'], 'DENY');
    assert.equal(response.headers['referrer-policy'], 'no-referrer');
    assert.equal(response.headers['cache-control'], 'no-store');
    assert.match(response.headers['x-request-id'], /^[A-Za-z0-9._-]+$/);
  });
});

class MemoryAuthRepository implements AuthRepository {
  readonly users: AuthUser[] = [];

  async findUserByGoogleId(googleId: string) {
    return this.users.find((user) => user.googleId === googleId) ?? null;
  }

  async createGoogleUser(input: GoogleUserInput) {
    const now = new Date();
    const user: AuthUser = {
      id: `user-${this.users.length + 1}`,
      phone: null,
      email: input.email,
      googleId: input.googleId,
      name: input.name,
      preferredLanguage: 'bn',
      profilePhotoUrl: input.profilePhotoUrl,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };
    this.users.push(user);
    return user;
  }

  readonly otps: (AuthOtp & { createdAt: Date })[] = [];
  readonly refreshTokens: AuthRefreshToken[] = [];

  async createOtp(phone: string, codeHash: string, expiresAt: Date) {
    this.otps.push({
      id: `otp-${this.otps.length + 1}`,
      phone,
      codeHash,
      expiresAt,
      attempts: 0,
      consumedAt: null,
      createdAt: new Date(),
    });
  }

  async countOtpRequests(phone: string, since: Date) {
    return this.otps.filter(
      (otp) => otp.phone === phone && otp.createdAt >= since,
    ).length;
  }

  async findLatestOtp(phone: string) {
    return (
      [...this.otps]
        .reverse()
        .find((otp) => otp.phone === phone && !otp.consumedAt) ?? null
    );
  }

  async incrementOtpAttempts(id: string) {
    const otp = this.otps.find((item) => item.id === id);
    if (otp) otp.attempts += 1;
  }

  async consumeOtp(id: string) {
    const otp = this.otps.find((item) => item.id === id);
    if (otp) otp.consumedAt = new Date();
  }

  async findUserByPhone(phone: string) {
    return this.users.find((user) => user.phone === phone) ?? null;
  }

  async findUserById(id: string) {
    return this.users.find((user) => user.id === id) ?? null;
  }

  async deleteUser(id: string) {
    const index = this.users.findIndex((user) => user.id === id);
    if (index >= 0) this.users.splice(index, 1);
  }

  async createUser(phone: string) {
    const now = new Date();
    const user: AuthUser = {
      id: `user-${this.users.length + 1}`,
      phone,
      email: null,
      googleId: null,
      name: null,
      preferredLanguage: 'bn',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };
    this.users.push(user);
    return user;
  }

  async ensureDemoUser(phone: string) {
    const existing = await this.findUserByPhone(phone);
    if (existing) {
      existing.name = 'Demo Farmer';
      existing.preferredLanguage = 'en';
      existing.isActive = true;
      return existing;
    }
    const user = await this.createUser(phone);
    user.name = 'Demo Farmer';
    user.preferredLanguage = 'en';
    return user;
  }

  async createRefreshToken(userId: string, tokenHash: string, expiresAt: Date) {
    this.refreshTokens.push({
      id: `refresh-${this.refreshTokens.length + 1}`,
      userId,
      tokenHash,
      expiresAt,
      revokedAt: null,
    });
  }

  async findRefreshToken(tokenHash: string) {
    return (
      this.refreshTokens.find((token) => token.tokenHash === tokenHash) ?? null
    );
  }

  async rotateRefreshToken(
    currentTokenId: string,
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    await this.revokeRefreshToken(currentTokenId);
    await this.createRefreshToken(userId, tokenHash, expiresAt);
  }

  async revokeRefreshToken(id: string) {
    const token = this.refreshTokens.find((item) => item.id === id);
    if (token && !token.revokedAt) token.revokedAt = new Date();
  }
}

const testConfig: AuthConfig = {
  accessTokenSecret: 'test-access-secret',
  refreshTokenSecret: 'test-refresh-secret',
  otpHashSecret: 'test-otp-secret',
  accessTokenTtlSeconds: 15 * 60,
  refreshTokenTtlSeconds: 30 * 24 * 60 * 60,
  otpTtlSeconds: 5 * 60,
  otpRequestWindowSeconds: 10 * 60,
  otpMaxRequestsPerWindow: 3,
  exposeDebugOtp: true,
  demoLoginEnabled: false,
};

function authenticationFixture() {
  const repository = new MemoryAuthRepository();
  const sms = new DummySmsProvider();
  const service = new AuthService(repository, sms, testConfig);
  return { repository, app: createApp(service) };
}

function appWithOptions(
  service: AuthService,
  options: Parameters<typeof createApp>[9],
) {
  return createApp(
    service,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    options,
  );
}

describe('production infrastructure middleware', () => {
  it('reports readiness only when the database probe succeeds', async () => {
    const { repository } = authenticationFixture();
    const service = new AuthService(
      repository,
      new DummySmsProvider(),
      testConfig,
    );
    const readyApp = appWithOptions(service, {
      readinessProbe: async () => {},
    });
    const ready = await request(readyApp).get('/api/ready').expect(200);
    assert.deepEqual(ready.body, {
      success: true,
      status: 'ready',
      checks: { backend: 'ok', environment: 'ok', database: 'ok' },
    });
    assert.ok(ready.headers['x-request-id']);

    const unavailableApp = appWithOptions(service, {
      readinessProbe: async () => {
        throw new Error('connection detail that must remain private');
      },
    });
    const unavailable = await request(unavailableApp)
      .get('/api/ready')
      .expect(503);
    assert.equal(unavailable.body.checks.database, 'unavailable');
    assert.doesNotMatch(JSON.stringify(unavailable.body), /connection detail/);
  });

  it('rate limits authentication requests by client address', async () => {
    const repository = new MemoryAuthRepository();
    const service = new AuthService(
      repository,
      new DummySmsProvider(),
      testConfig,
    );
    const config = loadAppConfig({
      APP_ENV: 'development',
      LOGGING_ENABLED: 'false',
      AUTH_RATE_LIMIT_MAX: '1',
      RATE_LIMIT_WINDOW_MS: '60000',
    });
    const limitedApp = appWithOptions(service, { config });
    await request(limitedApp)
      .post('/api/auth/send-otp')
      .send({ phone: '+919811111111' })
      .expect(200);
    const limited = await request(limitedApp)
      .post('/api/auth/send-otp')
      .send({ phone: '+919822222222' })
      .expect(429);
    assert.equal(limited.body.error.code, 'RATE_LIMITED');
    assert.ok(limited.headers['retry-after']);
  });

  it('rate limits AI requests independently', async () => {
    const authRepository = new MemoryAuthRepository();
    const service = new AuthService(
      authRepository,
      new DummySmsProvider(),
      testConfig,
    );
    const contextService = new AiContextService(
      authRepository,
      new MemoryCropRepository(),
      new EmptyAiContextRepository(),
    );
    const config = loadAppConfig({
      APP_ENV: 'development',
      LOGGING_ENABLED: 'false',
      AI_RATE_LIMIT_MAX: '1',
      RATE_LIMIT_WINDOW_MS: '60000',
    });
    const limitedApp = createApp(
      service,
      undefined,
      contextService,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      { config },
    );
    await request(limitedApp).get('/api/ai/context').expect(401);
    const limited = await request(limitedApp)
      .get('/api/ai/context')
      .expect(429);
    assert.equal(limited.body.error.code, 'RATE_LIMITED');
  });

  it('allows only configured production CORS origins and trusts one proxy', async () => {
    const { repository } = authenticationFixture();
    const service = new AuthService(
      repository,
      new DummySmsProvider(),
      testConfig,
    );
    const config = loadAppConfig({
      APP_ENV: 'production',
      LOGGING_ENABLED: 'false',
      DEMO_LOGIN_ENABLED: 'false',
      DEBUG_OTP_ENABLED: 'false',
      OPENAI_ENABLED: 'false',
      TRUST_PROXY: 'true',
      CORS_ALLOWED_ORIGINS: 'https://admin.krishisech.com',
    });
    const productionApp = appWithOptions(service, {
      config,
      readinessProbe: async () => {},
    });
    assert.equal(productionApp.get('trust proxy'), 1);
    const allowed = await request(productionApp)
      .get('/api/health')
      .set('Origin', 'https://admin.krishisech.com')
      .expect(200);
    assert.equal(
      allowed.headers['access-control-allow-origin'],
      'https://admin.krishisech.com',
    );
    await request(productionApp)
      .get('/api/health')
      .set('Origin', 'https://untrusted.example')
      .expect(403);
  });

  it('sanitizes production server errors and includes a request ID', async () => {
    const errorApp = express();
    errorApp.use(requestIdMiddleware);
    errorApp.get('/failure', () => {
      throw new AppError(502, 'UPSTREAM_FAILED', 'private upstream detail');
    });
    errorApp.use(
      createErrorHandler({ production: true, loggingEnabled: false }),
    );
    const response = await request(errorApp).get('/failure').expect(502);
    assert.equal(
      response.body.error.message,
      'Service temporarily unavailable',
    );
    assert.equal(response.body.error.code, 'UPSTREAM_FAILED');
    assert.ok(response.body.requestId);
    assert.doesNotMatch(
      JSON.stringify(response.body),
      /private upstream detail/,
    );
  });
});

describe('authenticated user and farm profiles', () => {
  async function fixture() {
    const repository = new MemoryAuthRepository();
    const auth = new AuthService(
      repository,
      new DummySmsProvider(),
      testConfig,
    );
    const profiles = new ProfileService(
      new InMemoryProfileRepository(repository),
    );
    const profileApp = createApp(
      auth,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      {},
      profiles,
    );
    const sent = await request(profileApp)
      .post('/api/auth/send-otp')
      .send({ phone: '+919812345678' })
      .expect(200);
    const verified = await request(profileApp)
      .post('/api/auth/verify-otp')
      .send({ phone: '+919812345678', otp: sent.body.data.debugOtp })
      .expect(200);
    return {
      app: profileApp,
      authorization: `Bearer ${verified.body.data.accessToken}`,
    };
  }

  it('reads and updates only the authenticated user profile', async () => {
    const value = await fixture();
    await request(value.app).get('/api/profile').expect(401);
    const updated = await request(value.app)
      .put('/api/profile')
      .set('Authorization', value.authorization)
      .send({
        name: 'Akash Farmer',
        preferredLanguage: 'bn',
        state: 'West Bengal',
        district: 'Kolkata',
        village: 'New Town',
      })
      .expect(200);
    assert.equal(updated.body.data.name, 'Akash Farmer');
    assert.equal(updated.body.data.phone, '+919812345678');
    const fetched = await request(value.app)
      .get('/api/profile')
      .set('Authorization', value.authorization)
      .expect(200);
    assert.equal(fetched.body.data.name, 'Akash Farmer');
  });

  it('validates and persists the authenticated farm profile', async () => {
    const value = await fixture();
    await request(value.app)
      .put('/api/profile/farm')
      .set('Authorization', value.authorization)
      .send({
        farmName: '',
        farmerType: 'small',
        totalLandArea: 0,
        landUnit: 'acre',
        soilType: 'loamy',
        irrigationSource: 'canal',
        mainCrops: [],
      })
      .expect(400);
    const body = {
      farmName: 'Green Farm',
      farmerType: 'small',
      totalLandArea: 2.5,
      landUnit: 'acre',
      soilType: 'loamy',
      irrigationSource: 'canal',
      mainCrops: ['Paddy', 'Wheat'],
      coarseLocation: 'Kolkata district',
    };
    await request(value.app)
      .put('/api/profile/farm')
      .set('Authorization', value.authorization)
      .send(body)
      .expect(200);
    const fetched = await request(value.app)
      .get('/api/profile/farm')
      .set('Authorization', value.authorization)
      .expect(200);
    assert.equal(fetched.body.data.farmName, 'Green Farm');
    assert.deepEqual(fetched.body.data.mainCrops, ['Paddy', 'Wheat']);
  });
});

class MemoryCropRepository implements CropRepository {
  readonly crops: CropRecord[] = [];

  async create(userId: string, input: CropInput, id = randomUUID()) {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing) return existing;
    const now = new Date();
    const crop = {
      ...input,
      id,
      userId,
      createdAt: now,
      updatedAt: now,
    };
    this.crops.push(crop);
    return crop;
  }

  async findAllByUser(userId: string) {
    return this.crops.filter((crop) => crop.userId === userId);
  }

  async findByIdAndUser(id: string, userId: string) {
    return (
      this.crops.find((crop) => crop.id === id && crop.userId === userId) ??
      null
    );
  }

  async update(id: string, userId: string, input: CropInput) {
    const index = this.crops.findIndex(
      (crop) => crop.id === id && crop.userId === userId,
    );
    const updated = {
      ...this.crops[index],
      ...input,
      updatedAt: new Date(),
    };
    this.crops[index] = updated;
    return updated;
  }

  async delete(id: string, userId: string) {
    const index = this.crops.findIndex(
      (crop) => crop.id === id && crop.userId === userId,
    );
    if (index >= 0) this.crops.splice(index, 1);
  }
}

class MemoryCalendarTaskRepository implements CalendarTaskRepository {
  readonly tasks: CalendarTaskRecord[] = [];

  async create(userId: string, input: CalendarTaskInput) {
    const now = new Date();
    const task = { ...input, userId, createdAt: now, updatedAt: now };
    this.tasks.push(task);
    return task;
  }

  async findAllByUser(userId: string) {
    return this.tasks.filter((task) => task.userId === userId);
  }

  async findByIdAndUser(id: string, userId: string) {
    return (
      this.tasks.find((task) => task.id === id && task.userId === userId) ??
      null
    );
  }

  async update(
    id: string,
    userId: string,
    input: Omit<CalendarTaskInput, 'id'>,
  ) {
    const index = this.tasks.findIndex(
      (task) => task.id === id && task.userId === userId,
    );
    const updated = { ...this.tasks[index], ...input, updatedAt: new Date() };
    this.tasks[index] = updated;
    return updated;
  }

  async delete(id: string, userId: string) {
    const index = this.tasks.findIndex(
      (task) => task.id === id && task.userId === userId,
    );
    if (index >= 0) this.tasks.splice(index, 1);
  }
}

async function authenticatedCropFixture(phone: string) {
  const authRepository = new MemoryAuthRepository();
  const sms = new DummySmsProvider();
  const authService = new AuthService(authRepository, sms, testConfig);
  const cropRepository = new MemoryCropRepository();
  const cropApp = createApp(authService, new CropService(cropRepository));
  const sent = await request(cropApp)
    .post('/api/auth/send-otp')
    .send({ phone })
    .expect(200);
  const verified = await request(cropApp)
    .post('/api/auth/verify-otp')
    .send({ phone, otp: sent.body.data.debugOtp })
    .expect(200);
  return {
    app: cropApp,
    repository: cropRepository,
    accessToken: verified.body.data.accessToken as string,
  };
}

describe('authentication', () => {
  it('completes OTP login, protected me, rotation, and logout', async () => {
    const fixture = authenticationFixture();
    const phone = '+919876543210';
    const sent = await request(fixture.app)
      .post('/api/auth/send-otp')
      .send({ phone })
      .expect(200);
    assert.match(sent.body.data.debugOtp, /^\d{6}$/);

    const verified = await request(fixture.app)
      .post('/api/auth/verify-otp')
      .send({ phone, otp: sent.body.data.debugOtp })
      .expect(200);
    const { accessToken, refreshToken, user } = verified.body.data;
    assert.equal(user.phone, phone);
    assert.equal(user.preferredLanguage, 'bn');

    const me = await request(fixture.app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    assert.equal(me.body.data.id, user.id);

    const refreshed = await request(fixture.app)
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(200);
    assert.notEqual(refreshed.body.data.refreshToken, refreshToken);
    await request(fixture.app)
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(401);

    await request(fixture.app)
      .post('/api/auth/logout')
      .send({ refreshToken: refreshed.body.data.refreshToken })
      .expect(200);
    await request(fixture.app)
      .post('/api/auth/refresh')
      .send({ refreshToken: refreshed.body.data.refreshToken })
      .expect(401);
  });

  it('prevents OTP reuse and rejects invalid requests', async () => {
    const fixture = authenticationFixture();
    const phone = '+919876543210';
    await request(fixture.app)
      .post('/api/auth/send-otp')
      .send({ phone: '9876543210' })
      .expect(400);
    const sent = await request(fixture.app)
      .post('/api/auth/send-otp')
      .send({ phone })
      .expect(200);
    const otp = sent.body.data.debugOtp;
    await request(fixture.app)
      .post('/api/auth/verify-otp')
      .send({ phone, otp: '000000' })
      .expect(400);
    await request(fixture.app)
      .post('/api/auth/verify-otp')
      .send({ phone, otp })
      .expect(200);
    await request(fixture.app)
      .post('/api/auth/verify-otp')
      .send({ phone, otp })
      .expect(400);
  });

  it('throttles repeated OTP requests', async () => {
    const fixture = authenticationFixture();
    const body = { phone: '+919876543210' };
    await request(fixture.app)
      .post('/api/auth/send-otp')
      .send(body)
      .expect(200);
    await request(fixture.app)
      .post('/api/auth/send-otp')
      .send(body)
      .expect(200);
    await request(fixture.app)
      .post('/api/auth/send-otp')
      .send(body)
      .expect(200);
    await request(fixture.app)
      .post('/api/auth/send-otp')
      .send(body)
      .expect(429);
  });

  it('uses the demo OTP and stable demo user only for a development client', async () => {
    const repository = new MemoryAuthRepository();
    const service = new AuthService(repository, new DummySmsProvider(), {
      ...testConfig,
      demoLoginEnabled: true,
      exposeDebugOtp: false,
    });
    const demoApp = createApp(service);
    const headers = { 'X-Krishi-Development-Client': 'true' };
    const body = { phone: '+919999999999' };

    const sent = await request(demoApp)
      .post('/api/auth/send-otp')
      .set(headers)
      .send(body)
      .expect(200);
    assert.equal(sent.body.data.debugOtp, '123456');

    const first = await request(demoApp)
      .post('/api/auth/verify-otp')
      .set(headers)
      .send({ ...body, otp: '123456' })
      .expect(200);
    const second = await request(demoApp)
      .post('/api/auth/verify-otp')
      .set(headers)
      .send({ ...body, otp: '123456' })
      .expect(200);

    assert.equal(first.body.data.user.id, second.body.data.user.id);
    assert.equal(first.body.data.user.name, 'Demo Farmer');
    assert.equal(first.body.data.user.preferredLanguage, 'en');
    assert.equal(first.body.data.user.isActive, true);
    assert.ok(first.body.data.accessToken);
    assert.ok(first.body.data.refreshToken);

    const realUser = await repository.createUser('+919812345678');
    assert.notEqual(realUser.id, first.body.data.user.id);
    assert.equal(realUser.name, null);
    assert.equal(
      (await repository.findUserByPhone('+919999999999'))?.name,
      'Demo Farmer',
    );
  });

  it('rejects the demo credentials when production demo mode is disabled', async () => {
    const repository = new MemoryAuthRepository();
    const service = new AuthService(repository, new DummySmsProvider(), {
      ...testConfig,
      demoLoginEnabled: false,
      exposeDebugOtp: false,
    });
    const productionApp = createApp(service);

    await request(productionApp)
      .post('/api/auth/verify-otp')
      .set('X-Krishi-Development-Client', 'true')
      .send({ phone: '+919999999999', otp: '123456' })
      .expect(400);
    assert.equal(await repository.findUserByPhone('+919999999999'), null);
  });

  it('rejects the demo credentials in staging', async () => {
    const staging = loadAppConfig({
      APP_ENV: 'staging',
      LOGGING_ENABLED: 'false',
      DEMO_LOGIN_ENABLED: 'false',
      DEBUG_OTP_ENABLED: 'false',
      OPENAI_ENABLED: 'false',
    });
    const repository = new MemoryAuthRepository();
    const service = new AuthService(repository, new DummySmsProvider(), {
      ...testConfig,
      demoLoginEnabled: staging.demoLoginEnabled,
      exposeDebugOtp: staging.debugOtpEnabled,
    });
    const stagingApp = createApp(service);

    await request(stagingApp)
      .post('/api/auth/verify-otp')
      .set('X-Krishi-Development-Client', 'true')
      .send({ phone: '+919999999999', otp: '123456' })
      .expect(400);
    assert.equal(await repository.findUserByPhone('+919999999999'), null);
  });
});

describe('crop management', () => {
  const cropBody = {
    cropName: 'Paddy',
    variety: 'Swarna',
    sowingDate: '2026-06-01',
    growthStage: 'vegetative',
    landArea: 2.5,
    landUnit: 'acre',
    soilType: 'alluvial',
    irrigationMethod: 'flood',
    expectedHarvestDate: '2026-10-15',
    healthStatus: 'healthy',
    notes: 'North field',
  };

  it('requires authentication and validates crop input', async () => {
    const fixture = await authenticatedCropFixture('+919876543210');
    await request(fixture.app).get('/api/crops').expect(401);
    await request(fixture.app)
      .post('/api/crops')
      .set('Authorization', `Bearer ${fixture.accessToken}`)
      .send({ ...cropBody, landArea: 0 })
      .expect(400);
  });

  it('creates, lists, reads, updates, and deletes a crop', async () => {
    const fixture = await authenticatedCropFixture('+919876543210');
    const authorization = `Bearer ${fixture.accessToken}`;
    const created = await request(fixture.app)
      .post('/api/crops')
      .set('Authorization', authorization)
      .send(cropBody)
      .expect(201);
    const cropId = created.body.data.id as string;
    assert.equal(created.body.data.cropName, 'Paddy');

    const list = await request(fixture.app)
      .get('/api/crops')
      .set('Authorization', authorization)
      .expect(200);
    assert.equal(list.body.data.length, 1);

    await request(fixture.app)
      .get(`/api/crops/${cropId}`)
      .set('Authorization', authorization)
      .expect(200);

    const updated = await request(fixture.app)
      .put(`/api/crops/${cropId}`)
      .set('Authorization', authorization)
      .send({
        ...cropBody,
        variety: 'Swarna Sub-1',
        growthStage: 'flowering',
        healthStatus: 'moderate',
      })
      .expect(200);
    assert.equal(updated.body.data.variety, 'Swarna Sub-1');
    assert.equal(updated.body.data.growthStage, 'flowering');
    assert.equal(updated.body.data.healthStatus, 'moderate');

    const refreshed = await request(fixture.app)
      .get(`/api/crops/${cropId}`)
      .set('Authorization', authorization)
      .expect(200);
    assert.equal(refreshed.body.data.variety, 'Swarna Sub-1');
    assert.equal(refreshed.body.data.healthStatus, 'moderate');

    await request(fixture.app)
      .delete(`/api/crops/${cropId}`)
      .set('Authorization', authorization)
      .expect(200);
    await request(fixture.app)
      .get(`/api/crops/${cropId}`)
      .set('Authorization', authorization)
      .expect(404);
  });

  it('creates one crop when an idempotency key is replayed', async () => {
    const fixture = await authenticatedCropFixture('+919876543210');
    const authorization = `Bearer ${fixture.accessToken}`;
    const idempotencyKey = 'd89d24d7-1d0d-4a1c-9cd3-a457e9485760';

    const first = await request(fixture.app)
      .post('/api/crops')
      .set('Authorization', authorization)
      .set('Idempotency-Key', idempotencyKey)
      .send(cropBody)
      .expect(201);
    const replay = await request(fixture.app)
      .post('/api/crops')
      .set('Authorization', authorization)
      .set('Idempotency-Key', idempotencyKey)
      .send(cropBody)
      .expect(201);

    assert.equal(first.body.data.id, idempotencyKey);
    assert.equal(replay.body.data.id, idempotencyKey);
    const list = await request(fixture.app)
      .get('/api/crops')
      .set('Authorization', authorization)
      .expect(200);
    assert.equal(list.body.data.length, 1);
  });

  it("never exposes another user's crop", async () => {
    const owner = await authenticatedCropFixture('+919876543210');
    const created = await request(owner.app)
      .post('/api/crops')
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send(cropBody)
      .expect(201);

    const sent = await request(owner.app)
      .post('/api/auth/send-otp')
      .send({ phone: '+919999999999' })
      .expect(200);
    const verified = await request(owner.app)
      .post('/api/auth/verify-otp')
      .send({ phone: '+919999999999', otp: sent.body.data.debugOtp })
      .expect(200);
    const otherToken = verified.body.data.accessToken;

    const list = await request(owner.app)
      .get('/api/crops')
      .set('Authorization', `Bearer ${otherToken}`)
      .expect(200);
    assert.deepEqual(list.body.data, []);
    await request(owner.app)
      .get(`/api/crops/${created.body.data.id}`)
      .set('Authorization', `Bearer ${otherToken}`)
      .expect(404);
  });
});

describe('calendar task synchronization API', () => {
  const cropBody = {
    cropName: 'Paddy',
    variety: 'Swarna',
    sowingDate: '2026-06-01',
    growthStage: 'vegetative',
    landArea: 2.5,
    landUnit: 'acre',
    soilType: 'alluvial',
    irrigationMethod: 'flood',
    expectedHarvestDate: '2026-10-15',
    healthStatus: 'healthy',
    notes: null,
  };

  async function fixture(phone: string) {
    const authRepository = new MemoryAuthRepository();
    const authService = new AuthService(
      authRepository,
      new DummySmsProvider(),
      testConfig,
    );
    const cropRepository = new MemoryCropRepository();
    const taskRepository = new MemoryCalendarTaskRepository();
    const calendarService = new CalendarTaskService(
      taskRepository,
      cropRepository,
    );
    const calendarApp = createApp(
      authService,
      new CropService(cropRepository),
      undefined,
      calendarService,
    );
    const sent = await request(calendarApp)
      .post('/api/auth/send-otp')
      .send({ phone })
      .expect(200);
    const verified = await request(calendarApp)
      .post('/api/auth/verify-otp')
      .send({ phone, otp: sent.body.data.debugOtp })
      .expect(200);
    const authorization = `Bearer ${verified.body.data.accessToken}`;
    const crop = await request(calendarApp)
      .post('/api/crops')
      .set('Authorization', authorization)
      .send(cropBody)
      .expect(201);
    return {
      app: calendarApp,
      authorization,
      cropId: crop.body.data.id as string,
      repository: taskRepository,
    };
  }

  it('creates, lists, updates, and deletes an owned crop task', async () => {
    const owner = await fixture('+919811111111');
    const id = `generated-${owner.cropId}-irrigation`;
    const created = await request(owner.app)
      .post('/api/calendar/tasks')
      .set('Authorization', owner.authorization)
      .send({
        id,
        cropId: owner.cropId,
        taskType: 'irrigation',
        dueDate: '2026-08-10T07:00:00.000Z',
        status: 'pending',
        notes: 'Check soil moisture',
        reminderEnabled: true,
      })
      .expect(201);
    assert.equal(created.body.data.userId, owner.repository.tasks[0].userId);

    const listed = await request(owner.app)
      .get('/api/calendar/tasks')
      .set('Authorization', owner.authorization)
      .expect(200);
    assert.equal(listed.body.data.length, 1);

    const updated = await request(owner.app)
      .put(`/api/calendar/tasks/${encodeURIComponent(id)}`)
      .set('Authorization', owner.authorization)
      .send({
        cropId: owner.cropId,
        taskType: 'irrigation',
        dueDate: '2026-08-11T07:00:00.000Z',
        status: 'completed',
        notes: null,
        reminderEnabled: false,
      })
      .expect(200);
    assert.equal(updated.body.data.status, 'completed');

    await request(owner.app)
      .delete(`/api/calendar/tasks/${encodeURIComponent(id)}`)
      .set('Authorization', owner.authorization)
      .expect(200);
    assert.equal(owner.repository.tasks.length, 0);
  });

  it('requires authentication and an owned crop', async () => {
    const owner = await fixture('+919822222222');
    await request(owner.app).get('/api/calendar/tasks').expect(401);
    await request(owner.app)
      .post('/api/calendar/tasks')
      .set('Authorization', owner.authorization)
      .send({
        id: randomUUID(),
        cropId: randomUUID(),
        taskType: 'harvest',
        dueDate: '2026-10-15T07:00:00.000Z',
        status: 'pending',
        notes: null,
        reminderEnabled: true,
      })
      .expect(404);
  });
});

class ApiCompletionProvider implements AiCompletionProvider {
  messages: AiCompletionMessage[] = [];

  async complete(messages: AiCompletionMessage[]) {
    this.messages = messages;
    return {
      text: 'Check soil moisture before irrigating.',
      model: 'test-model',
      usage: { inputTokens: 20, outputTokens: 6, totalTokens: 26 },
    };
  }
}

describe('POST /api/ai/chat', () => {
  it('requires authentication and returns a structured AI response', async () => {
    const authRepository = new MemoryAuthRepository();
    const authService = new AuthService(
      authRepository,
      new DummySmsProvider(),
      testConfig,
    );
    const cropRepository = new MemoryCropRepository();
    const contextService = new AiContextService(
      authRepository,
      cropRepository,
      new EmptyAiContextRepository(),
    );
    const provider = new ApiCompletionProvider();
    const chatApp = createApp(
      authService,
      new CropService(cropRepository),
      contextService,
      undefined,
      new AiChatService(contextService, provider),
    );
    await request(chatApp)
      .post('/api/ai/chat')
      .send({ message: 'Should I irrigate?', language: 'en' })
      .expect(401);

    const sent = await request(chatApp)
      .post('/api/auth/send-otp')
      .send({ phone: '+919833333333' })
      .expect(200);
    const verified = await request(chatApp)
      .post('/api/auth/verify-otp')
      .send({ phone: '+919833333333', otp: sent.body.data.debugOtp })
      .expect(200);
    const response = await request(chatApp)
      .post('/api/ai/chat')
      .set('Authorization', `Bearer ${verified.body.data.accessToken}`)
      .send({ message: 'Should I irrigate?', language: 'en', history: [] })
      .expect(200);

    assert.equal(
      response.body.data.reply,
      'Check soil moisture before irrigating.',
    );
    assert.equal(response.body.data.model, 'test-model');
    assert.equal(response.body.data.usage.totalTokens, 26);
    assert.match(provider.messages[0].content, /English/);
  });
});
