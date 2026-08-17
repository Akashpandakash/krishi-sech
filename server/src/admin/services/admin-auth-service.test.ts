import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { loadAdminConfig } from '../../config/admin-config.js';
import { AppError } from '../../common/app-error.js';
import { AdminAuthService } from './admin-auth-service.js';
import {
  checkPasswordPolicy,
  hashPassword,
  verifyPassword,
} from './password-service.js';
import { fillSeries } from '../repositories/mongo-admin-analytics-repository.js';
import { InMemoryAdminRepository } from '../../testing/repository-fakes.js';

const strongPassword = 'Monsoon!Field42';

function createService(overrides: Partial<ReturnType<typeof loadAdminConfig>> = {}) {
  const repository = new InMemoryAdminRepository();
  const service = new AdminAuthService(repository, {
    ...loadAdminConfig({ APP_ENV: 'development' } as NodeJS.ProcessEnv),
    ...overrides,
  });
  return { repository, service };
}

describe('admin password hashing', () => {
  it('verifies a password against its own hash', async () => {
    const encoded = await hashPassword(strongPassword);
    assert.ok(encoded.startsWith('scrypt$'));
    assert.equal(await verifyPassword(strongPassword, encoded), true);
    assert.equal(await verifyPassword('Monsoon!Field43', encoded), false);
  });

  it('rejects a hash that has been tampered with', async () => {
    assert.equal(await verifyPassword(strongPassword, 'not-a-hash'), false);
    assert.equal(
      await verifyPassword(strongPassword, 'scrypt$1$2$3$aaaa$bbbb'),
      false,
    );
  });

  it('requires length, mixed case, a digit and a symbol', () => {
    assert.deepEqual(checkPasswordPolicy(strongPassword), []);
    const codes = checkPasswordPolicy('short').map((issue) => issue.code);
    assert.deepEqual(codes, [
      'TOO_SHORT',
      'MISSING_CASE',
      'MISSING_DIGIT',
      'MISSING_SYMBOL',
    ]);
  });
});

describe('admin authentication', () => {
  it('issues a session for correct credentials and rejects wrong ones', async () => {
    const { service } = createService();
    await service.createAdmin({
      email: 'Owner@Example.com',
      name: 'Owner',
      password: strongPassword,
      role: 'owner',
    });

    const session = await service.login('owner@example.com', strongPassword);
    assert.equal(session.admin.email, 'owner@example.com');
    assert.ok(session.accessToken && session.refreshToken);
    assert.equal(
      (await service.authenticate(session.accessToken)).email,
      'owner@example.com',
    );

    await assert.rejects(
      service.login('owner@example.com', 'WrongPassword!9'),
      (error: AppError) => error.code === 'ADMIN_CREDENTIALS_INVALID',
    );
  });

  it('locks an account out after repeated failures', async () => {
    const { service } = createService({ maxFailedLogins: 2 });
    await service.createAdmin({
      email: 'admin@example.com',
      name: 'Admin',
      password: strongPassword,
      role: 'admin',
    });
    for (let attempt = 0; attempt < 2; attempt += 1) {
      await assert.rejects(service.login('admin@example.com', 'nope'));
    }
    await assert.rejects(
      service.login('admin@example.com', strongPassword),
      (error: AppError) => error.code === 'ADMIN_LOCKED_OUT',
    );
  });

  it('rotates the refresh token and invalidates the previous one', async () => {
    const { service } = createService();
    await service.createAdmin({
      email: 'owner@example.com',
      name: 'Owner',
      password: strongPassword,
      role: 'owner',
    });
    const first = await service.login('owner@example.com', strongPassword);
    const second = await service.refresh(first.refreshToken);
    assert.notEqual(first.refreshToken, second.refreshToken);
    await assert.rejects(
      service.refresh(first.refreshToken),
      (error: AppError) => error.code === 'ADMIN_SESSION_INVALID',
    );
  });

  it('refuses to demote the last active owner', async () => {
    const { service } = createService();
    const owner = await service.createAdmin({
      email: 'owner@example.com',
      name: 'Owner',
      password: strongPassword,
      role: 'owner',
    });
    await assert.rejects(
      service.updateAdmin(owner.id, { role: 'analyst' }),
      (error: AppError) => error.code === 'LAST_OWNER',
    );
    await service.createAdmin({
      email: 'second@example.com',
      name: 'Second',
      password: strongPassword,
      role: 'owner',
    });
    assert.equal(
      (await service.updateAdmin(owner.id, { role: 'analyst' })).role,
      'analyst',
    );
  });

  it('signs out every session when the password changes', async () => {
    const { service } = createService();
    const admin = await service.createAdmin({
      email: 'owner@example.com',
      name: 'Owner',
      password: strongPassword,
      role: 'owner',
    });
    const session = await service.login('owner@example.com', strongPassword);
    await service.changePassword(admin.id, strongPassword, 'NewHarvest!2026');
    await assert.rejects(
      service.refresh(session.refreshToken),
      (error: AppError) => error.code === 'ADMIN_SESSION_INVALID',
    );
    assert.ok(await service.login('owner@example.com', 'NewHarvest!2026'));
  });

  it('never exposes the password hash', async () => {
    const { service } = createService();
    const admin = await service.createAdmin({
      email: 'owner@example.com',
      name: 'Owner',
      password: strongPassword,
      role: 'owner',
    });
    assert.equal('passwordHash' in admin, false);
    const [listed] = await service.listAdmins();
    assert.equal('passwordHash' in listed!, false);
  });

  it('rejects a weak password before any account is created', async () => {
    const { service, repository } = createService();
    await assert.rejects(
      service.createAdmin({
        email: 'weak@example.com',
        name: 'Weak',
        password: 'password',
        role: 'admin',
      }),
      (error: AppError) => error.code === 'WEAK_PASSWORD',
    );
    assert.equal(await repository.countAdmins(), 0);
  });
});

describe('growth series', () => {
  it('fills missing days with zero and keeps the requested length', () => {
    const now = new Date('2026-08-14T12:00:00+05:30');
    const series = fillSeries([{ _id: '2026-08-14', value: 5 }], 3, now);
    assert.deepEqual(series, [
      { date: '2026-08-12', value: 0 },
      { date: '2026-08-13', value: 0 },
      { date: '2026-08-14', value: 5 },
    ]);
  });
});
