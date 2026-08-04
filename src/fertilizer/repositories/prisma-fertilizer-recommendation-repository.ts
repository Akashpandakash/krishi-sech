import type { PrismaClient } from '@prisma/client';
import type { FertilizerRecommendationRecord, FertilizerRecommendationRepository } from './fertilizer-recommendation-repository.js';

export class PrismaFertilizerRecommendationRepository implements FertilizerRecommendationRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async save(input: FertilizerRecommendationRecord): Promise<FertilizerRecommendationRecord> {
    const record = await this.prisma.fertilizerRecommendation.create({
      data: { ...input, quantity: input.quantity, safetyPrecautions: input.safetyPrecautions },
    });
    return record as FertilizerRecommendationRecord;
  }

  async findByUserAndCrop(userId: string, cropId: string): Promise<FertilizerRecommendationRecord[]> {
    return this.prisma.fertilizerRecommendation.findMany({
      where: { userId, cropId },
      orderBy: { createdAt: 'desc' },
    }) as unknown as Promise<FertilizerRecommendationRecord[]>;
  }
}
