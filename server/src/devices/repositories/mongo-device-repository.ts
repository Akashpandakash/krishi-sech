import { randomUUID } from 'node:crypto';

import type {
  DeviceDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  DevicePlatform,
  DeviceRecord,
  DeviceRepository,
} from './device-repository.js';

function toDeviceRecord(document: DeviceDocument): DeviceRecord {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

export class MongoDeviceRepository implements DeviceRepository {
  constructor(private readonly database: MongoDatabase) {}

  async register(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ): Promise<DeviceRecord> {
    const now = new Date();
    const document = await this.database.devices.findOneAndUpdate(
      { token },
      {
        $set: { userId, platform, updatedAt: now },
        $setOnInsert: { _id: randomUUID(), createdAt: now },
      },
      { upsert: true, returnDocument: 'after' },
    ).lean();
    if (!document) throw new Error('Failed to register device');
    // Mirror the newest token onto the account so the admin panel can show
    // reachability without a join. Delivery still reads `devices`, which is
    // what supports a farmer having more than one handset.
    await this.database.users.updateOne(
      { _id: userId },
      { $set: { fcmToken: token, fcmTokenUpdatedAt: now } },
    );
    return toDeviceRecord(document);
  }

  async findByUser(userId: string): Promise<DeviceRecord[]> {
    const documents = await this.database.devices
      .find({ userId })
      .sort({ updatedAt: -1 })
      .lean();
    return documents.map(toDeviceRecord);
  }

  async removeTokens(tokens: string[]): Promise<void> {
    if (tokens.length === 0) return;
    await this.database.devices.deleteMany({ token: { $in: tokens } });
  }

  async countByPlatform(): Promise<Record<DevicePlatform, number>> {
    const counts: Record<DevicePlatform, number> = {
      android: 0,
      ios: 0,
      web: 0,
    };
    const rows = await this.database.devices
      .aggregate<{ _id: DevicePlatform; total: number }>([
        { $group: { _id: '$platform', total: { $sum: 1 } } },
      ])
      ;
    for (const row of rows) {
      if (row._id in counts) counts[row._id] = row.total;
    }
    return counts;
  }
}
