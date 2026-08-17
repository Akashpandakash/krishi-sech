import mongoose, { Schema, type Connection, type Model } from 'mongoose';

import type {
  AuthOtp,
  AuthRefreshToken,
  AuthUser,
} from '../auth/repositories/auth-repository.js';
import type {
  AdminSession,
  AdminUser,
} from '../admin/repositories/admin-repository.js';
import type { AuditLogEntry } from '../admin/repositories/audit-log-repository.js';
import type { CalendarTaskRecord } from '../calendar/repositories/calendar-task-repository.js';
import type {
  Broadcast,
  BroadcastReceipt,
} from '../broadcasts/repositories/broadcast-repository.js';
import type { CropRecord } from '../crops/repositories/crop-repository.js';
import type { DeviceRecord } from '../devices/repositories/device-repository.js';
import type { FertilizerRecommendationRecord } from '../fertilizer/repositories/fertilizer-recommendation-repository.js';
import type { IrrigationRecommendationRecord } from '../irrigation/repositories/irrigation-recommendation-repository.js';
import type {
  MandiPriceRecord,
  MandiPriceSource,
} from '../mandi/repositories/mandi-price-repository.js';
import type { MarketProductRecord } from '../market/repositories/market-product-repository.js';
import type { FarmProfile } from '../profile/repositories/profile-repository.js';

/** Domain records carry `id`; MongoDB stores that identity in `_id`. */
type Document<T extends { id: string }> = Omit<T, 'id'> & { _id: string };

/**
 * The account document also mirrors the most recent FCM token seen for it.
 *
 * This is a CONVENIENCE MIRROR, not the delivery source of truth: one account
 * can have several handsets, and a scalar field can only hold one, so
 * broadcasts resolve their audience from the `devices` collection. The mirror
 * exists so an operator can see at a glance whether an account is reachable.
 */
export type UserDocument = Document<AuthUser> & {
  fcmToken?: string | null;
  fcmTokenUpdatedAt?: Date | null;
};
export type FarmProfileDocument = Document<FarmProfile>;
export type CropDocument = Document<CropRecord>;
export type CalendarTaskDocument = Document<CalendarTaskRecord>;
export type FertilizerRecommendationDocument =
  Document<FertilizerRecommendationRecord>;
export type IrrigationRecommendationDocument =
  Document<IrrigationRecommendationRecord>;
export type DeviceDocument = Document<DeviceRecord>;
/** `source` is optional: rows written before admin editing landed have none. */
export type MandiPriceDocument = Omit<Document<MandiPriceRecord>, 'source'> & {
  source?: MandiPriceSource;
};
export type MarketProductDocument = Document<MarketProductRecord>;
export type AdminUserDocument = Document<AdminUser>;
export type AdminSessionDocument = Document<AdminSession> & {
  createdAt: Date;
};
export type AdminAuditLogDocument = Document<AuditLogEntry>;
export type OtpCodeDocument = Document<AuthOtp> & { createdAt: Date };
export type RefreshTokenDocument = Document<AuthRefreshToken> & {
  createdAt: Date;
};
export type BroadcastDocument = Document<Broadcast>;
export type BroadcastReceiptDocument = Document<BroadcastReceipt>;

export const defaultDatabaseName = 'krishi_sech';

/**
 * Shared schema options.
 *
 * `_id` is an application-generated UUID string, never a Mongo ObjectId, so
 * every schema declares it explicitly — Mongoose would otherwise cast the
 * UUIDs and break every existing document.
 *
 * `strict: false` is deliberate. Several record types compose from other
 * interfaces (a fertilizer recommendation carries a whole nested output
 * object), and a strict schema silently drops any path it does not declare.
 * The repositories and zod already validate at the edges; the schemas here
 * exist for typing, indexes and middleware, not to gate writes.
 */
const baseOptions = {
  _id: false as const,
  versionKey: false as const,
  strict: false as const,
  minimize: false as const,
  timestamps: false as const,
};

function collectionSchema(
  paths: Record<string, unknown>,
): Schema {
  return new Schema(
    { _id: { type: String, required: true }, ...paths },
    baseOptions,
  );
}

const userSchema = collectionSchema({
  phone: { type: String, default: null },
  email: { type: String, default: null },
  googleId: { type: String, default: null },
  name: { type: String, default: null },
  preferredLanguage: String,
  profilePhotoUrl: { type: String, default: null },
  state: { type: String, default: null },
  district: { type: String, default: null },
  village: { type: String, default: null },
  isActive: Boolean,
  // Mirror of the newest device token; `devices` remains authoritative.
  fcmToken: { type: String, default: null },
  fcmTokenUpdatedAt: { type: Date, default: null },
  createdAt: Date,
  updatedAt: Date,
});
// Partial: Google accounts store a null phone, and a plain unique index would
// reject every account after the first one.
userSchema.index(
  { phone: 1 },
  { unique: true, partialFilterExpression: { phone: { $type: 'string' } } },
);
userSchema.index(
  { googleId: 1 },
  { unique: true, partialFilterExpression: { googleId: { $type: 'string' } } },
);

const farmProfileSchema = collectionSchema({
  userId: String,
  farmName: String,
  farmerType: String,
  totalLandArea: Number,
  landUnit: String,
  soilType: String,
  irrigationSource: String,
  mainCrops: [String],
  coarseLocation: { type: String, default: null },
  createdAt: Date,
  updatedAt: Date,
});
farmProfileSchema.index({ userId: 1 }, { unique: true });

const cropSchema = collectionSchema({
  userId: String,
  cropName: String,
  createdAt: Date,
  updatedAt: Date,
});
cropSchema.index({ userId: 1, createdAt: -1 });

const calendarTaskSchema = collectionSchema({
  userId: String,
  cropId: String,
  taskType: String,
  status: String,
  dueDate: Date,
  createdAt: Date,
  updatedAt: Date,
});
calendarTaskSchema.index({ userId: 1, dueDate: 1 });
calendarTaskSchema.index({ cropId: 1 });

const fertilizerSchema = collectionSchema({
  userId: String,
  cropId: String,
  language: String,
  engineVersion: String,
  createdAt: Date,
});
fertilizerSchema.index({ userId: 1, cropId: 1, createdAt: -1 });

const irrigationSchema = collectionSchema({
  userId: String,
  cropId: String,
  language: String,
  landType: String,
  engineVersion: String,
  createdAt: Date,
});
irrigationSchema.index({ userId: 1, cropId: 1, createdAt: -1 });

const deviceSchema = collectionSchema({
  userId: String,
  token: String,
  platform: String,
  createdAt: Date,
  updatedAt: Date,
});
deviceSchema.index({ token: 1 }, { unique: true });
deviceSchema.index({ userId: 1 });

// Daily AGMARKNET snapshots. The upstream feed only publishes the current
// day, so this collection is the only place a price trend can come from.
const mandiPriceSchema = collectionSchema({
  seriesKey: String,
  state: String,
  district: String,
  market: String,
  commodity: String,
  variety: { type: String, default: null },
  grade: { type: String, default: null },
  arrivalDate: Date,
  minPrice: Number,
  maxPrice: Number,
  modalPrice: Number,
  source: { type: String, default: 'agmarknet' },
  recordedAt: Date,
});
mandiPriceSchema.index({ seriesKey: 1, arrivalDate: -1 });
mandiPriceSchema.index({ state: 1, district: 1, arrivalDate: -1 });
mandiPriceSchema.index({ source: 1, arrivalDate: -1 });

const marketProductSchema = collectionSchema({
  // Free-text name and description per locale, keyed by language code, with
  // `en` required as the fallback for any locale the seller has not filled in.
  name: { type: Schema.Types.Mixed },
  description: { type: Schema.Types.Mixed },
  category: String,
  price: Number,
  unit: String,
  stockQuantity: Number,
  vendor: String,
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date,
});
marketProductSchema.index({ isActive: 1, category: 1, createdAt: -1 });

const adminUserSchema = collectionSchema({
  email: String,
  name: String,
  role: String,
  passwordHash: String,
  isActive: Boolean,
  lastLoginAt: { type: Date, default: null },
  createdAt: Date,
  updatedAt: Date,
});
adminUserSchema.index({ email: 1 }, { unique: true });

const adminSessionSchema = collectionSchema({
  adminId: String,
  tokenHash: String,
  expiresAt: Date,
  revokedAt: { type: Date, default: null },
  createdAt: Date,
});
adminSessionSchema.index({ tokenHash: 1 }, { unique: true });
adminSessionSchema.index({ adminId: 1, revokedAt: 1 });

const auditLogSchema = collectionSchema({
  adminId: String,
  adminEmail: String,
  action: String,
  targetType: { type: String, default: null },
  targetId: { type: String, default: null },
  summary: String,
  ipAddress: { type: String, default: null },
  createdAt: Date,
});
auditLogSchema.index({ createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });

const otpSchema = collectionSchema({
  phone: String,
  codeHash: String,
  expiresAt: Date,
  attempts: Number,
  consumedAt: { type: Date, default: null },
  createdAt: Date,
});
otpSchema.index({ phone: 1, createdAt: -1 });

const refreshTokenSchema = collectionSchema({
  userId: String,
  tokenHash: String,
  expiresAt: Date,
  revokedAt: { type: Date, default: null },
  createdAt: Date,
});
refreshTokenSchema.index({ tokenHash: 1 }, { unique: true });
refreshTokenSchema.index({ userId: 1, revokedAt: 1 });

const broadcastSchema = collectionSchema({
  title: String,
  body: String,
  category: String,
  deepLink: { type: String, default: null },
  audience: { type: Schema.Types.Mixed },
  status: String,
  createdByAdminId: String,
  createdByAdminEmail: String,
  scheduledAt: { type: Date, default: null },
  sentAt: { type: Date, default: null },
  audienceCount: Number,
  deliveredCount: Number,
  failedCount: Number,
  failureReason: { type: String, default: null },
  createdAt: Date,
  updatedAt: Date,
});
broadcastSchema.index({ status: 1, sentAt: -1 });
broadcastSchema.index({ status: 1, scheduledAt: 1 });

const broadcastReceiptSchema = collectionSchema({
  broadcastId: String,
  userId: String,
  readAt: Date,
});
broadcastReceiptSchema.index({ broadcastId: 1, userId: 1 }, { unique: true });
broadcastReceiptSchema.index({ userId: 1 });

export class MongoDatabase {
  private readonly connection: Connection;

  readonly users: Model<UserDocument>;
  readonly farmProfiles: Model<FarmProfileDocument>;
  readonly crops: Model<CropDocument>;
  readonly calendarTasks: Model<CalendarTaskDocument>;
  readonly fertilizerRecommendations: Model<FertilizerRecommendationDocument>;
  readonly irrigationRecommendations: Model<IrrigationRecommendationDocument>;
  readonly devices: Model<DeviceDocument>;
  readonly mandiPrices: Model<MandiPriceDocument>;
  readonly marketProducts: Model<MarketProductDocument>;
  readonly adminUsers: Model<AdminUserDocument>;
  readonly adminSessions: Model<AdminSessionDocument>;
  readonly adminAuditLogs: Model<AdminAuditLogDocument>;
  readonly otpCodes: Model<OtpCodeDocument>;
  readonly refreshTokens: Model<RefreshTokenDocument>;
  readonly broadcasts: Model<BroadcastDocument>;
  readonly broadcastReceipts: Model<BroadcastReceiptDocument>;

  constructor(uri: string, databaseName?: string) {
    // A dedicated connection rather than the global mongoose default, so the
    // process can hold more than one and close this one deterministically.
    this.connection = mongoose.createConnection(uri, {
      dbName:
        databaseName?.trim() || databaseNameFromUri(uri) || defaultDatabaseName,
      // Index building is an explicit deploy step (`npm run db:indexes`), not
      // something that races every boot.
      autoIndex: false,
    });

    const model = <T>(name: string, schema: Schema, collection: string) =>
      this.connection.model(name, schema, collection) as unknown as Model<T>;

    this.users = model<UserDocument>('User', userSchema, 'users');
    this.farmProfiles = model<FarmProfileDocument>(
      'FarmProfile',
      farmProfileSchema,
      'farm_profiles',
    );
    this.crops = model<CropDocument>('Crop', cropSchema, 'crops');
    this.calendarTasks = model<CalendarTaskDocument>(
      'CalendarTask',
      calendarTaskSchema,
      'calendar_tasks',
    );
    this.fertilizerRecommendations = model<FertilizerRecommendationDocument>(
      'FertilizerRecommendation',
      fertilizerSchema,
      'fertilizer_recommendations',
    );
    this.irrigationRecommendations = model<IrrigationRecommendationDocument>(
      'IrrigationRecommendation',
      irrigationSchema,
      'irrigation_recommendations',
    );
    this.devices = model<DeviceDocument>('Device', deviceSchema, 'devices');
    this.mandiPrices = model<MandiPriceDocument>(
      'MandiPrice',
      mandiPriceSchema,
      'mandi_prices',
    );
    this.marketProducts = model<MarketProductDocument>(
      'MarketProduct',
      marketProductSchema,
      'market_products',
    );
    this.adminUsers = model<AdminUserDocument>(
      'AdminUser',
      adminUserSchema,
      'admin_users',
    );
    this.adminSessions = model<AdminSessionDocument>(
      'AdminSession',
      adminSessionSchema,
      'admin_sessions',
    );
    this.adminAuditLogs = model<AdminAuditLogDocument>(
      'AdminAuditLog',
      auditLogSchema,
      'admin_audit_logs',
    );
    this.otpCodes = model<OtpCodeDocument>('OtpCode', otpSchema, 'otp_codes');
    this.refreshTokens = model<RefreshTokenDocument>(
      'RefreshToken',
      refreshTokenSchema,
      'refresh_tokens',
    );
    this.broadcasts = model<BroadcastDocument>(
      'Broadcast',
      broadcastSchema,
      'broadcasts',
    );
    this.broadcastReceipts = model<BroadcastReceiptDocument>(
      'BroadcastReceipt',
      broadcastReceiptSchema,
      'broadcast_receipts',
    );
  }

  async ping(): Promise<void> {
    await this.connection.asPromise();
    await this.connection.db?.command({ ping: 1 });
  }

  /**
   * Builds every index declared on the schemas. `syncIndexes` also drops
   * indexes that are no longer declared, which is what makes replacing a plain
   * unique index with a partial one work without a manual drop.
   */
  async ensureIndexes(): Promise<void> {
    await this.connection.asPromise();
    await Promise.all(
      Object.values(this.connection.models).map((model) =>
        model.syncIndexes({ background: true }),
      ),
    );
  }

  async close(): Promise<void> {
    await this.connection.close();
  }
}

function databaseNameFromUri(uri: string): string | null {
  const withoutQuery = uri.split('?')[0] ?? '';
  const separator = withoutQuery.indexOf('/', uri.indexOf('//') + 2);
  if (separator < 0) return null;
  const name = withoutQuery.slice(separator + 1);
  return name.length > 0 ? decodeURIComponent(name) : null;
}

export function isDuplicateKeyError(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    (error as { code?: unknown }).code === 11000
  );
}
