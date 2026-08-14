/**
 * Mirrors of the Express API's admin contracts.
 *
 * Dates cross the wire as ISO-8601 strings, so every field the server types as
 * `Date` is typed `string` here. Convert at the render edge, never in state.
 */

export const adminRoles = ['owner', 'admin', 'analyst'] as const;
export type AdminRole = (typeof adminRoles)[number];

export interface PublicAdminUser {
  id: string;
  email: string;
  name: string;
  role: AdminRole;
  isActive: boolean;
  lastLoginAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminSessionResponse {
  admin: PublicAdminUser;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

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

/** Always `database` — the generated-sample-data repository was removed, so
 *  the panel can no longer show anything but real rows. */
export type MetricsSource = 'database';

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
  at: string;
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
  createdAt: string;
  lastSeenAt: string | null;
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
    sowingDate: string;
    expectedHarvestDate: string | null;
  }[];
  tasks: {
    id: string;
    cropId: string;
    taskType: string;
    status: string;
    dueDate: string;
  }[];
  sessions: { createdAt: string; expiresAt: string; revoked: boolean }[];
  /** Push registrations. Empty means this account cannot receive a broadcast. */
  devices: {
    platform: string;
    createdAt: string;
    updatedAt: string;
    /** Last 12 characters only — the full token is a send capability. */
    tokenSuffix: string;
  }[];
}

export type UserStatusFilter = 'all' | 'active' | 'blocked';
export type UserSort = 'recent' | 'oldest' | 'crops' | 'lastSeen';

export interface UserListResult {
  users: AdminUserSummary[];
  total: number;
  page: number;
  limit: number;
}

export interface FilterOptions {
  languages: string[];
  states: string[];
  farmerTypes: string[];
}

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

/** Which push transport the server is actually wired to. `configured: false`
 *  means nothing will physically be delivered to a device. */
export interface PushTransport {
  name: string;
  configured: boolean;
}

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
  scheduledAt: string | null;
  sentAt: string | null;
  audienceCount: number;
  deliveredCount: number;
  failedCount: number;
  failureReason: string | null;
  createdAt: string;
  updatedAt: string;
}

/* ------------------------------------------------------- market catalogue */

export const marketCategories = ['seeds', 'fertilizers', 'tools'] as const;
export type MarketCategory = (typeof marketCategories)[number];

export const marketUnits = ['bag', 'pack', 'piece', 'kg', 'litre'] as const;
export type MarketUnit = (typeof marketUnits)[number];

/** Language codes the app can render. `en` is the fallback for the rest. */
export const supportedLocaleCodes = [
  'en',
  'hi',
  'bn',
  'as',
  'brx',
  'doi',
  'gu',
  'kn',
  'ks',
  'kok',
  'mai',
  'ml',
  'mni',
  'mr',
  'ne',
  'or',
  'pa',
  'sa',
  'sat',
  'sd',
  'ta',
  'te',
  'ur',
] as const;
export type SupportedLocaleCode = (typeof supportedLocaleCodes)[number];

export const localeNames: Record<string, string> = {
  en: 'English',
  hi: 'Hindi',
  bn: 'Bengali',
  as: 'Assamese',
  brx: 'Bodo',
  doi: 'Dogri',
  gu: 'Gujarati',
  kn: 'Kannada',
  ks: 'Kashmiri',
  kok: 'Konkani',
  mai: 'Maithili',
  ml: 'Malayalam',
  mni: 'Manipuri',
  mr: 'Marathi',
  ne: 'Nepali',
  or: 'Odia',
  pa: 'Punjabi',
  sa: 'Sanskrit',
  sat: 'Santali',
  sd: 'Sindhi',
  ta: 'Tamil',
  te: 'Telugu',
  ur: 'Urdu',
};

export type LocalizedText = { en: string } & Record<string, string>;

export interface MarketProductInput {
  name: LocalizedText;
  description: LocalizedText;
  category: MarketCategory;
  price: number;
  unit: MarketUnit;
  stockQuantity: number;
  vendor: string;
  isActive: boolean;
}

export interface MarketProduct extends MarketProductInput {
  id: string;
  createdAt: string;
  updatedAt: string;
}

/* ------------------------------------------------------------ mandi prices */

export const mandiSources = ['agmarknet', 'manual'] as const;
export type MandiSource = (typeof mandiSources)[number];

export interface MandiPriceRecord {
  id: string;
  seriesKey: string;
  source: MandiSource;
  state: string;
  district: string;
  market: string;
  commodity: string;
  variety: string | null;
  grade: string | null;
  arrivalDate: string;
  minPrice: number;
  maxPrice: number;
  modalPrice: number;
  recordedAt: string;
}

export interface MandiPriceInput {
  state: string;
  district: string;
  market: string;
  commodity: string;
  variety: string | null;
  grade: string | null;
  arrivalDate: string;
  minPrice: number;
  maxPrice: number;
  modalPrice: number;
}

export interface MandiFilterOptions {
  states: string[];
  districts: string[];
  commodities: string[];
}

export interface AuditLogEntry {
  id: string;
  adminId: string;
  adminEmail: string;
  action: string;
  targetType: string | null;
  targetId: string | null;
  summary: string;
  ipAddress: string | null;
  createdAt: string;
}

/** Only `owner` and `admin` may mutate; `analyst` is read-only. */
export function canWrite(role: AdminRole | undefined): boolean {
  return role === 'owner' || role === 'admin';
}

export function isOwner(role: AdminRole | undefined): boolean {
  return role === 'owner';
}

/* ---------------------------------------------------------- Firebase telemetry */

/**
 * Both telemetry responses are discriminated on `configured`. An unconfigured
 * integration and a genuinely quiet week must never render the same way, so
 * the union forces the caller to handle the setup case.
 */
export interface TelemetryNotConfigured {
  configured: false;
  integration: 'analytics' | 'crashlytics';
  reason: string;
  missing: string[];
}

export interface AnalyticsTotals {
  activeUsers: number;
  newUsers: number;
  sessions: number;
  screenViews: number;
  eventCount: number;
  averageEngagementSeconds: number;
}

export interface AnalyticsReport {
  configured: true;
  source: 'ga4';
  propertyId: string;
  days: number;
  totals: AnalyticsTotals;
  daily: {
    activeUsers: TimeSeriesPoint[];
    newUsers: TimeSeriesPoint[];
  };
  topScreens: DistributionSlice[];
  byAppVersion: DistributionSlice[];
  byPlatform: DistributionSlice[];
  byRegion: DistributionSlice[];
}

export interface CrashIssue {
  issueId: string;
  title: string;
  subtitle: string;
  events: number;
  affectedUsers: number;
  fatal: boolean;
  latestVersion: string;
  lastSeen: string | null;
}

export interface CrashReport {
  configured: true;
  source: 'bigquery';
  dataset: string;
  table: string;
  days: number;
  totals: {
    events: number;
    fatalEvents: number;
    nonFatalEvents: number;
    affectedUsers: number;
    distinctIssues: number;
  };
  daily: {
    fatal: TimeSeriesPoint[];
    nonFatal: TimeSeriesPoint[];
  };
  topIssues: CrashIssue[];
  byAppVersion: DistributionSlice[];
  byDevice: DistributionSlice[];
  byOsVersion: DistributionSlice[];
}

export type AnalyticsResponse = AnalyticsReport | TelemetryNotConfigured;
export type CrashResponse = CrashReport | TelemetryNotConfigured;

/* ------------------------------------------------------ Broadcast analytics */

export interface BroadcastAnalytics {
  days: number;
  transport: PushTransport;
  devices: {
    total: number;
    byPlatform: DistributionSlice[];
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
    /** Percentage, already rounded to one decimal by the server. */
    deliveryRate: number;
  };
  daily: {
    delivered: TimeSeriesPoint[];
    failed: TimeSeriesPoint[];
  };
  byCategory: DistributionSlice[];
  byStatus: DistributionSlice[];
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
