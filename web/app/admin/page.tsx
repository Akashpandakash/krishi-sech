'use client';

import { useState } from 'react';

import { BarList, StatTile, TimeSeriesChart } from '@/components/charts';
import { ErrorNotice, LoadingPanel, SourceBadge } from '@/components/admin/states';
import { useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import {
  formatCompact,
  formatDecimal,
  formatNumber,
  formatPercent,
  formatRelative,
} from '@/lib/format';

const RANGES = [
  { days: 7, label: '7 days' },
  { days: 30, label: '30 days' },
  { days: 90, label: '90 days' },
];

export default function DashboardPage() {
  const [days, setDays] = useState(30);

  const overview = useAsync(() => adminApi.overview(), []);
  const growth = useAsync(() => adminApi.growth(days), [days]);
  const distributions = useAsync(() => adminApi.distributions(), []);
  const activity = useAsync(() => adminApi.activity(12), []);

  if (overview.error) {
    return <ErrorNotice message={overview.error} onRetry={overview.reload} />;
  }
  if (overview.loading || !overview.data) {
    return <LoadingPanel label="Loading overview metrics" />;
  }

  const metrics = overview.data.metrics;
  const taskTotal = metrics.totalTasks;

  return (
    <div className="stack" style={{ gap: '1.1rem' }}>
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h1 className="h2">Overview</h1>
            <p className="muted">
              {formatNumber(metrics.totalUsers)} farmers registered ·{' '}
              {formatNumber(metrics.farmProfiles)} farm profiles completed
            </p>
          </div>
          <SourceBadge source={overview.data.source} />
        </div>

        <div className="grid grid--stats">
          <StatTile
            label="Total farmers"
            value={formatNumber(metrics.totalUsers)}
            hint={`${formatNumber(metrics.newUsersToday)} joined today`}
          />
          <StatTile
            label="Active"
            value={formatNumber(metrics.activeUsers)}
            hint={formatPercent(metrics.activeUsers, metrics.totalUsers)}
            tone="good"
          />
          <StatTile
            label="Blocked"
            value={formatNumber(metrics.blockedUsers)}
            hint={formatPercent(metrics.blockedUsers, metrics.totalUsers)}
            tone={metrics.blockedUsers > 0 ? 'critical' : 'neutral'}
          />
          <StatTile
            label="New this week"
            value={formatNumber(metrics.newUsers7d)}
            hint={`${formatNumber(metrics.newUsers30d)} in 30 days`}
          />
          <StatTile
            label="Returning (7d)"
            value={formatNumber(metrics.returningUsers7d)}
            hint={`${formatNumber(metrics.returningUsers30d)} in 30 days`}
          />
          <StatTile
            label="Land under management"
            value={`${formatDecimal(metrics.totalLandAcres)} ac`}
            hint={`${formatNumber(metrics.totalCrops)} crops tracked`}
          />
        </div>
      </section>

      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h2 className="h2">Crop &amp; task workload</h2>
            <p className="muted">
              {formatNumber(metrics.crops30d)} crops added in the last 30 days
            </p>
          </div>
        </div>

        <div className="grid grid--stats">
          <StatTile
            label="Pending tasks"
            value={formatNumber(metrics.pendingTasks)}
            hint={formatPercent(metrics.pendingTasks, taskTotal)}
          />
          <StatTile
            label="Completed"
            value={formatNumber(metrics.completedTasks)}
            hint={formatPercent(metrics.completedTasks, taskTotal)}
            tone="good"
          />
          <StatTile
            label="Overdue"
            value={formatNumber(metrics.overdueTasks)}
            hint={formatPercent(metrics.overdueTasks, taskTotal)}
            tone={metrics.overdueTasks > 0 ? 'warning' : 'neutral'}
          />
          <StatTile
            label="Fertilizer advice"
            value={formatCompact(metrics.fertilizerRecommendations)}
            hint="recommendations generated"
          />
          <StatTile
            label="Irrigation advice"
            value={formatCompact(metrics.irrigationRecommendations)}
            hint="recommendations generated"
          />
        </div>
      </section>

      <section className="glass panel stack">
        <div className="spread">
          <h2 className="h2">Growth</h2>
          <div className="row" role="group" aria-label="Time range">
            {RANGES.map((range) => (
              <button
                key={range.days}
                className={`btn btn--sm ${
                  days === range.days ? 'btn--primary' : 'btn--glass'
                }`}
                onClick={() => setDays(range.days)}
                aria-pressed={days === range.days}
              >
                {range.label}
              </button>
            ))}
          </div>
        </div>

        {growth.error ? (
          <ErrorNotice message={growth.error} onRetry={growth.reload} />
        ) : growth.loading || !growth.data ? (
          <LoadingPanel label="Loading growth metrics" />
        ) : (
          <div className="grid grid--charts">
            {/* Signups and sign-ins are an order of magnitude apart, so they
                get their own y-axes as separate charts — never a dual axis. */}
            <div className="glass glass--plot glass--flat panel--tight">
              <TimeSeriesChart
                title="New farmers"
                subtitle={`Sign-ups over the last ${days} days`}
                series={[
                  {
                    key: 'signups',
                    label: 'Sign-ups',
                    color: 'var(--series-1)',
                    points: growth.data.series.signups,
                  },
                ]}
              />
            </div>

            <div className="glass glass--plot glass--flat panel--tight">
              <TimeSeriesChart
                title="Sign-ins"
                subtitle={`Returning sessions over the last ${days} days`}
                series={[
                  {
                    key: 'logins',
                    label: 'Sign-ins',
                    color: 'var(--series-2)',
                    points: growth.data.series.logins,
                  },
                ]}
              />
            </div>

            <div
              className="glass glass--plot glass--flat panel--tight"
              style={{ gridColumn: '1 / -1' }}
            >
              <TimeSeriesChart
                title="Crops added vs tasks completed"
                subtitle="Both are per-day counts on the same scale"
                series={[
                  {
                    key: 'crops',
                    label: 'Crops added',
                    color: 'var(--series-1)',
                    points: growth.data.series.cropsCreated,
                  },
                  {
                    key: 'tasks',
                    label: 'Tasks completed',
                    color: 'var(--series-2)',
                    points: growth.data.series.tasksCompleted,
                  },
                ]}
              />
            </div>
          </div>
        )}
      </section>

      <section className="stack">
        <h2 className="h2">Where farmers are and what they grow</h2>
        {distributions.error ? (
          <ErrorNotice
            message={distributions.error}
            onRetry={distributions.reload}
          />
        ) : distributions.loading || !distributions.data ? (
          <LoadingPanel label="Loading distributions" />
        ) : (
          <div className="grid grid--halves">
            {(
              [
                ['Languages', distributions.data.distributions.languages],
                ['States', distributions.data.distributions.states],
                ['Crops grown', distributions.data.distributions.cropNames],
                ['Soil types', distributions.data.distributions.soilTypes],
                [
                  'Irrigation methods',
                  distributions.data.distributions.irrigationMethods,
                ],
                ['Growth stages', distributions.data.distributions.growthStages],
                ['Farmer types', distributions.data.distributions.farmerTypes],
                ['Task types', distributions.data.distributions.taskTypes],
                ['Crop health', distributions.data.distributions.cropHealth],
              ] as const
            ).map(([title, slices]) => (
              <div key={title} className="glass panel">
                <BarList title={title} slices={slices} />
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="glass panel stack">
        <h2 className="h2">Recent activity</h2>
        {activity.error ? (
          <ErrorNotice message={activity.error} onRetry={activity.reload} />
        ) : activity.loading || !activity.data ? (
          <LoadingPanel label="Loading recent activity" />
        ) : activity.data.activity.length === 0 ? (
          <p className="muted">Nothing has happened yet.</p>
        ) : (
          <ul className="stack" style={{ gap: '0.55rem' }}>
            {activity.data.activity.map((entry, index) => (
              <li key={`${entry.type}-${entry.at}-${index}`} className="spread">
                <span className="row" style={{ gap: '0.5rem' }}>
                  <span className="badge badge--neutral">{entry.type}</span>
                  <span>
                    <strong style={{ fontWeight: 600 }}>{entry.label}</strong>{' '}
                    <span className="muted">{entry.detail}</span>
                  </span>
                </span>
                <span className="muted" style={{ fontSize: '0.75rem' }}>
                  {formatRelative(entry.at)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
