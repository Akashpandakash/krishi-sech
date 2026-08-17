export interface AccountDeletionSummary {
  crops: number;
  calendarTasks: number;
  farmProfiles: number;
  fertilizerRecommendations: number;
  irrigationRecommendations: number;
  devices: number;
  notificationReceipts: number;
  sessions: number;
}

export interface AccountDeletionRepository {
  /**
   * Removes every record owned by the account, including the account itself.
   * Returns per-collection counts so the deletion can be logged and shown back
   * to the person who asked for it.
   */
  purge(userId: string): Promise<AccountDeletionSummary>;
}

export const emptyDeletionSummary: AccountDeletionSummary = {
  crops: 0,
  calendarTasks: 0,
  farmProfiles: 0,
  fertilizerRecommendations: 0,
  irrigationRecommendations: 0,
  devices: 0,
  notificationReceipts: 0,
  sessions: 0,
};
