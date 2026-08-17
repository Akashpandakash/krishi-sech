import type { MongoDatabase } from '../../database/mongo-database.js';
import type {
  AccountDeletionRepository,
  AccountDeletionSummary,
} from './account-deletion-repository.js';

export class MongoAccountDeletionRepository
  implements AccountDeletionRepository
{
  constructor(private readonly database: MongoDatabase) {}

  async purge(userId: string): Promise<AccountDeletionSummary> {
    // Owned data goes first: if anything fails midway the account still
    // exists, so the request can be retried instead of orphaning records.
    const [
      crops,
      calendarTasks,
      farmProfiles,
      fertilizerRecommendations,
      irrigationRecommendations,
      devices,
      notificationReceipts,
      sessions,
    ] = await Promise.all([
      this.database.crops.deleteMany({ userId }),
      this.database.calendarTasks.deleteMany({ userId }),
      this.database.farmProfiles.deleteMany({ userId }),
      this.database.fertilizerRecommendations.deleteMany({ userId }),
      this.database.irrigationRecommendations.deleteMany({ userId }),
      // Push tokens must go with the account, or a broadcast would deliver to
      // a handset whose owner deleted their data.
      this.database.devices.deleteMany({ userId }),
      this.database.broadcastReceipts.deleteMany({ userId }),
      this.database.refreshTokens.deleteMany({ userId }),
    ]);
    await this.database.users.deleteOne({ _id: userId });
    return {
      crops: crops.deletedCount,
      calendarTasks: calendarTasks.deletedCount,
      farmProfiles: farmProfiles.deletedCount,
      fertilizerRecommendations: fertilizerRecommendations.deletedCount,
      irrigationRecommendations: irrigationRecommendations.deletedCount,
      devices: devices.deletedCount,
      notificationReceipts: notificationReceipts.deletedCount,
      sessions: sessions.deletedCount,
    };
  }
}
