import {
  GoogleAccessTokenProvider,
  googleApiPost,
  type GoogleServiceAccount,
} from '../../common/google-service-account.js';
import type {
  CrashIssue,
  CrashReport,
  DistributionSlice,
  TimeSeriesPoint,
} from '../telemetry-types.js';

/**
 * Crashlytics has NO public read API — the only supported programmatic access
 * is the BigQuery export, so this queries that dataset directly.
 *
 * Requires, in the Firebase console: Crashlytics → BigQuery export enabled,
 * and the service account granted `roles/bigquery.dataViewer` on the dataset
 * plus `roles/bigquery.jobUser` on the project (running a query is a job).
 *
 * Table naming follows the export convention, e.g. a package of
 * `com.krishisech.app` on Android exports to
 * `firebase_crashlytics.com_krishisech_app_ANDROID`.
 */

const BIGQUERY_SCOPE = 'https://www.googleapis.com/auth/bigquery.readonly';

interface QueryResponse {
  schema?: { fields?: { name: string }[] };
  rows?: { f: { v: string | null }[] }[];
  jobComplete?: boolean;
  totalRows?: string;
  errors?: { message: string }[];
}

function num(value: string | null | undefined): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function text(value: string | null | undefined, fallback = 'Unknown'): string {
  const trimmed = value?.trim();
  return trimmed ? trimmed : fallback;
}

/** BigQuery returns every column as a string in positional `f[]` slots. */
function rowsOf(response: QueryResponse): (string | null)[][] {
  return (response.rows ?? []).map((row) => row.f.map((cell) => cell.v));
}

export class CrashlyticsBigQueryProvider {
  readonly configured = true;

  private readonly tokens: GoogleAccessTokenProvider;

  constructor(
    serviceAccount: GoogleServiceAccount,
    private readonly projectId: string,
    private readonly dataset: string,
    private readonly table: string,
    private readonly timeoutMs = 30_000,
    private readonly fetchImplementation: typeof fetch = fetch,
  ) {
    this.tokens = new GoogleAccessTokenProvider(
      serviceAccount,
      BIGQUERY_SCOPE,
      timeoutMs,
      fetchImplementation,
    );
  }

  /** Fully-qualified, backtick-quoted table reference. */
  private get tableRef(): string {
    return `\`${this.projectId}.${this.dataset}.${this.table}\``;
  }

  private async query(
    sql: string,
    days: number,
  ): Promise<QueryResponse> {
    const response = await googleApiPost<QueryResponse>(
      `https://bigquery.googleapis.com/bigquery/v2/projects/${encodeURIComponent(
        this.projectId,
      )}/queries`,
      {
        query: sql,
        useLegacySql: false,
        timeoutMs: this.timeoutMs,
        // Parameterised so the day window can never be injected into SQL.
        parameterMode: 'NAMED',
        queryParameters: [
          {
            name: 'days',
            parameterType: { type: 'INT64' },
            parameterValue: { value: String(days) },
          },
        ],
      },
      {
        tokens: this.tokens,
        timeoutMs: this.timeoutMs,
        fetchImplementation: this.fetchImplementation,
        apiName: 'BigQuery',
      },
    );
    if (response.errors?.length) {
      throw new Error(`BigQuery query failed: ${response.errors[0]!.message}`);
    }
    return response;
  }

  /** Restricts every query to the requested window. */
  private get window(): string {
    return `event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL @days DAY)`;
  }

  async report(days: number): Promise<CrashReport> {
    const [totals, daily, issues, versions, devices, osVersions] =
      await Promise.all([
        this.query(
          `SELECT
             COUNT(*) AS events,
             COUNTIF(is_fatal) AS fatal_events,
             COUNTIF(NOT is_fatal) AS non_fatal_events,
             COUNT(DISTINCT installation_uuid) AS affected_users,
             COUNT(DISTINCT issue_id) AS distinct_issues
           FROM ${this.tableRef}
           WHERE ${this.window}`,
          days,
        ),
        this.query(
          `SELECT
             FORMAT_TIMESTAMP('%Y-%m-%d', event_timestamp) AS day,
             COUNTIF(is_fatal) AS fatal_events,
             COUNTIF(NOT is_fatal) AS non_fatal_events
           FROM ${this.tableRef}
           WHERE ${this.window}
           GROUP BY day
           ORDER BY day`,
          days,
        ),
        this.query(
          `SELECT
             issue_id,
             ANY_VALUE(issue_title) AS issue_title,
             ANY_VALUE(issue_subtitle) AS issue_subtitle,
             COUNT(*) AS events,
             COUNT(DISTINCT installation_uuid) AS affected_users,
             LOGICAL_OR(is_fatal) AS fatal,
             MAX(application.display_version) AS latest_version,
             FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', MAX(event_timestamp)) AS last_seen
           FROM ${this.tableRef}
           WHERE ${this.window}
           GROUP BY issue_id
           ORDER BY events DESC
           LIMIT 15`,
          days,
        ),
        this.query(
          `SELECT application.display_version AS label, COUNT(*) AS value
           FROM ${this.tableRef}
           WHERE ${this.window}
           GROUP BY label ORDER BY value DESC LIMIT 10`,
          days,
        ),
        this.query(
          `SELECT device.model AS label, COUNT(*) AS value
           FROM ${this.tableRef}
           WHERE ${this.window}
           GROUP BY label ORDER BY value DESC LIMIT 10`,
          days,
        ),
        this.query(
          `SELECT operating_system.display_version AS label, COUNT(*) AS value
           FROM ${this.tableRef}
           WHERE ${this.window}
           GROUP BY label ORDER BY value DESC LIMIT 10`,
          days,
        ),
      ]);

    const totalsRow = rowsOf(totals)[0] ?? [];
    const fatalSeries: TimeSeriesPoint[] = [];
    const nonFatalSeries: TimeSeriesPoint[] = [];
    for (const row of rowsOf(daily)) {
      const date = text(row[0], '');
      fatalSeries.push({ date, value: num(row[1]) });
      nonFatalSeries.push({ date, value: num(row[2]) });
    }

    const topIssues: CrashIssue[] = rowsOf(issues).map((row) => ({
      issueId: text(row[0], ''),
      title: text(row[1], 'Untitled issue'),
      subtitle: text(row[2], ''),
      events: num(row[3]),
      affectedUsers: num(row[4]),
      fatal: row[5] === 'true',
      latestVersion: text(row[6], '—'),
      lastSeen: row[7] ?? null,
    }));

    const slices = (response: QueryResponse): DistributionSlice[] =>
      rowsOf(response).map((row) => ({
        label: text(row[0]),
        value: num(row[1]),
      }));

    return {
      configured: true,
      source: 'bigquery',
      dataset: this.dataset,
      table: this.table,
      days,
      totals: {
        events: num(totalsRow[0]),
        fatalEvents: num(totalsRow[1]),
        nonFatalEvents: num(totalsRow[2]),
        affectedUsers: num(totalsRow[3]),
        distinctIssues: num(totalsRow[4]),
      },
      daily: { fatal: fatalSeries, nonFatal: nonFatalSeries },
      topIssues,
      byAppVersion: slices(versions),
      byDevice: slices(devices),
      byOsVersion: slices(osVersions),
    };
  }
}
