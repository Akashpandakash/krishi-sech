export interface OverviewMetrics {
  totalUsers: number;
  activeUsers: number;
  blockedUsers: number;
  newUsersToday: number;
  newUsers7d: number;
  newUsers30d: number;
  returningUsers7d: number;
  returningUsers30d: number;
  farmProfiles: number;
  totalLandAcres: number;
  totalCrops: number;
  crops30d: number;
  totalTasks: number;
  pendingTasks: number;
  completedTasks: number;
  overdueTasks: number;
  fertilizerRecommendations: number;
  irrigationRecommendations: number;
}

export interface TimeSeriesPoint {
  date: string;
  value: number;
}

export interface GrowthMetrics {
  signups: TimeSeriesPoint[];
  logins: TimeSeriesPoint[];
  cropsCreated: TimeSeriesPoint[];
  tasksCompleted: TimeSeriesPoint[];
}

export interface DistributionSlice {
  label: string;
  value: number;
}

export interface DistributionMetrics {
  languages: DistributionSlice[];
  states: DistributionSlice[];
  cropNames: DistributionSlice[];
  soilTypes: DistributionSlice[];
  irrigationMethods: DistributionSlice[];
  growthStages: DistributionSlice[];
  farmerTypes: DistributionSlice[];
  taskTypes: DistributionSlice[];
  cropHealth: DistributionSlice[];
}

export interface ActivityEntry {
  type: 'signup' | 'crop' | 'task';
  label: string;
  detail: string;
  at: Date;
}

export interface AdminUserSummary {
  id: string;
  /** Null for Google accounts, which never carry a phone number. */
  phone: string | null;
  email: string | null;
  name: string | null;
  preferredLanguage: string;
  state: string | null;
  district: string | null;
  village: string | null;
  isActive: boolean;
  createdAt: Date;
  lastSeenAt: Date | null;
  cropCount: number;
  taskCount: number;
}

export interface AdminUserDetail extends AdminUserSummary {
  farm: {
    farmName: string;
    farmerType: string;
    totalLandArea: number;
    landUnit: string;
    soilType: string;
    irrigationSource: string;
    mainCrops: string[];
    coarseLocation: string | null;
  } | null;
  crops: {
    id: string;
    cropName: string;
    variety: string;
    growthStage: string;
    healthStatus: string;
    landArea: number;
    landUnit: string;
    sowingDate: Date;
    expectedHarvestDate: Date | null;
  }[];
  tasks: {
    id: string;
    cropId: string;
    taskType: string;
    status: string;
    dueDate: Date;
  }[];
  sessions: { createdAt: Date; expiresAt: Date; revoked: boolean }[];
  /** Push registrations. Empty means the account cannot receive a broadcast. */
  devices: {
    platform: string;
    createdAt: Date;
    updatedAt: Date;
    /** Last 12 characters only — enough to correlate, useless if leaked. */
    tokenSuffix: string;
  }[];
}

export interface UserListQuery {
  search?: string;
  status?: 'all' | 'active' | 'blocked';
  language?: string;
  state?: string;
  sort?: 'recent' | 'oldest' | 'crops' | 'lastSeen';
  page: number;
  limit: number;
}

export interface UserListResult {
  users: AdminUserSummary[];
  total: number;
  page: number;
  limit: number;
}

export interface AudienceFilter {
  language?: string | null;
  state?: string | null;
  farmerType?: string | null;
  onlyActive: boolean;
}

export interface AdminAnalyticsRepository {
  /** Always `database`. The generated-sample-data implementation was removed
   *  along with the in-memory fallbacks; the panel only ever shows real rows. */
  readonly source: 'database';
  overview(): Promise<OverviewMetrics>;
  growth(days: number): Promise<GrowthMetrics>;
  distributions(): Promise<DistributionMetrics>;
  recentActivity(limit: number): Promise<ActivityEntry[]>;
  listUsers(query: UserListQuery): Promise<UserListResult>;
  getUser(userId: string): Promise<AdminUserDetail | null>;
  setUserActive(userId: string, isActive: boolean): Promise<void>;
  countAudience(filter: AudienceFilter): Promise<number>;
  /** Distinct values available for audience and list filters. */
  filterOptions(): Promise<{
    languages: string[];
    states: string[];
    farmerTypes: string[];
  }>;
}
