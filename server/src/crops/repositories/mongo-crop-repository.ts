import { randomUUID } from 'node:crypto';

import {
  isDuplicateKeyError,
  type CropDocument,
  type MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  CropInput,
  CropRecord,
  CropRepository,
} from './crop-repository.js';

function toCropRecord(document: CropDocument): CropRecord {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

export class MongoCropRepository implements CropRepository {
  constructor(private readonly database: MongoDatabase) {}

  async create(
    userId: string,
    input: CropInput,
    id = randomUUID(),
  ): Promise<CropRecord> {
    const now = new Date();
    const document: CropDocument = {
      ...input,
      _id: id,
      userId,
      createdAt: now,
      updatedAt: now,
    };
    try {
      await this.database.crops.insertOne(document);
      return toCropRecord(document);
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const existing = await this.findByIdAndUser(id, userId);
        if (existing) return existing;
      }
      throw error;
    }
  }

  async findAllByUser(userId: string): Promise<CropRecord[]> {
    const documents = await this.database.crops
      .find({ userId })
      .sort({ createdAt: -1 })
      .lean();
    return documents.map(toCropRecord);
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<CropRecord | null> {
    const document = await this.database.crops.findOne({ _id: id, userId }).lean();
    return document ? toCropRecord(document) : null;
  }

  async update(
    id: string,
    userId: string,
    input: CropInput,
  ): Promise<CropRecord> {
    const document = await this.database.crops.findOneAndUpdate(
      { _id: id, userId },
      { $set: { ...input, updatedAt: new Date() } },
      { returnDocument: 'after' },
    ).lean();
    if (!document) throw new Error('Crop not found');
    return toCropRecord(document);
  }

  /** Mirrors the relational `ON DELETE CASCADE` from crop to its dependents. */
  async delete(id: string, userId: string): Promise<void> {
    const result = await this.database.crops.deleteOne({ _id: id, userId });
    if (result.deletedCount === 0) throw new Error('Crop not found');
    await Promise.all([
      this.database.calendarTasks.deleteMany({ cropId: id, userId }),
      this.database.fertilizerRecommendations.deleteMany({
        cropId: id,
        userId,
      }),
      this.database.irrigationRecommendations.deleteMany({
        cropId: id,
        userId,
      }),
    ]);
  }
}
