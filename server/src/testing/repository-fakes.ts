/**
 * Test-only repository fakes.
 *
 * These used to live beside the Mongo implementations and doubled as a
 * no-database fallback for the running server. That fallback is gone — the
 * server now requires MONGODB_URI — because a process that boots without a
 * database served confidently wrong numbers rather than failing loudly.
 *
 * They survive here for one reason: the suite runs in ~3 seconds with no
 * database, no container and no cleanup between tests. Nothing outside a
 * *.test.ts file may import this module.
 *
 * They are fakes, not mirrors of production behaviour. Where a query cannot be
 * answered in memory it returns an empty result, so never use them to reason
 * about what the real repositories do.
 */
import { randomUUID } from 'node:crypto';

import type {
  AuthOtp,
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
  GoogleUserInput,
} from '../auth/repositories/auth-repository.js';
import type {
  CalendarTaskInput,
  CalendarTaskRecord,
  CalendarTaskRepository,
} from '../calendar/repositories/calendar-task-repository.js';
import type {
  CropInput,
  CropRecord,
  CropRepository,
} from '../crops/repositories/crop-repository.js';
import type {
  FarmProfile,
  FarmProfileInput,
  ProfileRepository,
  UserProfileUpdate,
} from '../profile/repositories/profile-repository.js';
import type {
  AdminRepository,
  AdminSession,
  AdminUser,
  AdminUserInput,
  AdminRole,
} from '../admin/repositories/admin-repository.js';
import type {
  Broadcast,
  BroadcastAudience,
  BroadcastInput,
  BroadcastRepository,
  BroadcastSendResult,
  BroadcastStatus,
  InboxItem,
} from '../broadcasts/repositories/broadcast-repository.js';
import type {
  AccountDeletionRepository,
  AccountDeletionSummary,
} from '../account/repositories/account-deletion-repository.js';
import { emptyDeletionSummary } from '../account/repositories/account-deletion-repository.js';

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

  async findUserByGoogleId(googleId: string) {
    return this.users.find((user) => user.googleId === googleId) ?? null;
  }

  async createGoogleUser(input: GoogleUserInput) {
    const now = new Date();
    const user: AuthUser = {
      id: randomUUID(),
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
      existing.updatedAt = new Date();
      return existing;
    }
    const user = await this.createUser(phone);
    user.name = 'Demo Farmer';
    user.preferredLanguage = 'en';
    return user;
  }

  async deleteUser(id: string) {
    const index = this.users.findIndex((user) => user.id === id);
    if (index >= 0) this.users.splice(index, 1);
    for (let cursor = this.refreshTokens.length - 1; cursor >= 0; cursor -= 1) {
      if (this.refreshTokens[cursor]!.userId === id) {
        this.refreshTokens.splice(cursor, 1);
      }
    }
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

export class InMemoryCropRepository implements CropRepository {
  private readonly crops = new Map<string, CropRecord>();

  async create(
    userId: string,
    input: CropInput,
    id = randomUUID(),
  ): Promise<CropRecord> {
    const existing = this.crops.get(id);
    if (existing) {
      if (existing.userId === userId) return existing;
      throw new Error('Crop idempotency key already exists');
    }
    const now = new Date();
    const crop: CropRecord = {
      ...input,
      id,
      userId,
      createdAt: now,
      updatedAt: now,
    };
    this.crops.set(crop.id, crop);
    return crop;
  }

  async findAllByUser(userId: string): Promise<CropRecord[]> {
    return [...this.crops.values()]
      .filter((crop) => crop.userId === userId)
      .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime());
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<CropRecord | null> {
    const crop = this.crops.get(id);
    return crop?.userId === userId ? crop : null;
  }

  async update(
    id: string,
    userId: string,
    input: CropInput,
  ): Promise<CropRecord> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) {
      throw new Error('Crop not found');
    }
    const crop = {...existing, ...input, updatedAt: new Date()};
    this.crops.set(id, crop);
    return crop;
  }

  async delete(id: string, userId: string): Promise<void> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) {
      throw new Error('Crop not found');
    }
    this.crops.delete(id);
  }
}

export class InMemoryCalendarTaskRepository implements CalendarTaskRepository {
  private readonly tasks = new Map<string, CalendarTaskRecord>();

  async create(
    userId: string,
    input: CalendarTaskInput,
  ): Promise<CalendarTaskRecord> {
    const now = new Date();
    const task = { ...input, userId, createdAt: now, updatedAt: now };
    this.tasks.set(task.id, task);
    return task;
  }

  async findAllByUser(userId: string): Promise<CalendarTaskRecord[]> {
    return [...this.tasks.values()]
      .filter((task) => task.userId === userId)
      .sort((left, right) => left.dueDate.getTime() - right.dueDate.getTime());
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<CalendarTaskRecord | null> {
    const task = this.tasks.get(id);
    return task?.userId === userId ? task : null;
  }

  async update(
    id: string,
    userId: string,
    input: Omit<CalendarTaskInput, "id">,
  ): Promise<CalendarTaskRecord> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) throw new Error("Calendar task not found");
    const task = { ...existing, ...input, updatedAt: new Date() };
    this.tasks.set(id, task);
    return task;
  }

  async delete(id: string, userId: string): Promise<void> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) throw new Error("Calendar task not found");
    this.tasks.delete(id);
  }
}

export class InMemoryProfileRepository implements ProfileRepository {
  private readonly farms = new Map<string, FarmProfile>();
  constructor(private readonly auth: AuthRepository) {}
  getUserProfile(userId: string) {
    return this.auth.findUserById(userId);
  }
  async updateUserProfile(userId: string, input: UserProfileUpdate) {
    const user = await this.auth.findUserById(userId);
    if (!user) throw new Error('User not found');
    Object.assign(user, input, { updatedAt: new Date() });
    return user as AuthUser;
  }
  async getFarmProfile(userId: string) {
    return this.farms.get(userId) ?? null;
  }
  async upsertFarmProfile(userId: string, input: FarmProfileInput) {
    const now = new Date();
    const current = this.farms.get(userId);
    const farm: FarmProfile = {
      id: current?.id ?? `farm-${userId}`,
      userId,
      ...input,
      coarseLocation: input.coarseLocation ?? null,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    };
    this.farms.set(userId, farm);
    return farm;
  }
}

export class InMemoryAdminRepository implements AdminRepository {
  private readonly admins = new Map<string, AdminUser>();
  private readonly sessions = new Map<string, AdminSession>();

  async createAdmin(input: AdminUserInput): Promise<AdminUser> {
    const now = new Date();
    const admin: AdminUser = {
      id: randomUUID(),
      email: input.email,
      name: input.name,
      role: input.role,
      passwordHash: input.passwordHash,
      isActive: true,
      lastLoginAt: null,
      createdAt: now,
      updatedAt: now,
    };
    if (await this.findAdminByEmail(admin.email)) {
      throw Object.assign(new Error('Duplicate admin email'), { code: 11000 });
    }
    this.admins.set(admin.id, admin);
    return { ...admin };
  }

  async findAdminByEmail(email: string): Promise<AdminUser | null> {
    for (const admin of this.admins.values()) {
      if (admin.email === email) return { ...admin };
    }
    return null;
  }

  async findAdminById(id: string): Promise<AdminUser | null> {
    const admin = this.admins.get(id);
    return admin ? { ...admin } : null;
  }

  async listAdmins(): Promise<AdminUser[]> {
    return [...this.admins.values()]
      .sort((left, right) => left.createdAt.getTime() - right.createdAt.getTime())
      .map((admin) => ({ ...admin }));
  }

  async countAdmins(): Promise<number> {
    return this.admins.size;
  }

  async updatePassword(id: string, passwordHash: string): Promise<void> {
    const admin = this.admins.get(id);
    if (admin) Object.assign(admin, { passwordHash, updatedAt: new Date() });
  }

  async updateAdmin(
    id: string,
    changes: { name?: string; role?: AdminRole; isActive?: boolean },
  ): Promise<AdminUser> {
    const admin = this.admins.get(id);
    if (!admin) throw new Error('Admin not found');
    Object.assign(admin, changes, { updatedAt: new Date() });
    return { ...admin };
  }

  async recordLogin(id: string, at: Date): Promise<void> {
    const admin = this.admins.get(id);
    if (admin) Object.assign(admin, { lastLoginAt: at, updatedAt: at });
  }

  async createSession(adminId: string, tokenHash: string, expiresAt: Date) {
    const id = randomUUID();
    this.sessions.set(id, {
      id,
      adminId,
      tokenHash,
      expiresAt,
      revokedAt: null,
    });
  }

  async findSession(tokenHash: string): Promise<AdminSession | null> {
    for (const session of this.sessions.values()) {
      if (session.tokenHash === tokenHash) return { ...session };
    }
    return null;
  }

  async revokeSession(id: string): Promise<void> {
    const session = this.sessions.get(id);
    if (session && !session.revokedAt) session.revokedAt = new Date();
  }

  async revokeAllSessions(adminId: string): Promise<void> {
    for (const session of this.sessions.values()) {
      if (session.adminId === adminId && !session.revokedAt) {
        session.revokedAt = new Date();
      }
    }
  }
}

/**
 * Used when `MONGODB_URI` is unset. Audience filters cannot be resolved
 * without the user collection, so every sent broadcast reaches every inbox and
 * no push tokens are returned.
 */
export class InMemoryBroadcastRepository implements BroadcastRepository {
  private readonly broadcasts = new Map<string, Broadcast>();
  private readonly receipts = new Set<string>();

  async create(
    input: BroadcastInput,
    status: BroadcastStatus,
  ): Promise<Broadcast> {
    const now = new Date();
    const broadcast: Broadcast = {
      id: randomUUID(),
      ...input,
      status,
      sentAt: null,
      audienceCount: 0,
      deliveredCount: 0,
      failedCount: 0,
      failureReason: null,
      createdAt: now,
      updatedAt: now,
    };
    this.broadcasts.set(broadcast.id, broadcast);
    return { ...broadcast };
  }

  async findById(id: string): Promise<Broadcast | null> {
    const broadcast = this.broadcasts.get(id);
    return broadcast ? { ...broadcast } : null;
  }

  async list(limit: number, status?: BroadcastStatus): Promise<Broadcast[]> {
    return [...this.broadcasts.values()]
      .filter((broadcast) => !status || broadcast.status === status)
      .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())
      .slice(0, limit)
      .map((broadcast) => ({ ...broadcast }));
  }

  async updateStatus(
    id: string,
    status: BroadcastStatus,
    changes: Partial<BroadcastSendResult> & { sentAt?: Date } = {},
  ): Promise<Broadcast> {
    const broadcast = this.broadcasts.get(id);
    if (!broadcast) throw new Error('Broadcast not found');
    Object.assign(broadcast, changes, { status, updatedAt: new Date() });
    return { ...broadcast };
  }

  async delete(id: string): Promise<void> {
    this.broadcasts.delete(id);
    for (const key of this.receipts) {
      if (key.startsWith(`${id}:`)) this.receipts.delete(key);
    }
  }

  async findDueScheduled(now: Date): Promise<Broadcast[]> {
    return [...this.broadcasts.values()]
      .filter(
        (broadcast) =>
          broadcast.status === 'scheduled' &&
          broadcast.scheduledAt !== null &&
          broadcast.scheduledAt.getTime() <= now.getTime(),
      )
      .map((broadcast) => ({ ...broadcast }));
  }

  async audienceDeviceTokens(_audience: BroadcastAudience): Promise<string[]> {
    return [];
  }

  async inboxForUser(userId: string, limit: number): Promise<InboxItem[]> {
    return [...this.broadcasts.values()]
      .filter((broadcast) => broadcast.status === 'sent')
      .sort(
        (left, right) =>
          (right.sentAt?.getTime() ?? 0) - (left.sentAt?.getTime() ?? 0),
      )
      .slice(0, limit)
      .map((broadcast) => ({
        id: broadcast.id,
        title: broadcast.title,
        body: broadcast.body,
        category: broadcast.category,
        deepLink: broadcast.deepLink,
        sentAt: broadcast.sentAt ?? broadcast.createdAt,
        read: this.receipts.has(`${broadcast.id}:${userId}`),
      }));
  }

  async markRead(broadcastId: string, userId: string): Promise<void> {
    this.receipts.add(`${broadcastId}:${userId}`);
  }

  async countUnread(userId: string): Promise<number> {
    return [...this.broadcasts.values()].filter(
      (broadcast) =>
        broadcast.status === 'sent' &&
        !this.receipts.has(`${broadcast.id}:${userId}`),
    ).length;
  }

  async removeTokens(_tokens: string[]): Promise<void> {}
}

/**
 * Used when `MONGODB_URI` is unset. Only the collections that exist in memory
 * can be cleared; the rest of the counts stay zero.
 */
export class InMemoryAccountDeletionRepository
  implements AccountDeletionRepository {
  constructor(
    private readonly auth: AuthRepository,
    private readonly crops: CropRepository,
    private readonly calendarTasks: CalendarTaskRepository,
  ) { }

  async purge(userId: string): Promise<AccountDeletionSummary> {
    const [crops, tasks] = await Promise.all([
      this.crops.findAllByUser(userId),
      this.calendarTasks.findAllByUser(userId),
    ]);
    for (const task of tasks) await this.calendarTasks.delete(task.id, userId);
    for (const crop of crops) await this.crops.delete(crop.id, userId);
    await this.auth.deleteUser(userId);
    return {
      ...emptyDeletionSummary,
      crops: crops.length,
      calendarTasks: tasks.length,
    };
  }
}
