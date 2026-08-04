import { PrismaClient } from '@prisma/client';

import type {
  AuthOtp,
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
} from './auth-repository.js';

export class PrismaAuthRepository implements AuthRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async createOtp(phone: string, codeHash: string, expiresAt: Date) {
    await this.prisma.otpCode.create({ data: { phone, codeHash, expiresAt } });
  }

  countOtpRequests(phone: string, since: Date): Promise<number> {
    return this.prisma.otpCode.count({
      where: { phone, createdAt: { gte: since } },
    });
  }

  findLatestOtp(phone: string): Promise<AuthOtp | null> {
    return this.prisma.otpCode.findFirst({
      where: { phone, consumedAt: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async incrementOtpAttempts(id: string) {
    await this.prisma.otpCode.update({
      where: { id },
      data: { attempts: { increment: 1 } },
    });
  }

  async consumeOtp(id: string) {
    await this.prisma.otpCode.update({
      where: { id },
      data: { consumedAt: new Date() },
    });
  }

  findUserByPhone(phone: string): Promise<AuthUser | null> {
    return this.prisma.user.findUnique({ where: { phone } });
  }

  findUserById(id: string): Promise<AuthUser | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  createUser(phone: string): Promise<AuthUser> {
    return this.prisma.user.create({ data: { phone } });
  }

  ensureDemoUser(phone: string): Promise<AuthUser> {
    return this.prisma.user.upsert({
      where: { phone },
      create: {
        phone,
        name: 'Demo Farmer',
        preferredLanguage: 'en',
        isActive: true,
      },
      update: {
        name: 'Demo Farmer',
        preferredLanguage: 'en',
        isActive: true,
      },
    });
  }

  async createRefreshToken(
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    await this.prisma.refreshToken.create({
      data: { userId, tokenHash, expiresAt },
    });
  }

  findRefreshToken(tokenHash: string): Promise<AuthRefreshToken | null> {
    return this.prisma.refreshToken.findUnique({ where: { tokenHash } });
  }

  async rotateRefreshToken(
    currentTokenId: string,
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    await this.prisma.$transaction([
      this.prisma.refreshToken.update({
        where: { id: currentTokenId },
        data: { revokedAt: new Date() },
      }),
      this.prisma.refreshToken.create({
        data: { userId, tokenHash, expiresAt },
      }),
    ]);
  }

  async revokeRefreshToken(id: string) {
    await this.prisma.refreshToken.updateMany({
      where: { id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}
