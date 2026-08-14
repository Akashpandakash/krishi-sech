import { MongoClient, type Collection, type Db } from 'mongodb';

import type {
  AuthOtp,
  AuthRefreshToken,
  AuthUser,
} from '../auth/repositories/auth-repository.js';
import type { CalendarTaskRecord } from '../calendar/repositories/calendar-task-repository.js';
import type { CropRecord } from '../crops/repositories/crop-repository.js';
import type { FertilizerRecommendationRecord } from '../fertilizer/repositories/fertilizer-recommendation-repository.js';
import type { IrrigationRecommendationRecord } from '../irrigation/repositories/irrigation-recommendation-repository.js';
import type { FarmProfile } from '../profile/repositories/profile-repository.js';

/** Domain records carry `id`; MongoDB stores that identity in `_id`. */
type Document<T extends { id: string }> = Omit<T, 'id'> & { _id: string };

export type UserDocument = Document<AuthUser>;
export type FarmProfileDocument = Document<FarmProfile>;
export type CropDocument = Document<CropRecord>;
export type CalendarTaskDocument = Document<CalendarTaskRecord>;
export type FertilizerRecommendationDocument =
  Document<FertilizerRecommendationRecord>;
export type IrrigationRecommendationDocument =
  Document<IrrigationRecommendationRecord>;
export type OtpCodeDocument = Document<AuthOtp> & { createdAt: Date };
export type RefreshTokenDocument = Document<AuthRefreshToken> & {
  createdAt: Date;
};

export const defaultDatabaseName = 'krishi_sech';

export class MongoDatabase {
  private readonly client: MongoClient;
  private readonly database: Db;

  constructor(uri: string, databaseName?: string) {
    this.client = new MongoClient(uri, { ignoreUndefined: true });
    this.database = this.client.db(
      databaseName?.trim() || databaseNameFromUri(uri) || defaultDatabaseName,
    );
  }

  get users(): Collection<UserDocument> {
    return this.database.collection<UserDocument>('users');
  }

  get farmProfiles(): Collection<FarmProfileDocument> {
    return this.database.collection<FarmProfileDocument>('farm_profiles');
  }

  get crops(): Collection<CropDocument> {
    return this.database.collection<CropDocument>('crops');
  }

  get calendarTasks(): Collection<CalendarTaskDocument> {
    return this.database.collection<CalendarTaskDocument>('calendar_tasks');
  }

  get fertilizerRecommendations(): Collection<FertilizerRecommendationDocument> {
    return this.database.collection<FertilizerRecommendationDocument>(
      'fertilizer_recommendations',
    );
  }

  get irrigationRecommendations(): Collection<IrrigationRecommendationDocument> {
    return this.database.collection<IrrigationRecommendationDocument>(
      'irrigation_recommendations',
    );
  }

  get otpCodes(): Collection<OtpCodeDocument> {
    return this.database.collection<OtpCodeDocument>('otp_codes');
  }

  get refreshTokens(): Collection<RefreshTokenDocument> {
    return this.database.collection<RefreshTokenDocument>('refresh_tokens');
  }

  async ping(): Promise<void> {
    await this.database.command({ ping: 1 });
  }

  /** Replaces the relational unique constraints and indexes. Idempotent. */
  async ensureIndexes(): Promise<void> {
    await Promise.all([
      this.users.createIndex({ phone: 1 }, { unique: true }),
      this.farmProfiles.createIndex({ userId: 1 }, { unique: true }),
      this.crops.createIndex({ userId: 1, createdAt: -1 }),
      this.calendarTasks.createIndex({ userId: 1, dueDate: 1 }),
      this.calendarTasks.createIndex({ cropId: 1 }),
      this.fertilizerRecommendations.createIndex({
        userId: 1,
        cropId: 1,
        createdAt: -1,
      }),
      this.irrigationRecommendations.createIndex({
        userId: 1,
        cropId: 1,
        createdAt: -1,
      }),
      this.otpCodes.createIndex({ phone: 1, createdAt: -1 }),
      this.refreshTokens.createIndex({ tokenHash: 1 }, { unique: true }),
      this.refreshTokens.createIndex({ userId: 1, revokedAt: 1 }),
    ]);
  }

  async close(): Promise<void> {
    await this.client.close();
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
