import { createHash, randomUUID } from 'node:crypto';

import jwt, { type JwtPayload } from 'jsonwebtoken';

import { AppError } from '../../common/app-error.js';
import type { AdminConfig } from '../../config/admin-config.js';
import type {
  AdminRepository,
  AdminRole,
  AdminUser,
  PublicAdminUser,
} from '../repositories/admin-repository.js';
import { toPublicAdmin } from '../repositories/admin-repository.js';
import {
  checkPasswordPolicy,
  hashPassword,
  verifyPassword,
} from './password-service.js';

export interface AdminTokenPayload extends JwtPayload {
  sub: string;
  role: AdminRole;
  type: 'admin_access' | 'admin_refresh';
}

export interface AdminSessionResponse {
  admin: PublicAdminUser;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

interface FailedLoginState {
  count: number;
  lockedUntil: number;
}

export class AdminAuthService {
  private readonly failedLogins = new Map<string, FailedLoginState>();

  constructor(
    private readonly repository: AdminRepository,
    readonly config: AdminConfig,
  ) {}

  static normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  async createAdmin(input: {
    email: string;
    name: string;
    password: string;
    role: AdminRole;
  }): Promise<PublicAdminUser> {
    const issues = checkPasswordPolicy(input.password);
    if (issues.length > 0) {
      throw new AppError(400, 'WEAK_PASSWORD', issues[0]!.message);
    }
    const email = AdminAuthService.normalizeEmail(input.email);
    if (await this.repository.findAdminByEmail(email)) {
      throw new AppError(
        409,
        'ADMIN_EXISTS',
        'An admin with that email already exists',
      );
    }
    const admin = await this.repository.createAdmin({
      email,
      name: input.name.trim(),
      role: input.role,
      passwordHash: await hashPassword(input.password),
    });
    return toPublicAdmin(admin);
  }

  async login(
    email: string,
    password: string,
  ): Promise<AdminSessionResponse> {
    const normalized = AdminAuthService.normalizeEmail(email);
    this.assertNotLockedOut(normalized);
    const admin = await this.repository.findAdminByEmail(normalized);
    // Hash-compare even when the account is missing so a wrong email and a
    // wrong password take the same amount of time.
    const matches = admin
      ? await verifyPassword(password, admin.passwordHash)
      : await verifyPassword(password, decoyHash);
    if (!admin || !matches || !admin.isActive) {
      this.recordFailedLogin(normalized);
      throw new AppError(
        401,
        'ADMIN_CREDENTIALS_INVALID',
        'Email or password is incorrect',
      );
    }
    this.failedLogins.delete(normalized);
    await this.repository.recordLogin(admin.id, new Date());
    return this.createSession(admin);
  }

  async refresh(refreshToken: string): Promise<AdminSessionResponse> {
    const payload = this.verify(refreshToken, 'admin_refresh');
    const stored = await this.repository.findSession(hashToken(refreshToken));
    if (
      !stored ||
      stored.revokedAt ||
      stored.expiresAt.getTime() <= Date.now() ||
      stored.adminId !== payload.sub
    ) {
      throw new AppError(
        401,
        'ADMIN_SESSION_INVALID',
        'Session expired, please sign in again',
      );
    }
    const admin = await this.repository.findAdminById(payload.sub);
    if (!admin?.isActive) {
      throw new AppError(
        401,
        'ADMIN_SESSION_INVALID',
        'Session expired, please sign in again',
      );
    }
    await this.repository.revokeSession(stored.id);
    return this.createSession(admin);
  }

  async logout(refreshToken: string): Promise<void> {
    const stored = await this.repository.findSession(hashToken(refreshToken));
    if (stored) await this.repository.revokeSession(stored.id);
  }

  async authenticate(accessToken: string): Promise<AdminUser> {
    const payload = this.verify(accessToken, 'admin_access');
    const admin = await this.repository.findAdminById(payload.sub);
    if (!admin?.isActive) {
      throw new AppError(401, 'ADMIN_SESSION_INVALID', 'Admin is not active');
    }
    return admin;
  }

  async changePassword(
    adminId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const admin = await this.repository.findAdminById(adminId);
    if (!admin) throw new AppError(404, 'ADMIN_NOT_FOUND', 'Admin not found');
    if (!(await verifyPassword(currentPassword, admin.passwordHash))) {
      throw new AppError(
        401,
        'ADMIN_CREDENTIALS_INVALID',
        'Current password is incorrect',
      );
    }
    const issues = checkPasswordPolicy(newPassword);
    if (issues.length > 0) {
      throw new AppError(400, 'WEAK_PASSWORD', issues[0]!.message);
    }
    await this.repository.updatePassword(
      adminId,
      await hashPassword(newPassword),
    );
    // Every other browser holding this account must be signed out.
    await this.repository.revokeAllSessions(adminId);
  }

  async listAdmins(): Promise<PublicAdminUser[]> {
    return (await this.repository.listAdmins()).map(toPublicAdmin);
  }

  async updateAdmin(
    id: string,
    changes: { name?: string; role?: AdminRole; isActive?: boolean },
  ): Promise<PublicAdminUser> {
    const admin = await this.repository.findAdminById(id);
    if (!admin) throw new AppError(404, 'ADMIN_NOT_FOUND', 'Admin not found');
    if (admin.role === 'owner' && (changes.role || changes.isActive === false)) {
      const owners = (await this.repository.listAdmins()).filter(
        (candidate) => candidate.role === 'owner' && candidate.isActive,
      );
      if (owners.length <= 1) {
        throw new AppError(
          409,
          'LAST_OWNER',
          'The last active owner cannot be demoted or deactivated',
        );
      }
    }
    const updated = await this.repository.updateAdmin(id, changes);
    if (changes.isActive === false) {
      await this.repository.revokeAllSessions(id);
    }
    return toPublicAdmin(updated);
  }

  async resetPassword(id: string, newPassword: string): Promise<void> {
    const issues = checkPasswordPolicy(newPassword);
    if (issues.length > 0) {
      throw new AppError(400, 'WEAK_PASSWORD', issues[0]!.message);
    }
    const admin = await this.repository.findAdminById(id);
    if (!admin) throw new AppError(404, 'ADMIN_NOT_FOUND', 'Admin not found');
    await this.repository.updatePassword(id, await hashPassword(newPassword));
    await this.repository.revokeAllSessions(id);
  }

  private async createSession(admin: AdminUser): Promise<AdminSessionResponse> {
    const accessToken = jwt.sign(
      { role: admin.role, type: 'admin_access' },
      this.config.accessTokenSecret,
      {
        subject: admin.id,
        jwtid: randomUUID(),
        expiresIn: this.config.accessTokenTtlSeconds,
      },
    );
    const refreshToken = jwt.sign(
      { role: admin.role, type: 'admin_refresh' },
      this.config.refreshTokenSecret,
      {
        subject: admin.id,
        jwtid: randomUUID(),
        expiresIn: this.config.refreshTokenTtlSeconds,
      },
    );
    await this.repository.createSession(
      admin.id,
      hashToken(refreshToken),
      new Date(Date.now() + this.config.refreshTokenTtlSeconds * 1000),
    );
    return {
      admin: toPublicAdmin(admin),
      accessToken,
      refreshToken,
      expiresIn: this.config.accessTokenTtlSeconds,
    };
  }

  private verify(
    token: string,
    type: AdminTokenPayload['type'],
  ): AdminTokenPayload {
    const secret =
      type === 'admin_access'
        ? this.config.accessTokenSecret
        : this.config.refreshTokenSecret;
    try {
      const decoded = jwt.verify(token, secret);
      if (
        typeof decoded === 'string' ||
        typeof decoded.sub !== 'string' ||
        decoded.type !== type
      ) {
        throw new Error('Invalid admin token payload');
      }
      return decoded as AdminTokenPayload;
    } catch {
      throw new AppError(
        401,
        'ADMIN_SESSION_INVALID',
        'Session expired, please sign in again',
      );
    }
  }

  private assertNotLockedOut(email: string): void {
    const state = this.failedLogins.get(email);
    if (!state || state.lockedUntil <= Date.now()) return;
    throw new AppError(
      429,
      'ADMIN_LOCKED_OUT',
      'Too many failed attempts. Try again later',
    );
  }

  private recordFailedLogin(email: string): void {
    const state = this.failedLogins.get(email) ?? { count: 0, lockedUntil: 0 };
    state.count += 1;
    if (state.count >= this.config.maxFailedLogins) {
      state.lockedUntil = Date.now() + this.config.lockoutSeconds * 1000;
      state.count = 0;
    }
    this.failedLogins.set(email, state);
    if (this.failedLogins.size > 5_000) {
      for (const [key, value] of this.failedLogins) {
        if (value.lockedUntil <= Date.now()) this.failedLogins.delete(key);
      }
    }
  }
}

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

/**
 * A real scrypt hash of a value nobody can supply, so the unknown-email path
 * performs the same work as the known-email path.
 */
const decoyHash =
  'scrypt$65536$8$1$AAAAAAAAAAAAAAAAAAAAAA==$' +
  'ZG9lcy1ub3QtbWF0Y2gtYW55LXBhc3N3b3JkLWV2ZXItYXQtYWxsLXBhZGRpbmc=';
