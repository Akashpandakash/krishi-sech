export interface TimeSeriesPoint {
  date: string;
  value: number;
}

export interface DistributionSlice {
  label: string;
  value: number;
}

/**
 * Every telemetry response carries `configured`. When it is false the panel
 * shows setup instructions rather than an empty chart — an unconfigured
 * integration and a genuinely quiet week must never look the same.
 */
export interface NotConfigured {
  configured: false;
  /** Which integration is missing, for the setup panel. */
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

export interface CrashTotals {
  events: number;
  fatalEvents: number;
  nonFatalEvents: number;
  affectedUsers: number;
  distinctIssues: number;
}

export interface CrashReport {
  configured: true;
  source: 'bigquery';
  dataset: string;
  table: string;
  days: number;
  totals: CrashTotals;
  daily: {
    fatal: TimeSeriesPoint[];
    nonFatal: TimeSeriesPoint[];
  };
  topIssues: CrashIssue[];
  byAppVersion: DistributionSlice[];
  byDevice: DistributionSlice[];
  byOsVersion: DistributionSlice[];
}

export type AnalyticsResponse = AnalyticsReport | NotConfigured;
export type CrashResponse = CrashReport | NotConfigured;
