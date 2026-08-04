import type { PrismaClient } from '@prisma/client';
import type { IrrigationRecommendationRecord, IrrigationRecommendationRepository } from './irrigation-recommendation-repository.js';

export class PrismaIrrigationRecommendationRepository implements IrrigationRecommendationRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async save(input: IrrigationRecommendationRecord): Promise<IrrigationRecommendationRecord> {
    return this.prisma.irrigationRecommendation.create({
      data: { ...input, waterQuantity: input.waterQuantity },
    }) as unknown as Promise<IrrigationRecommendationRecord>;
  }

  async findByUserAndCrop(userId: string, cropId: string): Promise<IrrigationRecommendationRecord[]> {
    return this.prisma.irrigationRecommendation.findMany({
      where: { userId, cropId },
      orderBy: { createdAt: 'desc' },
    }) as unknown as Promise<IrrigationRecommendationRecord[]>;
  }
}
