import type { DeviceRepository } from '../../devices/repositories/device-repository.js';
import type { PushDeliveryProvider } from '../providers/push-delivery-provider.js';
import type {
  Broadcast,
  BroadcastCategory,
  BroadcastRepository,
  BroadcastStatus,
} from '../repositories/broadcast-repository.js';

/**
 * Delivery reporting for the broadcaster.
 *
 * Aggregates are derived from the broadcast records themselves rather than
 * from a new set of repository queries: each record already carries its
 * audience, delivered and failed counts, and the volumes here are hundreds of
 * rows, not millions. If the history ever outgrows that, this is the seam to
 * push down into Mongo aggregation.
 */

export interface BroadcastPoint {
  date: string;
  value: number;
}

export interface BroadcastSlice {
  label: string;
  value: number;
}

export interface BroadcastAnalytics {
  /** Window used for the daily series. */
  days: number;
  transport: { name: string; configured: boolean };
  devices: {
    total: number;
    byPlatform: BroadcastSlice[];
  };
  totals: {
    total: number;
    sent: number;
    scheduled: number;
    drafts: number;
    failed: number;
    cancelled: number;
    audience: number;
    delivered: number;
    failedDeliveries: number;
    /** Delivered / audience across sent broadcasts, as a percentage. */
    deliveryRate: number;
  };
  daily: {
    delivered: BroadcastPoint[];
    failed: BroadcastPoint[];
  };
  byCategory: BroadcastSlice[];
  byStatus: BroadcastSlice[];
  /** Sent broadcasts with the widest reach, newest first on ties. */
  topByReach: {
    id: string;
    title: string;
    category: BroadcastCategory;
    sentAt: string | null;
    audienceCount: number;
    deliveredCount: number;
    failedCount: number;
    deliveryRate: number;
  }[];
}

function isoDay(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/** Zero-filled day buckets, so a quiet day is a zero rather than a gap. */
function emptySeries(days: number, now: Date): Map<string, number> {
  const series = new Map<string, number>();
  for (let offset = days - 1; offset >= 0; offset -= 1) {
    const day = new Date(now);
    day.setUTCDate(day.getUTCDate() - offset);
    series.set(isoDay(day), 0);
  }
  return series;
}

function toPoints(series: Map<string, number>): BroadcastPoint[] {
  return [...series.entries()].map(([date, value]) => ({ date, value }));
}

function countBy<T extends string>(
  values: T[],
): { label: T; value: number }[] {
  const counts = new Map<T, number>();
  for (const value of values) counts.set(value, (counts.get(value) ?? 0) + 1);
  return [...counts.entries()]
    .map(([label, value]) => ({ label, value }))
    .sort((left, right) => right.value - left.value);
}

function rate(part: number, whole: number): number {
  if (whole <= 0) return 0;
  return Math.round((part / whole) * 1000) / 10;
}

export class BroadcastAnalyticsService {
  constructor(
    private readonly repository: BroadcastRepository,
    private readonly devices: DeviceRepository,
    private readonly push: PushDeliveryProvider,
    /** How many historical broadcasts to aggregate over. */
    private readonly historyLimit = 200,
  ) {}

  async report(days: number, now = new Date()): Promise<BroadcastAnalytics> {
    const [broadcasts, byPlatform] = await Promise.all([
      this.repository.list(this.historyLimit),
      this.devices.countByPlatform(),
    ]);

    const delivered = emptySeries(days, now);
    const failed = emptySeries(days, now);

    let audience = 0;
    let deliveredTotal = 0;
    let failedTotal = 0;

    for (const broadcast of broadcasts) {
      if (broadcast.status === 'sent' || broadcast.status === 'sending') {
        audience += broadcast.audienceCount;
        deliveredTotal += broadcast.deliveredCount;
        failedTotal += broadcast.failedCount;
      }
      const sentAt = broadcast.sentAt;
      if (!sentAt) continue;
      const day = isoDay(sentAt);
      if (delivered.has(day)) {
        delivered.set(day, (delivered.get(day) ?? 0) + broadcast.deliveredCount);
        failed.set(day, (failed.get(day) ?? 0) + broadcast.failedCount);
      }
    }

    const statuses = broadcasts.map((broadcast) => broadcast.status);
    const countOf = (status: BroadcastStatus): number =>
      statuses.filter((value) => value === status).length;

    const deviceCounts: BroadcastSlice[] = Object.entries(byPlatform)
      .map(([label, value]) => ({ label, value }))
      .filter((slice) => slice.value > 0);

    return {
      days,
      transport: {
        name: this.push.name,
        configured: this.push.configured,
      },
      devices: {
        total: deviceCounts.reduce((sum, slice) => sum + slice.value, 0),
        byPlatform: deviceCounts,
      },
      totals: {
        total: broadcasts.length,
        sent: countOf('sent'),
        scheduled: countOf('scheduled'),
        drafts: countOf('draft'),
        failed: countOf('failed'),
        cancelled: countOf('cancelled'),
        audience,
        delivered: deliveredTotal,
        failedDeliveries: failedTotal,
        deliveryRate: rate(deliveredTotal, audience),
      },
      daily: {
        delivered: toPoints(delivered),
        failed: toPoints(failed),
      },
      byCategory: countBy(
        broadcasts.map((broadcast) => broadcast.category),
      ) as BroadcastSlice[],
      byStatus: countBy(statuses) as BroadcastSlice[],
      topByReach: broadcasts
        .filter((broadcast) => broadcast.status === 'sent')
        .sort((left, right) => right.audienceCount - left.audienceCount)
        .slice(0, 8)
        .map((broadcast: Broadcast) => ({
          id: broadcast.id,
          title: broadcast.title,
          category: broadcast.category,
          sentAt: broadcast.sentAt ? broadcast.sentAt.toISOString() : null,
          audienceCount: broadcast.audienceCount,
          deliveredCount: broadcast.deliveredCount,
          failedCount: broadcast.failedCount,
          deliveryRate: rate(broadcast.deliveredCount, broadcast.audienceCount),
        })),
    };
  }
}
