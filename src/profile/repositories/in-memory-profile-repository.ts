import type {
  AuthRepository,
  AuthUser,
} from '../../auth/repositories/auth-repository.js';
import type {
  FarmProfile,
  FarmProfileInput,
  ProfileRepository,
  UserProfileUpdate,
} from './profile-repository.js';

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
