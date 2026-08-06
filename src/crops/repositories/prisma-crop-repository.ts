import { PrismaClient } from '@prisma/client';

import type {
  CropInput,
  CropRecord,
  CropRepository,
} from './crop-repository.js';

export class PrismaCropRepository implements CropRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(
    userId: string,
    input: CropInput,
    id?: string,
  ): Promise<CropRecord> {
    try {
      return await this.prisma.crop.create({
        data: { ...input, userId, ...(id == null ? {} : { id }) },
      });
    } catch (error) {
      if (id != null) {
        const existing = await this.findByIdAndUser(id, userId);
        if (existing) return existing;
      }
      throw error;
    }
  }

  findAllByUser(userId: string): Promise<CropRecord[]> {
    return this.prisma.crop.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  findByIdAndUser(id: string, userId: string): Promise<CropRecord | null> {
    return this.prisma.crop.findFirst({ where: { id, userId } });
  }

  update(
    id: string,
    userId: string,
    input: CropInput,
  ): Promise<CropRecord> {
    return this.prisma.crop.update({
      where: { id, userId },
      data: input,
    });
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.prisma.crop.delete({ where: { id, userId } });
  }
}
