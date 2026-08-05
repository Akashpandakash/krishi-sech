import { randomUUID } from 'node:crypto';

import type {
  CropInput,
  CropRecord,
  CropRepository,
} from './crop-repository.js';

export class InMemoryCropRepository implements CropRepository {
  private readonly crops = new Map<string, CropRecord>();

  async create(userId: string, input: CropInput): Promise<CropRecord> {
    const now = new Date();
    const crop: CropRecord = {
      ...input,
      id: randomUUID(),
      userId,
      createdAt: now,
      updatedAt: now,
    };
    this.crops.set(crop.id, crop);
    return crop;
  }

  async findAllByUser(userId: string): Promise<CropRecord[]> {
    return [...this.crops.values()]
      .filter((crop) => crop.userId === userId)
      .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime());
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<CropRecord | null> {
    const crop = this.crops.get(id);
    return crop?.userId === userId ? crop : null;
  }

  async update(
    id: string,
    userId: string,
    input: CropInput,
  ): Promise<CropRecord> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) {
      throw new Error('Crop not found');
    }
    const crop = {...existing, ...input, updatedAt: new Date()};
    this.crops.set(id, crop);
    return crop;
  }

  async delete(id: string, userId: string): Promise<void> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) {
      throw new Error('Crop not found');
    }
    this.crops.delete(id);
  }
}
