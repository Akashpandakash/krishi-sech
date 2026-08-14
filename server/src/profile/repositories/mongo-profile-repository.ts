import { randomUUID } from 'node:crypto';

import type { AuthUser } from '../../auth/repositories/auth-repository.js';
import { toAuthUser } from '../../auth/repositories/mongo-auth-repository.js';
import type {
  FarmProfileDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  FarmProfile,
  FarmProfileInput,
  ProfileRepository,
  UserProfileUpdate,
} from './profile-repository.js';

function toFarmProfile(document: FarmProfileDocument): FarmProfile {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

export class MongoProfileRepository implements ProfileRepository {
  constructor(private readonly database: MongoDatabase) {}

  async getUserProfile(userId: string): Promise<AuthUser | null> {
    const document = await this.database.users.findOne({ _id: userId });
    return document ? toAuthUser(document) : null;
  }

  async updateUserProfile(
    userId: string,
    input: UserProfileUpdate,
  ): Promise<AuthUser> {
    const document = await this.database.users.findOneAndUpdate(
      { _id: userId },
      { $set: { ...input, updatedAt: new Date() } },
      { returnDocument: 'after' },
    );
    if (!document) throw new Error('User not found');
    return toAuthUser(document);
  }

  async getFarmProfile(userId: string): Promise<FarmProfile | null> {
    const document = await this.database.farmProfiles.findOne({ userId });
    return document ? toFarmProfile(document) : null;
  }

  async upsertFarmProfile(
    userId: string,
    input: FarmProfileInput,
  ): Promise<FarmProfile> {
    const now = new Date();
    const document = await this.database.farmProfiles.findOneAndUpdate(
      { userId },
      {
        $set: {
          ...input,
          coarseLocation: input.coarseLocation ?? null,
          updatedAt: now,
        },
        $setOnInsert: { _id: randomUUID(), createdAt: now },
      },
      { upsert: true, returnDocument: 'after' },
    );
    if (!document) throw new Error('Failed to upsert farm profile');
    return toFarmProfile(document);
  }
}
