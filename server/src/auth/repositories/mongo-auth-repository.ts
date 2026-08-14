import { randomUUID } from 'node:crypto';

import type {
  MongoDatabase,
  OtpCodeDocument,
  RefreshTokenDocument,
  UserDocument,
} from '../../database/mongo-database.js';
import type {
  AuthOtp,
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
} from './auth-repository.js';

export function toAuthUser(document: UserDocument): AuthUser {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

function toAuthOtp(document: OtpCodeDocument): AuthOtp {
  return {
    id: document._id,
    phone: document.phone,
    codeHash: document.codeHash,
    expiresAt: document.expiresAt,
    attempts: document.attempts,
    consumedAt: document.consumedAt,
  };
}

function toAuthRefreshToken(document: RefreshTokenDocument): AuthRefreshToken {
  return {
    id: document._id,
    userId: document.userId,
    tokenHash: document.tokenHash,
    expiresAt: document.expiresAt,
    revokedAt: document.revokedAt,
  };
}

export class MongoAuthRepository implements AuthRepository {
  constructor(private readonly database: MongoDatabase) {}

  async createOtp(phone: string, codeHash: string, expiresAt: Date) {
    await this.database.otpCodes.insertOne({
      _id: randomUUID(),
      phone,
      codeHash,
      expiresAt,
      attempts: 0,
      consumedAt: null,
      createdAt: new Date(),
    });
  }

  countOtpRequests(phone: string, since: Date): Promise<number> {
    return this.database.otpCodes.countDocuments({
      phone,
      createdAt: { $gte: since },
    });
  }

  async findLatestOtp(phone: string): Promise<AuthOtp | null> {
    const document = await this.database.otpCodes.findOne(
      { phone, consumedAt: null },
      { sort: { createdAt: -1 } },
    );
    return document ? toAuthOtp(document) : null;
  }

  async incrementOtpAttempts(id: string) {
    await this.database.otpCodes.updateOne(
      { _id: id },
      { $inc: { attempts: 1 } },
    );
  }

  async consumeOtp(id: string) {
    await this.database.otpCodes.updateOne(
      { _id: id },
      { $set: { consumedAt: new Date() } },
    );
  }

  async findUserByPhone(phone: string): Promise<AuthUser | null> {
    const document = await this.database.users.findOne({ phone });
    return document ? toAuthUser(document) : null;
  }

  async findUserById(id: string): Promise<AuthUser | null> {
    const document = await this.database.users.findOne({ _id: id });
    return document ? toAuthUser(document) : null;
  }

  async createUser(phone: string): Promise<AuthUser> {
    const now = new Date();
    const document: UserDocument = {
      _id: randomUUID(),
      phone,
      name: null,
      preferredLanguage: 'bn',
      profilePhotoUrl: null,
      state: null,
      district: null,
      village: null,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };
    await this.database.users.insertOne(document);
    return toAuthUser(document);
  }

  async ensureDemoUser(phone: string): Promise<AuthUser> {
    const now = new Date();
    const document = await this.database.users.findOneAndUpdate(
      { phone },
      {
        $set: {
          name: 'Demo Farmer',
          preferredLanguage: 'en',
          isActive: true,
          updatedAt: now,
        },
        $setOnInsert: {
          _id: randomUUID(),
          profilePhotoUrl: null,
          state: null,
          district: null,
          village: null,
          createdAt: now,
        },
      },
      { upsert: true, returnDocument: 'after' },
    );
    if (!document) throw new Error('Failed to upsert demo user');
    return toAuthUser(document);
  }

  async createRefreshToken(userId: string, tokenHash: string, expiresAt: Date) {
    await this.database.refreshTokens.insertOne({
      _id: randomUUID(),
      userId,
      tokenHash,
      expiresAt,
      revokedAt: null,
      createdAt: new Date(),
    });
  }

  async findRefreshToken(tokenHash: string): Promise<AuthRefreshToken | null> {
    const document = await this.database.refreshTokens.findOne({ tokenHash });
    return document ? toAuthRefreshToken(document) : null;
  }

  async rotateRefreshToken(
    currentTokenId: string,
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    await this.database.refreshTokens.updateOne(
      { _id: currentTokenId, revokedAt: null },
      { $set: { revokedAt: new Date() } },
    );
    await this.createRefreshToken(userId, tokenHash, expiresAt);
  }

  async revokeRefreshToken(id: string) {
    await this.database.refreshTokens.updateOne(
      { _id: id, revokedAt: null },
      { $set: { revokedAt: new Date() } },
    );
  }
}
