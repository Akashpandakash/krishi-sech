import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { DummySmsProvider } from '../../auth/providers/dummy-sms-provider.js';
import { AuthService } from '../../auth/services/auth-service.js';
import type { AppError } from '../../common/app-error.js';
import type { AuthConfig } from '../../config/auth-config.js';
import { AccountDeletionService } from './account-deletion-service.js';
import { InMemoryAccountDeletionRepository, InMemoryAuthRepository, InMemoryCalendarTaskRepository, InMemoryCropRepository } from '../../testing/repository-fakes.js';

const authConfig: AuthConfig = {
  accessTokenSecret: 'test-access-secret',
  refreshTokenSecret: 'test-refresh-secret',
  otpHashSecret: 'test-otp-secret',
  accessTokenTtlSeconds: 900,
  refreshTokenTtlSeconds: 3600,
  otpTtlSeconds: 300,
  otpRequestWindowSeconds: 600,
  otpMaxRequestsPerWindow: 5,
  exposeDebugOtp: true,
  demoLoginEnabled: false,
};

const phone = '+919876543210';

function createHarness() {
  const authRepository = new InMemoryAuthRepository();
  const cropRepository = new InMemoryCropRepository();
  const calendarRepository = new InMemoryCalendarTaskRepository();
  const authService = new AuthService(
    authRepository,
    new DummySmsProvider(),
    authConfig,
  );
  const service = new AccountDeletionService(
    authService,
    new InMemoryAccountDeletionRepository(
      authRepository,
      cropRepository,
      calendarRepository,
    ),
  );
  return {
    authRepository,
    cropRepository,
    calendarRepository,
    authService,
    service,
  };
}

async function seedAccount(harness: ReturnType<typeof createHarness>) {
  const { debugOtp } = await harness.authService.sendOtp(phone);
  const session = await harness.authService.verifyOtp(phone, debugOtp!);
  await harness.cropRepository.create(session.user.id, {
    cropName: 'Rice',
    variety: 'Swarna',
    sowingDate: new Date(),
    growthStage: 'vegetative',
    landArea: 2,
    landUnit: 'acre',
    soilType: 'alluvial',
    irrigationMethod: 'flood',
    expectedHarvestDate: null,
    healthStatus: 'healthy',
    notes: null,
  });
  return session.user.id;
}

describe('account deletion', () => {
  it('erases the account and its crops once the OTP is confirmed', async () => {
    const harness = createHarness();
    const userId = await seedAccount(harness);

    const { debugOtp } = await harness.authService.sendOtp(phone);
    const outcome = await harness.service.confirmWithOtp(phone, debugOtp!);

    assert.equal(outcome.userId, userId);
    assert.equal(outcome.summary.crops, 1);
    assert.equal(await harness.authRepository.findUserById(userId), null);
    assert.equal(await harness.authRepository.findUserByPhone(phone), null);
    assert.deepEqual(await harness.cropRepository.findAllByUser(userId), []);
  });

  it('rejects a wrong code and leaves the account intact', async () => {
    const harness = createHarness();
    const userId = await seedAccount(harness);
    await harness.authService.sendOtp(phone);

    await assert.rejects(
      harness.service.confirmWithOtp(phone, '000000'),
      (error: AppError) => error.code === 'OTP_INVALID',
    );
    assert.ok(await harness.authRepository.findUserById(userId));
  });

  it('reports a number with no account rather than reporting success', async () => {
    const harness = createHarness();
    const unknown = '+919000000001';
    const { debugOtp } = await harness.authService.sendOtp(unknown);

    await assert.rejects(
      harness.service.confirmWithOtp(unknown, debugOtp!),
      (error: AppError) => error.code === 'ACCOUNT_NOT_FOUND',
    );
  });

  it('deletes an authenticated account from inside the app', async () => {
    const harness = createHarness();
    const userId = await seedAccount(harness);

    const outcome = await harness.service.deleteAuthenticated(userId, 'moving');

    assert.equal(outcome.summary.crops, 1);
    assert.equal(await harness.authRepository.findUserById(userId), null);
  });

  it('consumes the code so it cannot delete twice', async () => {
    const harness = createHarness();
    await seedAccount(harness);
    const { debugOtp } = await harness.authService.sendOtp(phone);

    await harness.service.confirmWithOtp(phone, debugOtp!);
    await assert.rejects(
      harness.service.confirmWithOtp(phone, debugOtp!),
      (error: AppError) => error.code === 'OTP_EXPIRED',
    );
  });
});
