import { PrismaClient } from '@prisma/client';
import type {
  FarmProfileInput,
  ProfileRepository,
  UserProfileUpdate,
} from './profile-repository.js';

export class PrismaProfileRepository implements ProfileRepository {
  constructor(private readonly prisma: PrismaClient) {}

  getUserProfile(userId: string) {
    return this.prisma.user.findUnique({ where: { id: userId } });
  }

  updateUserProfile(userId: string, input: UserProfileUpdate) {
    return this.prisma.user.update({ where: { id: userId }, data: input });
  }

  getFarmProfile(userId: string) {
    return this.prisma.farmProfile.findUnique({ where: { userId } });
  }

  upsertFarmProfile(userId: string, input: FarmProfileInput) {
    return this.prisma.farmProfile.upsert({
      where: { userId },
      create: { userId, ...input },
      update: input,
    });
  }
}
