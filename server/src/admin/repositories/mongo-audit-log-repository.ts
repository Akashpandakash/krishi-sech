import { randomUUID } from 'node:crypto';

import type { MongoDatabase } from '../../database/mongo-database.js';
import type {
  AuditLogEntry,
  AuditLogInput,
  AuditLogRepository,
} from './audit-log-repository.js';

export class MongoAuditLogRepository implements AuditLogRepository {
  constructor(private readonly database: MongoDatabase) {}

  async record(input: AuditLogInput): Promise<void> {
    await this.database.adminAuditLogs.insertOne({
      _id: randomUUID(),
      ...input,
      createdAt: new Date(),
    });
  }

  async list(limit: number, action?: string): Promise<AuditLogEntry[]> {
    const documents = await this.database.adminAuditLogs
      .find(action ? { action } : {})
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    return documents.map(({ _id, ...rest }) => ({ id: _id, ...rest }));
  }
}
