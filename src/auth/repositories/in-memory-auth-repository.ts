import { randomUUID } from 'node:crypto';

import type {
  AuthOtp,
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
} from './auth-repository.js';

type StoredOtp = AuthOtp & { createdAt: Date };

export class InMemoryAuthRepository implements AuthRepository {
  private readonly users: AuthUser[] = [];
  private readonly otps: StoredOtp[] = [];
  private readonly refreshTokens: AuthRefreshToken[] = [];

  async createOtp(phone: string, codeHash: string, expiresAt: Date) {
    this.otps.push({
      id: randomUUID(),
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
    return [...this.otps]
      .reverse()
      .find((otp) => otp.phone === phone && otp.consumedAt === null) ?? null;
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

  async createUser(phone: string) {
    const now = new Date();
    const user: AuthUser = {
      id: randomUUID(),
      phone,
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
      existing.updatedAt = new Date();
      return existing;
    }
    const user = await this.createUser(phone);
    user.name = 'Demo Farmer';
    user.preferredLanguage = 'en';
    return user;
  }

  async createRefreshToken(
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    this.refreshTokens.push({
      id: randomUUID(),
      userId,
      tokenHash,
      expiresAt,
      revokedAt: null,
    });
  }

  async findRefreshToken(tokenHash: string) {
    return this.refreshTokens.find((token) => token.tokenHash === tokenHash) ?? null;
  }

  async rotateRefreshToken(
    currentTokenId: string,
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    const current = this.refreshTokens.find((token) => token.id === currentTokenId);
    if (current) current.revokedAt = new Date();
    await this.createRefreshToken(userId, tokenHash, expiresAt);
  }

  async revokeRefreshToken(id: string) {
    const token = this.refreshTokens.find((item) => item.id === id);
    if (token && token.revokedAt === null) token.revokedAt = new Date();
  }
}
