'use client';

import { useState } from 'react';

import { BarList, StatTile, TimeSeriesChart } from '@/components/charts';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import {
  formatCompact,
  formatDateTime,
  formatNumber,
  formatPercent,
} from '@/lib/format';
import type { TelemetryNotConfigured } from '@/lib/types';

const RANGES = [7, 28, 90];

/** Setup guidance per integration. Shown instead of an empty chart, because a
 *  missing credential and a quiet week must never look the same. */
const SETUP: Record<
  'analytics' | 'crashlytics',
  { title: string; steps: string[] }
> = {
  analytics: {
    title: 'Firebase Analytics is not connected yet',
    steps: [
      'In the Firebase console, confirm the project is linked to a Google Analytics property.',
      'Open Google Analytics → Admin → Property settings and copy the numeric Property ID (not the G-XXXXXXX measurement ID).',
      'Set GA4_PROPERTY_ID in the server environment to that number.',
      'In Google Analytics → Admin → Property access management, add the service account email as a Viewer.',
      'Enable the Google Analytics Data API in the Google Cloud console for the project.',
    ],
  },
  crashlytics: {
    title: 'Crashlytics is not connected yet',
    steps: [
      'Crashlytics has no read API — the only supported programmatic access is its BigQuery export, so that has to be switched on.',
      'In the Firebase console, go to Project settings → Integrations → BigQuery, enable it, and tick Crashlytics.',
      'Wait for the first export to land; the table appears as firebase_crashlytics.<package>_<PLATFORM>, e.g. com_krishisech_app_ANDROID.',
      'Set CRASHLYTICS_BIGQUERY_TABLE and BIGQUERY_PROJECT_ID in the server environment.',
      'Grant the service account roles/bigquery.jobUser on the project and roles/bigquery.dataViewer on the dataset.',
    ],
  },
};

function SetupPanel({ state }: { state: TelemetryNotConfigured }) {
  const setup = SETUP[state.integration];
  return (
    <section className="glass panel stack">
      <div>
        <h2 className="h3">{setup.title}</h2>
        <p className="notice notice--info" style={{ marginTop: '0.6rem' }}>
          {state.reason}
        </p>
      </div>

      {state.missing.length > 0 ? (
        <p className="muted" style={{ fontSize: '0.8125rem' }}>
          Missing environment{' '}
          {state.missing.length === 1 ? 'variable' : 'variables'}:{' '}
          {state.missing.map((name) => (
            <code key={name} className="setup__var">
              {name}
            </code>
          ))}
        </p>
      ) : null}

      <ol className="setup__steps">
        {setup.steps.map((step) => (
          <li key={step}>{step}</li>
        ))}
      </ol>
    </section>
  );
}

function AnalyticsSection({ days }: { days: number }) {
  const report = useAsync(() => adminApi.analyticsReport(days), [days]);

  if (report.error) {
    return <ErrorNotice message={report.error} onRetry={report.reload} />;
  }
  if (report.loading || !report.data) {
    return <LoadingPanel label="Loading Firebase Analytics" />;
  }
  if (!report.data.configured) return <SetupPanel state={report.data} />;

  const { totals, daily, topScreens, byAppVersion, byPlatform, byRegion } =
    report.data;

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h2 className="h2">Firebase Analytics</h2>
            <p className="muted">
              GA4 property {report.data.propertyId} · last {days} days
            </p>
          </div>
          <span className="badge badge--good" data-glyph="●">
            Live from GA4
          </span>
        </div>

        <div className="grid grid--stats">
          <StatTile
            label="Active users"
            value={formatNumber(totals.activeUsers)}
            hint={`${formatNumber(totals.newUsers)} new`}
          />
          <StatTile label="Sessions" value={formatNumber(totals.sessions)} />
          <StatTile
            label="Screen views"
            value={formatCompact(totals.screenViews)}
          />
          <StatTile label="Events" value={formatCompact(totals.eventCount)} />
          <StatTile
            label="Avg engagement"
            value={`${Math.round(totals.averageEngagementSeconds / 60)}m`}
            hint="per active user"
          />
          <StatTile
            label="New user share"
            value={formatPercent(totals.newUsers, totals.activeUsers)}
          />
        </div>
      </section>

      <section className="glass panel">
        {/* Active and new users share a scale and a meaning, so they belong on
            one chart — unlike anything measured in different units. */}
        <TimeSeriesChart
          title="Users per day"
          subtitle={`Active and new users over the last ${days} days`}
          series={[
            {
              key: 'active',
              label: 'Active users',
              color: 'var(--series-1)',
              points: daily.activeUsers,
            },
            {
              key: 'new',
              label: 'New users',
              color: 'var(--series-2)',
              points: daily.newUsers,
            },
          ]}
        />
      </section>

      <div className="grid grid--halves">
        <div className="glass panel">
          <BarList title="Most viewed screens" slices={topScreens} />
        </div>
        <div className="glass panel">
          <BarList title="App versions in use" slices={byAppVersion} />
        </div>
        <div className="glass panel">
          <BarList title="Platforms" slices={byPlatform} />
        </div>
        <div className="glass panel">
          <BarList title="Regions" slices={byRegion} />
        </div>
      </div>
    </div>
  );
}

function CrashSection({ days }: { days: number }) {
  const report = useAsync(() => adminApi.crashReport(days), [days]);

  if (report.error) {
    return <ErrorNotice message={report.error} onRetry={report.reload} />;
  }
  if (report.loading || !report.data) {
    return <LoadingPanel label="Loading Crashlytics" />;
  }
  if (!report.data.configured) return <SetupPanel state={report.data} />;

  const { totals, daily, topIssues, byAppVersion, byDevice, byOsVersion } =
    report.data;

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h2 className="h2">Crashlytics</h2>
            <p className="muted">
              {report.data.dataset}.{report.data.table} · last {days} days
            </p>
          </div>
          <span className="badge badge--good" data-glyph="●">
            Live from BigQuery
          </span>
        </div>

        <div className="grid grid--stats">
          <StatTile
            label="Crashes"
            value={formatNumber(totals.fatalEvents)}
            tone={totals.fatalEvents > 0 ? 'critical' : 'good'}
          />
          <StatTile
            label="Non-fatal errors"
            value={formatNumber(totals.nonFatalEvents)}
            tone={totals.nonFatalEvents > 0 ? 'warning' : 'neutral'}
          />
          <StatTile
            label="Affected users"
            value={formatNumber(totals.affectedUsers)}
          />
          <StatTile
            label="Distinct issues"
            value={formatNumber(totals.distinctIssues)}
          />
          <StatTile
            label="Total events"
            value={formatCompact(totals.events)}
          />
        </div>
      </section>

      <section className="glass panel">
        <TimeSeriesChart
          title="Crashes and non-fatal errors per day"
          subtitle="Both are event counts on the same scale"
          series={[
            {
              key: 'fatal',
              label: 'Crashes',
              color: 'var(--series-1)',
              points: daily.fatal,
            },
            {
              key: 'nonfatal',
              label: 'Non-fatal',
              color: 'var(--series-2)',
              points: daily.nonFatal,
            },
          ]}
        />
      </section>

      <section className="glass panel stack">
        <h3 className="h3">Top issues</h3>
        {topIssues.length === 0 ? (
          <p className="muted">
            No crashes or non-fatal errors were reported in this window.
          </p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Issue</th>
                  <th scope="col">Type</th>
                  <th scope="col">Events</th>
                  <th scope="col">Users</th>
                  <th scope="col">Version</th>
                  <th scope="col">Last seen</th>
                </tr>
              </thead>
              <tbody>
                {topIssues.map((issue) => (
                  <tr key={issue.issueId}>
                    <td style={{ whiteSpace: 'normal', maxWidth: '32rem' }}>
                      <strong>{issue.title}</strong>
                      {issue.subtitle ? (
                        <>
                          <br />
                          <span className="muted">{issue.subtitle}</span>
                        </>
                      ) : null}
                    </td>
                    <td>
                      {issue.fatal ? (
                        <span className="badge badge--critical" data-glyph="■">
                          Crash
                        </span>
                      ) : (
                        <span className="badge badge--warning" data-glyph="▲">
                          Non-fatal
                        </span>
                      )}
                    </td>
                    <td className="numeric">{formatNumber(issue.events)}</td>
                    <td className="numeric">
                      {formatNumber(issue.affectedUsers)}
                    </td>
                    <td>{issue.latestVersion}</td>
                    <td>{formatDateTime(issue.lastSeen)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <div className="grid grid--halves">
        <div className="glass panel">
          <BarList title="Crashes by app version" slices={byAppVersion} />
        </div>
        <div className="glass panel">
          <BarList title="Crashes by device" slices={byDevice} />
        </div>
        <div className="glass panel">
          <BarList title="Crashes by OS version" slices={byOsVersion} />
        </div>
      </div>
    </div>
  );
}

export default function TelemetryPage() {
  const [days, setDays] = useState(28);

  return (
    <div className="stack" style={{ gap: '1.1rem' }}>
      <section className="glass panel spread">
        <div>
          <h1 className="h2">App health</h1>
          <p className="muted">
            Usage from Firebase Analytics and stability from Crashlytics.
          </p>
        </div>
        <div className="row" role="group" aria-label="Time range">
          {RANGES.map((range) => (
            <button
              key={range}
              className={`btn btn--sm ${
                days === range ? 'btn--primary' : 'btn--glass'
              }`}
              onClick={() => setDays(range)}
              aria-pressed={days === range}
            >
              {range} days
            </button>
          ))}
        </div>
      </section>

      <AnalyticsSection days={days} />
      <CrashSection days={days} />
    </div>
  );
}
