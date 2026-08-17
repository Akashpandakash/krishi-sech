export const broadcastStatuses = [
  'draft',
  'scheduled',
  'sending',
  'sent',
  'failed',
  'cancelled',
] as const;
export type BroadcastStatus = (typeof broadcastStatuses)[number];

export const broadcastCategories = [
  'general',
  'weather',
  'advisory',
  'market',
  'maintenance',
] as const;
export type BroadcastCategory = (typeof broadcastCategories)[number];

export interface BroadcastAudience {
  language: string | null;
  state: string | null;
  farmerType: string | null;
  onlyActive: boolean;
}

export interface Broadcast {
  id: string;
  title: string;
  body: string;
  category: BroadcastCategory;
  deepLink: string | null;
  audience: BroadcastAudience;
  status: BroadcastStatus;
  createdByAdminId: string;
  createdByAdminEmail: string;
  scheduledAt: Date | null;
  sentAt: Date | null;
  audienceCount: number;
  deliveredCount: number;
  failedCount: number;
  failureReason: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface BroadcastReceipt {
  id: string;
  broadcastId: string;
  userId: string;
  readAt: Date;
}

export interface BroadcastInput {
  title: string;
  body: string;
  category: BroadcastCategory;
  deepLink: string | null;
  audience: BroadcastAudience;
  scheduledAt: Date | null;
  createdByAdminId: string;
  createdByAdminEmail: string;
}

export interface BroadcastSendResult {
  audienceCount: number;
  deliveredCount: number;
  failedCount: number;
  failureReason: string | null;
}

export interface InboxItem {
  id: string;
  title: string;
  body: string;
  category: BroadcastCategory;
  deepLink: string | null;
  sentAt: Date;
  read: boolean;
}

export interface BroadcastRepository {
  create(input: BroadcastInput, status: BroadcastStatus): Promise<Broadcast>;
  findById(id: string): Promise<Broadcast | null>;
  list(limit: number, status?: BroadcastStatus): Promise<Broadcast[]>;
  updateStatus(
    id: string,
    status: BroadcastStatus,
    changes?: Partial<BroadcastSendResult> & { sentAt?: Date },
  ): Promise<Broadcast>;
  delete(id: string): Promise<void>;
  /** Broadcasts whose `scheduledAt` has passed and are still queued. */
  findDueScheduled(now: Date): Promise<Broadcast[]>;
  /** Push tokens for every account matching the audience filter. */
  audienceDeviceTokens(audience: BroadcastAudience): Promise<string[]>;
  /** Sent broadcasts targeted at one account, newest first. */
  inboxForUser(userId: string, limit: number): Promise<InboxItem[]>;
  markRead(broadcastId: string, userId: string): Promise<void>;
  countUnread(userId: string): Promise<number>;
  removeTokens(tokens: string[]): Promise<void>;
}
