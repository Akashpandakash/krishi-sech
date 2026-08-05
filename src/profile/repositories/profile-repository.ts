import type { AuthUser } from '../../auth/repositories/auth-repository.js';

export interface UserProfileUpdate {
  name: string;
  preferredLanguage: string;
  profilePhotoUrl?: string | null;
  state?: string | null;
  district?: string | null;
  village?: string | null;
}

export interface FarmProfile {
  id: string;
  userId: string;
  farmName: string;
  farmerType: string;
  totalLandArea: number;
  landUnit: string;
  soilType: string;
  irrigationSource: string;
  mainCrops: string[];
  coarseLocation: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export type FarmProfileInput = Omit<
  FarmProfile,
  'id' | 'userId' | 'createdAt' | 'updatedAt' | 'coarseLocation'
> & { coarseLocation?: string | null };

export interface ProfileRepository {
  getUserProfile(userId: string): Promise<AuthUser | null>;
  updateUserProfile(
    userId: string,
    input: UserProfileUpdate,
  ): Promise<AuthUser>;
  getFarmProfile(userId: string): Promise<FarmProfile | null>;
  upsertFarmProfile(
    userId: string,
    input: FarmProfileInput,
  ): Promise<FarmProfile>;
}
