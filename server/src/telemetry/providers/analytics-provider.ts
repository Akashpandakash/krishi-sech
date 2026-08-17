import {
  GoogleAccessTokenProvider,
  googleApiPost,
  type GoogleServiceAccount,
} from '../../common/google-service-account.js';
import type {
  AnalyticsReport,
  DistributionSlice,
  TimeSeriesPoint,
} from '../telemetry-types.js';

/**
 * Firebase Analytics is Google Analytics 4 underneath, and GA4 exposes a read
 * API — so this talks to the Data API directly rather than to Firebase.
 *
 * Requires: the GA4 property linked to the Firebase project, the Analytics
 * Data API enabled, and the service account granted Viewer on the property.
 */

const ANALYTICS_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly';

interface RunReportResponse {
  dimensionHeaders?: { name: string }[];
  metricHeaders?: { name: string }[];
  rows?: {
    dimensionValues?: { value: string }[];
    metricValues?: { value: string }[];
  }[];
  rowCount?: number;
}

interface ReportRequest {
  dimensions?: { name: string }[];
  metrics: { name: string }[];
  dateRanges: { startDate: string; endDate: string }[];
  orderBys?: unknown[];
  limit?: string;
}

function toNumber(value: string | undefined): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

/** GA4 returns `YYYYMMDD`; the charts want ISO dates. */
function toIsoDate(compact: string): string {
  if (!/^\d{8}$/.test(compact)) return compact;
  return `${compact.slice(0, 4)}-${compact.slice(4, 6)}-${compact.slice(6, 8)}`;
}

function sliceRows(
  response: RunReportResponse,
  metricIndex = 0,
): DistributionSlice[] {
  return (response.rows ?? []).map((row) => ({
    label: row.dimensionValues?.[0]?.value?.trim() || 'Unknown',
    value: toNumber(row.metricValues?.[metricIndex]?.value),
  }));
}

export class GoogleAnalyticsProvider {
  readonly configured = true;

  private readonly tokens: GoogleAccessTokenProvider;

  constructor(
    serviceAccount: GoogleServiceAccount,
    private readonly propertyId: string,
    private readonly timeoutMs = 20_000,
    fetchImplementation: typeof fetch = fetch,
  ) {
    this.tokens = new GoogleAccessTokenProvider(
      serviceAccount,
      ANALYTICS_SCOPE,
      timeoutMs,
      fetchImplementation,
    );
    this.fetchImplementation = fetchImplementation;
  }

  private readonly fetchImplementation: typeof fetch;

  private runReport(request: ReportRequest): Promise<RunReportResponse> {
    return googleApiPost<RunReportResponse>(
      `https://analyticsdata.googleapis.com/v1beta/properties/${encodeURIComponent(
        this.propertyId,
      )}:runReport`,
      request,
      {
        tokens: this.tokens,
        timeoutMs: this.timeoutMs,
        fetchImplementation: this.fetchImplementation,
        apiName: 'Google Analytics Data API',
      },
    );
  }

  async report(days: number): Promise<AnalyticsReport> {
    const dateRanges = [{ startDate: `${days}daysAgo`, endDate: 'today' }];

    // One round trip per report shape. They are independent, so they run
    // together rather than serially.
    const [totals, daily, screens, versions, platforms, countries] =
      await Promise.all([
        this.runReport({
          metrics: [
            { name: 'activeUsers' },
            { name: 'newUsers' },
            { name: 'sessions' },
            { name: 'screenPageViews' },
            { name: 'userEngagementDuration' },
            { name: 'eventCount' },
          ],
          dateRanges,
        }),
        this.runReport({
          dimensions: [{ name: 'date' }],
          metrics: [{ name: 'activeUsers' }, { name: 'newUsers' }],
          dateRanges,
          orderBys: [{ dimension: { dimensionName: 'date' } }],
        }),
        this.runReport({
          dimensions: [{ name: 'unifiedScreenName' }],
          metrics: [{ name: 'screenPageViews' }],
          dateRanges,
          orderBys: [
            { metric: { metricName: 'screenPageViews' }, desc: true },
          ],
          limit: '10',
        }),
        this.runReport({
          dimensions: [{ name: 'appVersion' }],
          metrics: [{ name: 'activeUsers' }],
          dateRanges,
          orderBys: [{ metric: { metricName: 'activeUsers' }, desc: true }],
          limit: '10',
        }),
        this.runReport({
          dimensions: [{ name: 'platform' }],
          metrics: [{ name: 'activeUsers' }],
          dateRanges,
          orderBys: [{ metric: { metricName: 'activeUsers' }, desc: true }],
          limit: '10',
        }),
        this.runReport({
          dimensions: [{ name: 'region' }],
          metrics: [{ name: 'activeUsers' }],
          dateRanges,
          orderBys: [{ metric: { metricName: 'activeUsers' }, desc: true }],
          limit: '10',
        }),
      ]);

    const totalsRow = totals.rows?.[0]?.metricValues ?? [];
    const activeUsers = toNumber(totalsRow[0]?.value);
    const engagementSeconds = toNumber(totalsRow[4]?.value);

    const activeSeries: TimeSeriesPoint[] = [];
    const newSeries: TimeSeriesPoint[] = [];
    for (const row of daily.rows ?? []) {
      const date = toIsoDate(row.dimensionValues?.[0]?.value ?? '');
      activeSeries.push({ date, value: toNumber(row.metricValues?.[0]?.value) });
      newSeries.push({ date, value: toNumber(row.metricValues?.[1]?.value) });
    }

    return {
      configured: true,
      source: 'ga4',
      propertyId: this.propertyId,
      days,
      totals: {
        activeUsers,
        newUsers: toNumber(totalsRow[1]?.value),
        sessions: toNumber(totalsRow[2]?.value),
        screenViews: toNumber(totalsRow[3]?.value),
        eventCount: toNumber(totalsRow[5]?.value),
        // GA4 reports total engagement seconds; per-user is the readable form.
        averageEngagementSeconds:
          activeUsers > 0 ? Math.round(engagementSeconds / activeUsers) : 0,
      },
      daily: { activeUsers: activeSeries, newUsers: newSeries },
      topScreens: sliceRows(screens),
      byAppVersion: sliceRows(versions),
      byPlatform: sliceRows(platforms),
      byRegion: sliceRows(countries),
    };
  }
}
