import { randomUUID } from 'node:crypto';

import type {
  AdminSessionDocument,
  AdminUserDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  AdminRepository,
  AdminRole,
  AdminSession,
  AdminUser,
  AdminUserInput,
} from './admin-repository.js';

function toAdminUser(document: AdminUserDocument): AdminUser {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

function toAdminSession(document: AdminSessionDocument): AdminSession {
  return {
    id: document._id,
    adminId: document.adminId,
    tokenHash: document.tokenHash,
    expiresAt: document.expiresAt,
    revokedAt: document.revokedAt,
  };
}

export class MongoAdminRepository implements AdminRepository {
  constructor(private readonly database: MongoDatabase) {}

  async createAdmin(input: AdminUserInput): Promise<AdminUser> {
    const now = new Date();
    const document: AdminUserDocument = {
      _id: randomUUID(),
      email: input.email,
      name: input.name,
      role: input.role,
      passwordHash: input.passwordHash,
      isActive: true,
      lastLoginAt: null,
      createdAt: now,
      updatedAt: now,
    };
    await this.database.adminUsers.insertOne(document);
    return toAdminUser(document);
  }

  async findAdminByEmail(email: string): Promise<AdminUser | null> {
    const document = await this.database.adminUsers.findOne({ email }).lean();
    return document ? toAdminUser(document) : null;
  }

  async findAdminById(id: string): Promise<AdminUser | null> {
    const document = await this.database.adminUsers.findOne({ _id: id }).lean();
    return document ? toAdminUser(document) : null;
  }

  async listAdmins(): Promise<AdminUser[]> {
    const documents = await this.database.adminUsers
      .find({})
      .sort({ createdAt: 1 })
      .lean();
    return documents.map(toAdminUser);
  }

  countAdmins(): Promise<number> {
    return this.database.adminUsers.countDocuments({});
  }

  async updatePassword(id: string, passwordHash: string): Promise<void> {
    await this.database.adminUsers.updateOne(
      { _id: id },
      { $set: { passwordHash, updatedAt: new Date() } },
    );
  }

  async updateAdmin(
    id: string,
    changes: { name?: string; role?: AdminRole; isActive?: boolean },
  ): Promise<AdminUser> {
    const document = await this.database.adminUsers.findOneAndUpdate(
      { _id: id },
      { $set: { ...changes, updatedAt: new Date() } },
      { returnDocument: 'after' },
    ).lean();
    if (!document) throw new Error('Admin not found');
    return toAdminUser(document);
  }

  async recordLogin(id: string, at: Date): Promise<void> {
    await this.database.adminUsers.updateOne(
      { _id: id },
      { $set: { lastLoginAt: at, updatedAt: at } },
    );
  }

  async createSession(adminId: string, tokenHash: string, expiresAt: Date) {
    await this.database.adminSessions.insertOne({
      _id: randomUUID(),
      adminId,
      tokenHash,
      expiresAt,
      revokedAt: null,
      createdAt: new Date(),
    });
  }

  async findSession(tokenHash: string): Promise<AdminSession | null> {
    const document = await this.database.adminSessions.findOne({ tokenHash }).lean();
    return document ? toAdminSession(document) : null;
  }

  async revokeSession(id: string): Promise<void> {
    await this.database.adminSessions.updateOne(
      { _id: id, revokedAt: null },
      { $set: { revokedAt: new Date() } },
    );
  }

  async revokeAllSessions(adminId: string): Promise<void> {
    await this.database.adminSessions.updateMany(
      { adminId, revokedAt: null },
      { $set: { revokedAt: new Date() } },
    );
  }
}
