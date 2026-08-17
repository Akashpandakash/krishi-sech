import type { PipelineStage } from 'mongoose';

/** Loose shape for filters and aggregation stages assembled at runtime. */
type Document = Record<string, any>;

import type { MongoDatabase } from '../../database/mongo-database.js';
import type {
  ActivityEntry,
  AdminAnalyticsRepository,
  AdminUserDetail,
  AdminUserSummary,
  AudienceFilter,
  DistributionMetrics,
  DistributionSlice,
  GrowthMetrics,
  OverviewMetrics,
  TimeSeriesPoint,
  UserListQuery,
  UserListResult,
} from './admin-analytics-repository.js';

/** Farmers report in local time, so day buckets follow IST rather than UTC. */
export const reportingTimezone = 'Asia/Kolkata';

/**
 * Land units are entered per region and only bigha/katha vary in practice;
 * these are the conventional eastern-India equivalents used for reporting
 * totals, so the acreage figure is an estimate rather than a survey number.
 */
const acresPerUnit: Record<string, number> = {
  acre: 1,
  hectare: 2.47105,
  bigha: 0.3306,
  katha: 0.0165,
};

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function startOfDaysAgo(days: number): Date {
  return new Date(Date.now() - days * 24 * 60 * 60 * 1000);
}

function dayKeyExpression(field: string): Document {
  return {
    $dateToString: {
      format: '%Y-%m-%d',
      date: `$${field}`,
      timezone: reportingTimezone,
    },
  };
}

/** Turns sparse `{_id: '2026-08-01', value: n}` rows into a dense day series. */
export function fillSeries(
  rows: { _id: string; value: number }[],
  days: number,
  now = new Date(),
): TimeSeriesPoint[] {
  const byDay = new Map(rows.map((row) => [row._id, row.value]));
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: reportingTimezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  const series: TimeSeriesPoint[] = [];
  for (let offset = days - 1; offset >= 0; offset -= 1) {
    const date = formatter.format(
      new Date(now.getTime() - offset * 24 * 60 * 60 * 1000),
    );
    series.push({ date, value: byDay.get(date) ?? 0 });
  }
  return series;
}

function toSlices(
  rows: { _id: unknown; value: number }[],
  fallbackLabel = 'Unknown',
): DistributionSlice[] {
  return rows.map((row) => ({
    label:
      typeof row._id === 'string' && row._id.trim() ? row._id : fallbackLabel,
    value: row.value,
  }));
}

export class MongoAdminAnalyticsRepository implements AdminAnalyticsRepository {
  readonly source = 'database' as const;

  constructor(private readonly database: MongoDatabase) {}

  async overview(): Promise<OverviewMetrics> {
    const now = new Date();
    const startOfToday = new Date(
      new Intl.DateTimeFormat('en-CA', {
        timeZone: reportingTimezone,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      }).format(now) + 'T00:00:00+05:30',
    );
    const [
      totalUsers,
      activeUsers,
      newUsersToday,
      newUsers7d,
      newUsers30d,
      returningUsers7d,
      returningUsers30d,
      farmProfiles,
      landRows,
      totalCrops,
      crops30d,
      taskRows,
      overdueTasks,
      fertilizerRecommendations,
      irrigationRecommendations,
    ] = await Promise.all([
      this.database.users.countDocuments({}),
      this.database.users.countDocuments({ isActive: true }),
      this.database.users.countDocuments({ createdAt: { $gte: startOfToday } }),
      this.database.users.countDocuments({
        createdAt: { $gte: startOfDaysAgo(7) },
      }),
      this.database.users.countDocuments({
        createdAt: { $gte: startOfDaysAgo(30) },
      }),
      this.distinctSessionUsers(7),
      this.distinctSessionUsers(30),
      this.database.farmProfiles.countDocuments({}),
      this.database.farmProfiles
        .aggregate<{ _id: string; area: number }>([
          { $group: { _id: '$landUnit', area: { $sum: '$totalLandArea' } } },
        ])
        ,
      this.database.crops.countDocuments({}),
      this.database.crops.countDocuments({
        createdAt: { $gte: startOfDaysAgo(30) },
      }),
      this.database.calendarTasks
        .aggregate<{ _id: string; value: number }>([
          { $group: { _id: '$status', value: { $sum: 1 } } },
        ])
        ,
      this.database.calendarTasks.countDocuments({
        status: 'pending',
        dueDate: { $lt: now },
      }),
      this.database.fertilizerRecommendations.countDocuments({}),
      this.database.irrigationRecommendations.countDocuments({}),
    ]);

    const taskCounts = new Map(taskRows.map((row) => [row._id, row.value]));
    const totalLandAcres = landRows.reduce(
      (total, row) => total + row.area * (acresPerUnit[row._id] ?? 1),
      0,
    );
    const pendingTasks = taskCounts.get('pending') ?? 0;
    const completedTasks = taskCounts.get('completed') ?? 0;

    return {
      totalUsers,
      activeUsers,
      blockedUsers: totalUsers - activeUsers,
      newUsersToday,
      newUsers7d,
      newUsers30d,
      returningUsers7d,
      returningUsers30d,
      farmProfiles,
      totalLandAcres: Math.round(totalLandAcres * 100) / 100,
      totalCrops,
      crops30d,
      totalTasks: pendingTasks + completedTasks,
      pendingTasks,
      completedTasks,
      overdueTasks,
      fertilizerRecommendations,
      irrigationRecommendations,
    };
  }

  private async distinctSessionUsers(days: number): Promise<number> {
    const rows = await this.database.refreshTokens
      .aggregate<{ value: number }>([
        { $match: { createdAt: { $gte: startOfDaysAgo(days) } } },
        { $group: { _id: '$userId' } },
        { $count: 'value' },
      ])
      ;
    return rows[0]?.value ?? 0;
  }

  async growth(days: number): Promise<GrowthMetrics> {
    const since = startOfDaysAgo(days);
    const byDay = (field: string) => [
      { $match: { [field]: { $gte: since } } },
      { $group: { _id: dayKeyExpression(field), value: { $sum: 1 } } },
    ];
    const [signups, logins, cropsCreated, tasksCompleted] = await Promise.all([
      this.database.users
        .aggregate<{ _id: string; value: number }>(byDay('createdAt'))
        ,
      this.database.refreshTokens
        .aggregate<{ _id: string; value: number }>(byDay('createdAt'))
        ,
      this.database.crops
        .aggregate<{ _id: string; value: number }>(byDay('createdAt'))
        ,
      this.database.calendarTasks
        .aggregate<{ _id: string; value: number }>([
          { $match: { status: 'completed', updatedAt: { $gte: since } } },
          { $group: { _id: dayKeyExpression('updatedAt'), value: { $sum: 1 } } },
        ])
        ,
    ]);
    return {
      signups: fillSeries(signups, days),
      logins: fillSeries(logins, days),
      cropsCreated: fillSeries(cropsCreated, days),
      tasksCompleted: fillSeries(tasksCompleted, days),
    };
  }

  async distributions(): Promise<DistributionMetrics> {
    const top = (field: string, limit = 8) => [
      { $group: { _id: `$${field}`, value: { $sum: 1 } } },
      { $sort: { value: -1 as const, _id: 1 as const } },
      { $limit: limit },
    ];
    const [
      languages,
      states,
      cropNames,
      soilTypes,
      irrigationMethods,
      growthStages,
      farmerTypes,
      taskTypes,
      cropHealth,
    ] = await Promise.all([
      this.database.users
        .aggregate<{ _id: string; value: number }>(top('preferredLanguage', 12))
        ,
      this.database.users
        .aggregate<{ _id: string; value: number }>([
          { $match: { state: { $nin: [null, ''] } } },
          ...top('state', 10),
        ])
        ,
      this.database.crops
        .aggregate<{ _id: string; value: number }>(top('cropName', 10))
        ,
      this.database.crops
        .aggregate<{ _id: string; value: number }>(top('soilType'))
        ,
      this.database.crops
        .aggregate<{ _id: string; value: number }>(top('irrigationMethod'))
        ,
      this.database.crops
        .aggregate<{ _id: string; value: number }>(top('growthStage'))
        ,
      this.database.farmProfiles
        .aggregate<{ _id: string; value: number }>(top('farmerType'))
        ,
      this.database.calendarTasks
        .aggregate<{ _id: string; value: number }>(top('taskType'))
        ,
      this.database.crops
        .aggregate<{ _id: string; value: number }>(top('healthStatus'))
        ,
    ]);
    return {
      languages: toSlices(languages),
      states: toSlices(states),
      cropNames: toSlices(cropNames),
      soilTypes: toSlices(soilTypes),
      irrigationMethods: toSlices(irrigationMethods),
      growthStages: toSlices(growthStages),
      farmerTypes: toSlices(farmerTypes),
      taskTypes: toSlices(taskTypes),
      cropHealth: toSlices(cropHealth),
    };
  }

  async recentActivity(limit: number): Promise<ActivityEntry[]> {
    const [users, crops, tasks] = await Promise.all([
      this.database.users
        .find({}, { phone: 1, name: 1, createdAt: 1 })
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean<
          { phone: string | null; name: string | null; createdAt: Date }[]
        >(),
      this.database.crops
        .find({}, { cropName: 1, variety: 1, createdAt: 1 })
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean<{ cropName: string; variety: string; createdAt: Date }[]>(),
      this.database.calendarTasks
        .find({}, { taskType: 1, status: 1, createdAt: 1 })
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean<{ taskType: string; status: string; createdAt: Date }[]>(),
    ]);
    const entries: ActivityEntry[] = [
      ...users.map((user) => ({
        type: 'signup' as const,
        label: user.name?.trim() || maskPhone(user.phone ?? null),
        detail: 'joined Krishi Sech',
        at: user.createdAt,
      })),
      ...crops.map((crop) => ({
        type: 'crop' as const,
        label: crop.cropName,
        detail: crop.variety ? `${crop.variety} added` : 'crop added',
        at: crop.createdAt,
      })),
      ...tasks.map((task) => ({
        type: 'task' as const,
        label: task.taskType,
        detail: `task ${task.status}`,
        at: task.createdAt,
      })),
    ];
    return entries
      .sort((left, right) => right.at.getTime() - left.at.getTime())
      .slice(0, limit);
  }

  async listUsers(query: UserListQuery): Promise<UserListResult> {
    const match: Document = {};
    if (query.status === 'active') match.isActive = true;
    if (query.status === 'blocked') match.isActive = false;
    if (query.language) match.preferredLanguage = query.language;
    if (query.state) match.state = query.state;
    if (query.search?.trim()) {
      const pattern = new RegExp(escapeRegExp(query.search.trim()), 'i');
      match.$or = [
        { phone: pattern },
        { name: pattern },
        { district: pattern },
        { village: pattern },
      ];
    }
    const sort: Document =
      query.sort === 'oldest'
        ? { createdAt: 1 }
        : query.sort === 'crops'
          ? { cropCount: -1, createdAt: -1 }
          : query.sort === 'lastSeen'
            ? { lastSeenAt: -1, createdAt: -1 }
            : { createdAt: -1 };
    const rows = await this.database.users
      .aggregate<{ users: Document[]; total: { value: number }[] }>(<PipelineStage[]>[
        { $match: match },
        {
          $facet: {
            total: [{ $count: 'value' }],
            users: [
              ...this.userSummaryStages(),
              { $sort: sort },
              { $skip: (query.page - 1) * query.limit },
              { $limit: query.limit },
            ],
          },
        },
      ])
      ;
    const facet = rows[0];
    return {
      users: (facet?.users ?? []).map(toUserSummary),
      total: facet?.total?.[0]?.value ?? 0,
      page: query.page,
      limit: query.limit,
    };
  }

  private userSummaryStages(): Document[] {
    return [
      {
        $lookup: {
          from: 'crops',
          localField: '_id',
          foreignField: 'userId',
          as: 'cropDocs',
          pipeline: [{ $project: { _id: 1 } }],
        },
      },
      {
        $lookup: {
          from: 'calendar_tasks',
          localField: '_id',
          foreignField: 'userId',
          as: 'taskDocs',
          pipeline: [{ $project: { _id: 1 } }],
        },
      },
      {
        $lookup: {
          from: 'refresh_tokens',
          localField: '_id',
          foreignField: 'userId',
          as: 'sessionDocs',
          pipeline: [
            { $sort: { createdAt: -1 } },
            { $limit: 1 },
            { $project: { createdAt: 1 } },
          ],
        },
      },
      {
        $addFields: {
          cropCount: { $size: '$cropDocs' },
          taskCount: { $size: '$taskDocs' },
          lastSeenAt: {
            $ifNull: [{ $first: '$sessionDocs.createdAt' }, null],
          },
        },
      },
      { $project: { cropDocs: 0, taskDocs: 0, sessionDocs: 0 } },
    ];
  }

  async getUser(userId: string): Promise<AdminUserDetail | null> {
    const rows = await this.database.users
      .aggregate<Document>(<PipelineStage[]>[
        { $match: { _id: userId } },
        ...this.userSummaryStages(),
        { $limit: 1 },
      ])
      ;
    const user = rows[0];
    if (!user) return null;
    const [farm, crops, tasks, sessions, devices] = await Promise.all([
      this.database.farmProfiles.findOne({ userId }).lean(),
      this.database.crops
        .find({ userId })
        .sort({ createdAt: -1 })
        .limit(50)
        .lean(),
      this.database.calendarTasks
        .find({ userId })
        .sort({ dueDate: -1 })
        .limit(50)
        .lean(),
      this.database.refreshTokens
        .find({ userId })
        .sort({ createdAt: -1 })
        .limit(10)
        .lean(),
      this.database.devices
        .find({ userId })
        .sort({ updatedAt: -1 })
        .limit(10)
        .lean(),
    ]);
    return {
      ...toUserSummary(user),
      farm: farm
        ? {
            farmName: farm.farmName,
            farmerType: farm.farmerType,
            totalLandArea: farm.totalLandArea,
            landUnit: farm.landUnit,
            soilType: farm.soilType,
            irrigationSource: farm.irrigationSource,
            mainCrops: farm.mainCrops,
            coarseLocation: farm.coarseLocation,
          }
        : null,
      crops: crops.map((crop) => ({
        id: crop._id,
        cropName: crop.cropName,
        variety: crop.variety,
        growthStage: crop.growthStage,
        healthStatus: crop.healthStatus,
        landArea: crop.landArea,
        landUnit: crop.landUnit,
        sowingDate: crop.sowingDate,
        expectedHarvestDate: crop.expectedHarvestDate,
      })),
      tasks: tasks.map((task) => ({
        id: task._id,
        cropId: task.cropId,
        taskType: task.taskType,
        status: task.status,
        dueDate: task.dueDate,
      })),
      sessions: sessions.map((session) => ({
        createdAt: session.createdAt,
        expiresAt: session.expiresAt,
        revoked: session.revokedAt !== null,
      })),
      devices: devices.map((device) => ({
        platform: device.platform,
        createdAt: device.createdAt,
        updatedAt: device.updatedAt,
        // Never return the whole token: it is a send capability for this
        // handset, and the panel only needs enough to tell devices apart.
        tokenSuffix: device.token.slice(-12),
      })),
    };
  }

  async setUserActive(userId: string, isActive: boolean): Promise<void> {
    await this.database.users.updateOne(
      { _id: userId },
      { $set: { isActive, updatedAt: new Date() } },
    );
    if (!isActive) {
      await this.database.refreshTokens.updateMany(
        { userId, revokedAt: null },
        { $set: { revokedAt: new Date() } },
      );
    }
  }

  async countAudience(filter: AudienceFilter): Promise<number> {
    const match = audienceMatch(filter);
    if (!filter.farmerType) return this.database.users.countDocuments(match);
    const rows = await this.database.users
      .aggregate<{ value: number }>([
        { $match: match },
        {
          $lookup: {
            from: 'farm_profiles',
            localField: '_id',
            foreignField: 'userId',
            as: 'farm',
          },
        },
        { $match: { 'farm.farmerType': filter.farmerType } },
        { $count: 'value' },
      ])
      ;
    return rows[0]?.value ?? 0;
  }

  async filterOptions() {
    const [languages, states, farmerTypes] = await Promise.all([
      this.database.users.distinct('preferredLanguage', {}),
      this.database.users.distinct('state', { state: { $nin: [null, ''] } }),
      this.database.farmProfiles.distinct('farmerType', {}),
    ]);
    return {
      languages: languages.filter(Boolean).sort(),
      states: (states as string[]).filter(Boolean).sort(),
      farmerTypes: farmerTypes.filter(Boolean).sort(),
    };
  }
}

export function audienceMatch(filter: AudienceFilter): Document {
  const match: Document = {};
  if (filter.onlyActive) match.isActive = true;
  if (filter.language) match.preferredLanguage = filter.language;
  if (filter.state) match.state = filter.state;
  return match;
}

export function maskPhone(phone: string | null): string {
  if (!phone) return 'Google account';
  return phone.length <= 4
    ? phone
    : `${phone.slice(0, phone.length - 4).replace(/\d/g, '•')}${phone.slice(-4)}`;
}

function toUserSummary(document: Document): AdminUserSummary {
  return {
    id: document._id,
    phone: document.phone ?? null,
    email: document.email ?? null,
    name: document.name ?? null,
    preferredLanguage: document.preferredLanguage,
    state: document.state ?? null,
    district: document.district ?? null,
    village: document.village ?? null,
    isActive: document.isActive,
    createdAt: document.createdAt,
    lastSeenAt: document.lastSeenAt ?? null,
    cropCount: document.cropCount ?? 0,
    taskCount: document.taskCount ?? 0,
  };
}
