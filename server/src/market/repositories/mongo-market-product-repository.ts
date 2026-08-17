import { randomUUID } from 'node:crypto';

import { AppError } from '../../common/app-error.js';
import {
  isDuplicateKeyError,
  type MarketProductDocument,
  type MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  MarketProductInput,
  MarketProductQuery,
  MarketProductRecord,
  MarketProductRepository,
} from './market-product-repository.js';

function toRecord(document: MarketProductDocument): MarketProductRecord {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

/** Search is user input reaching a regex, so every metacharacter is literal. */
function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export class MongoMarketProductRepository implements MarketProductRepository {
  constructor(private readonly database: MongoDatabase) {}

  async listActive(query: MarketProductQuery): Promise<MarketProductRecord[]> {
    const filter: Record<string, unknown> = { isActive: true };
    if (query.category) filter.category = query.category;
    const search = query.search?.trim();
    if (search) {
      const pattern = new RegExp(escapeRegExp(search), 'i');
      filter.$or = [{ 'name.en': pattern }, { vendor: pattern }];
    }
    const documents = await this.database.marketProducts
      .find(filter)
      .sort({ createdAt: -1 })
      .lean();
    return (documents as MarketProductDocument[]).map(toRecord);
  }

  async listAll(): Promise<MarketProductRecord[]> {
    const documents = await this.database.marketProducts
      .find({})
      .sort({ createdAt: -1 })
      .lean();
    return (documents as MarketProductDocument[]).map(toRecord);
  }

  async findById(id: string): Promise<MarketProductRecord | null> {
    const document = await this.database.marketProducts
      .findOne({ _id: id })
      .lean();
    return document ? toRecord(document as MarketProductDocument) : null;
  }

  async create(
    input: MarketProductInput,
    id = randomUUID(),
  ): Promise<MarketProductRecord> {
    const now = new Date();
    const document: MarketProductDocument = {
      ...input,
      _id: id,
      createdAt: now,
      updatedAt: now,
    };
    try {
      await this.database.marketProducts.insertOne(document);
      return toRecord(document);
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const existing = await this.findById(id);
        if (existing) return existing;
      }
      throw error;
    }
  }

  async update(
    id: string,
    input: MarketProductInput,
  ): Promise<MarketProductRecord> {
    const document = await this.database.marketProducts
      .findOneAndUpdate(
        { _id: id },
        { $set: { ...input, updatedAt: new Date() } },
        { returnDocument: 'after' },
      )
      .lean();
    if (!document) {
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found');
    }
    return toRecord(document as MarketProductDocument);
  }

  async delete(id: string): Promise<void> {
    const result = await this.database.marketProducts.deleteOne({ _id: id });
    if (result.deletedCount === 0) {
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found');
    }
  }
}
