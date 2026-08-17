import { randomUUID } from 'node:crypto';
import type { PipelineStage } from 'mongoose';

/** Loose shape for filters and aggregation stages assembled at runtime. */
type Document = Record<string, any>;

import type {
  BroadcastDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  Broadcast,
  BroadcastAudience,
  BroadcastInput,
  BroadcastRepository,
  BroadcastSendResult,
  BroadcastStatus,
  InboxItem,
} from './broadcast-repository.js';

function toBroadcast(document: BroadcastDocument): Broadcast {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

/** `null` on an audience field means "everyone", so it must always match. */
function audienceMatchesUser(
  field: string,
  value: string | null,
): Document {
  return { $or: [{ [field]: null }, { [field]: value }] };
}

export class MongoBroadcastRepository implements BroadcastRepository {
  constructor(private readonly database: MongoDatabase) {}

  async create(
    input: BroadcastInput,
    status: BroadcastStatus,
  ): Promise<Broadcast> {
    const now = new Date();
    const document: BroadcastDocument = {
      _id: randomUUID(),
      title: input.title,
      body: input.body,
      category: input.category,
      deepLink: input.deepLink,
      audience: input.audience,
      status,
      createdByAdminId: input.createdByAdminId,
      createdByAdminEmail: input.createdByAdminEmail,
      scheduledAt: input.scheduledAt,
      sentAt: null,
      audienceCount: 0,
      deliveredCount: 0,
      failedCount: 0,
      failureReason: null,
      createdAt: now,
      updatedAt: now,
    };
    await this.database.broadcasts.insertOne(document);
    return toBroadcast(document);
  }

  async findById(id: string): Promise<Broadcast | null> {
    const document = await this.database.broadcasts.findOne({ _id: id }).lean();
    return document ? toBroadcast(document) : null;
  }

  async list(limit: number, status?: BroadcastStatus): Promise<Broadcast[]> {
    const documents = await this.database.broadcasts
      .find(status ? { status } : {})
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    return documents.map(toBroadcast);
  }

  async updateStatus(
    id: string,
    status: BroadcastStatus,
    changes: Partial<BroadcastSendResult> & { sentAt?: Date } = {},
  ): Promise<Broadcast> {
    const document = await this.database.broadcasts.findOneAndUpdate(
      { _id: id },
      { $set: { status, ...changes, updatedAt: new Date() } },
      { returnDocument: 'after' },
    ).lean();
    if (!document) throw new Error('Broadcast not found');
    return toBroadcast(document);
  }

  async delete(id: string): Promise<void> {
    await this.database.broadcasts.deleteOne({ _id: id });
    await this.database.broadcastReceipts.deleteMany({ broadcastId: id });
  }

  async findDueScheduled(now: Date): Promise<Broadcast[]> {
    const documents = await this.database.broadcasts
      .find({ status: 'scheduled', scheduledAt: { $lte: now } })
      .lean();
    return documents.map(toBroadcast);
  }

  async audienceDeviceTokens(audience: BroadcastAudience): Promise<string[]> {
    const userMatch: Document = {};
    if (audience.onlyActive) userMatch.isActive = true;
    if (audience.language) userMatch.preferredLanguage = audience.language;
    if (audience.state) userMatch.state = audience.state;
    const stages: Document[] = [
      {
        $lookup: {
          from: 'users',
          localField: 'userId',
          foreignField: '_id',
          as: 'user',
        },
      },
      { $unwind: '$user' },
      {
        $match: Object.fromEntries(
          Object.entries(userMatch).map(([key, value]) => [
            `user.${key}`,
            value,
          ]),
        ),
      },
    ];
    if (audience.farmerType) {
      stages.push(
        {
          $lookup: {
            from: 'farm_profiles',
            localField: 'userId',
            foreignField: 'userId',
            as: 'farm',
          },
        },
        { $match: { 'farm.farmerType': audience.farmerType } },
      );
    }
    stages.push({ $group: { _id: '$token' } });
    const rows = await this.database.devices
      .aggregate<{ _id: string }>(stages as PipelineStage[])
      ;
    return rows.map((row) => row._id);
  }

  private async audienceFilterForUser(userId: string): Promise<Document | null> {
    const user = await this.database.users.findOne({ _id: userId }).lean();
    if (!user) return null;
    const farm = await this.database.farmProfiles.findOne({ userId }).lean();
    return {
      status: 'sent',
      $and: [
        audienceMatchesUser('audience.language', user.preferredLanguage),
        audienceMatchesUser('audience.state', user.state ?? null),
        audienceMatchesUser('audience.farmerType', farm?.farmerType ?? null),
      ],
    };
  }

  async inboxForUser(userId: string, limit: number): Promise<InboxItem[]> {
    const filter = await this.audienceFilterForUser(userId);
    if (!filter) return [];
    const [broadcasts, receipts] = await Promise.all([
      this.database.broadcasts
        .find(filter)
        .sort({ sentAt: -1 })
        .limit(limit)
        .lean(),
      this.database.broadcastReceipts.find({ userId }).lean(),
    ]);
    const read = new Set(receipts.map((receipt) => receipt.broadcastId));
    return broadcasts.map((broadcast) => ({
      id: broadcast._id,
      title: broadcast.title,
      body: broadcast.body,
      category: broadcast.category,
      deepLink: broadcast.deepLink,
      sentAt: broadcast.sentAt ?? broadcast.createdAt,
      read: read.has(broadcast._id),
    }));
  }

  async markRead(broadcastId: string, userId: string): Promise<void> {
    await this.database.broadcastReceipts.updateOne(
      { broadcastId, userId },
      { $setOnInsert: { _id: randomUUID(), readAt: new Date() } },
      { upsert: true },
    );
  }

  async countUnread(userId: string): Promise<number> {
    const filter = await this.audienceFilterForUser(userId);
    if (!filter) return 0;
    const [ids, receipts] = await Promise.all([
      this.database.broadcasts.distinct('_id', filter),
      this.database.broadcastReceipts.distinct('broadcastId', { userId }),
    ]);
    const read = new Set(receipts);
    return ids.filter((id) => !read.has(id)).length;
  }

  async removeTokens(tokens: string[]): Promise<void> {
    if (tokens.length === 0) return;
    await this.database.devices.deleteMany({ token: { $in: tokens } });
  }
}
