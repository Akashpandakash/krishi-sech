import { AppError } from '../../common/app-error.js';
import type { PushDeliveryProvider } from '../providers/push-delivery-provider.js';
import type {
  Broadcast,
  BroadcastInput,
  BroadcastRepository,
  BroadcastStatus,
} from '../repositories/broadcast-repository.js';

export class BroadcastService {
  private schedulerTimer: NodeJS.Timeout | null = null;

  constructor(
    private readonly repository: BroadcastRepository,
    private readonly push: PushDeliveryProvider,
    private readonly loggingEnabled = false,
  ) {}

  get pushTransport(): { name: string; configured: boolean } {
    return { name: this.push.name, configured: this.push.configured };
  }

  async create(input: BroadcastInput, sendNow: boolean): Promise<Broadcast> {
    if (input.scheduledAt && input.scheduledAt.getTime() < Date.now()) {
      throw new AppError(
        400,
        'SCHEDULE_IN_PAST',
        'Scheduled time must be in the future',
      );
    }
    const status: BroadcastStatus = sendNow
      ? 'sending'
      : input.scheduledAt
        ? 'scheduled'
        : 'draft';
    const broadcast = await this.repository.create(input, status);
    return sendNow ? this.deliver(broadcast) : broadcast;
  }

  list(limit: number, status?: BroadcastStatus): Promise<Broadcast[]> {
    return this.repository.list(limit, status);
  }

  async get(id: string): Promise<Broadcast> {
    const broadcast = await this.repository.findById(id);
    if (!broadcast) {
      throw new AppError(404, 'BROADCAST_NOT_FOUND', 'Broadcast not found');
    }
    return broadcast;
  }

  async send(id: string): Promise<Broadcast> {
    const broadcast = await this.get(id);
    if (broadcast.status === 'sent' || broadcast.status === 'sending') {
      throw new AppError(
        409,
        'BROADCAST_ALREADY_SENT',
        'Broadcast has already been sent',
      );
    }
    return this.deliver(
      await this.repository.updateStatus(broadcast.id, 'sending'),
    );
  }

  async cancel(id: string): Promise<Broadcast> {
    const broadcast = await this.get(id);
    if (broadcast.status === 'sent') {
      throw new AppError(
        409,
        'BROADCAST_ALREADY_SENT',
        'A sent broadcast cannot be cancelled',
      );
    }
    return this.repository.updateStatus(broadcast.id, 'cancelled');
  }

  async delete(id: string): Promise<void> {
    await this.get(id);
    await this.repository.delete(id);
  }

  estimateAudience(audience: Broadcast['audience']): Promise<string[]> {
    return this.repository.audienceDeviceTokens(audience);
  }

  private async deliver(broadcast: Broadcast): Promise<Broadcast> {
    const tokens = await this.repository.audienceDeviceTokens(
      broadcast.audience,
    );
    const result = await this.push.send(tokens, {
      title: broadcast.title,
      body: broadcast.body,
      data: {
        broadcastId: broadcast.id,
        category: broadcast.category,
        ...(broadcast.deepLink ? { deepLink: broadcast.deepLink } : {}),
      },
    });
    if (result.staleTokens.length > 0) {
      await this.repository.removeTokens(result.staleTokens);
    }
    // A push failure never hides the message: it stays readable in the inbox,
    // so the broadcast is still "sent" and the counters carry the detail.
    const updated = await this.repository.updateStatus(broadcast.id, 'sent', {
      sentAt: new Date(),
      audienceCount: tokens.length,
      deliveredCount: result.delivered,
      failedCount: result.failed,
      failureReason: result.failureReason,
    });
    if (this.loggingEnabled) {
      console.log(
        JSON.stringify({
          event: 'broadcast_sent',
          broadcastId: broadcast.id,
          transport: this.push.name,
          tokens: tokens.length,
          delivered: result.delivered,
          failed: result.failed,
        }),
      );
    }
    return updated;
  }

  inbox(userId: string, limit: number) {
    return this.repository.inboxForUser(userId, limit);
  }

  markRead(broadcastId: string, userId: string) {
    return this.repository.markRead(broadcastId, userId);
  }

  countUnread(userId: string) {
    return this.repository.countUnread(userId);
  }

  /** Sends scheduled broadcasts whose time has passed. Safe to call repeatedly. */
  async dispatchScheduled(now = new Date()): Promise<number> {
    const due = await this.repository.findDueScheduled(now);
    for (const broadcast of due) {
      try {
        await this.deliver(
          await this.repository.updateStatus(broadcast.id, 'sending'),
        );
      } catch (error) {
        await this.repository.updateStatus(broadcast.id, 'failed', {
          failureReason:
            error instanceof Error ? error.message : 'Broadcast delivery failed',
        });
      }
    }
    return due.length;
  }

  startScheduler(intervalMs = 60_000): void {
    if (this.schedulerTimer) return;
    this.schedulerTimer = setInterval(() => {
      void this.dispatchScheduled().catch((error: unknown) => {
        if (!this.loggingEnabled) return;
        console.error(
          JSON.stringify({
            event: 'broadcast_scheduler_failed',
            message: error instanceof Error ? error.message : String(error),
          }),
        );
      });
    }, intervalMs);
    this.schedulerTimer.unref();
  }

  stopScheduler(): void {
    if (!this.schedulerTimer) return;
    clearInterval(this.schedulerTimer);
    this.schedulerTimer = null;
  }
}
