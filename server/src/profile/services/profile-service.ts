import { AppError } from '../../common/app-error.js';
import type {
  FarmProfileInput,
  ProfileRepository,
  UserProfileUpdate,
} from '../repositories/profile-repository.js';

export class ProfileService {
  constructor(private readonly repository: ProfileRepository) {}
  async getUser(userId: string) {
    const user = await this.repository.getUserProfile(userId);
    if (!user)
      throw new AppError(404, 'PROFILE_NOT_FOUND', 'Profile not found');
    return user;
  }
  updateUser(userId: string, input: UserProfileUpdate) {
    return this.repository.updateUserProfile(userId, input);
  }
  getFarm(userId: string) {
    return this.repository.getFarmProfile(userId);
  }
  updateFarm(userId: string, input: FarmProfileInput) {
    return this.repository.upsertFarmProfile(userId, input);
  }
}
