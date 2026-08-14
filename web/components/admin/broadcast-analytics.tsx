'use client';

import { useState } from 'react';

import { BarList, StatTile, TimeSeriesChart } from '@/components/charts';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { formatDateTime, formatNumber, titleCase } from '@/lib/format';

const RANGES = [7, 28, 90];

/** Delivery reporting for the broadcaster, shown above the composer. */
export function BroadcastAnalytics() {
  const [days, setDays] = useState(28);
  const report = useAsync(() => adminApi.broadcastAnalytics(days), [days]);

  if (report.error) {
    return <ErrorNotice message={report.error} onRetry={report.reload} />;
  }
  if (report.loading || !report.data) {
    return <LoadingPanel label="Loading broadcast analytics" />;
  }

  const { totals, daily, devices, transport, byCategory, byStatus, topByReach } =
    report.data;

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h2 className="h2">Delivery</h2>
            <p className="muted">
              {formatNumber(devices.total)} registered{' '}
              {devices.total === 1 ? 'device' : 'devices'} · transport{' '}
              <strong>{transport.name}</strong>
            </p>
          </div>
          <div className="row">
            {transport.configured ? (
              <span className="badge badge--good" data-glyph="●">
                Push configured
              </span>
            ) : (
              <span className="badge badge--warning" data-glyph="▲">
                Inbox only — no device push
              </span>
            )}
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
                  {range}d
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="grid grid--stats">
          <StatTile
            label="Delivered"
            value={formatNumber(totals.delivered)}
            hint={`${totals.deliveryRate}% of audience`}
            tone={totals.delivered > 0 ? 'good' : 'neutral'}
          />
          <StatTile
            label="Failed deliveries"
            value={formatNumber(totals.failedDeliveries)}
            tone={totals.failedDeliveries > 0 ? 'warning' : 'neutral'}
          />
          <StatTile
            label="Total audience"
            value={formatNumber(totals.audience)}
            hint="across sent broadcasts"
          />
          <StatTile
            label="Sent"
            value={formatNumber(totals.sent)}
            hint={`${formatNumber(totals.total)} broadcasts total`}
          />
          <StatTile
            label="Scheduled"
            value={formatNumber(totals.scheduled)}
            hint={`${formatNumber(totals.drafts)} drafts`}
          />
          <StatTile
            label="Registered devices"
            value={formatNumber(devices.total)}
            hint={
              devices.byPlatform
                .map((slice) => `${slice.value} ${slice.label}`)
                .join(' · ') || 'none yet'
            }
          />
        </div>
      </section>

      <section className="glass panel">
        {/* Delivered and failed are the same unit on the same scale, so they
            belong on one chart with one axis. */}
        <TimeSeriesChart
          title="Deliveries per day"
          subtitle={`Delivered and failed notifications over the last ${days} days`}
          series={[
            {
              key: 'delivered',
              label: 'Delivered',
              color: 'var(--series-1)',
              points: daily.delivered,
            },
            {
              key: 'failed',
              label: 'Failed',
              color: 'var(--series-2)',
              points: daily.failed,
            },
          ]}
        />
      </section>

      <div className="grid grid--halves">
        <div className="glass panel">
          <BarList
            title="Broadcasts by category"
            slices={byCategory.map((slice) => ({
              ...slice,
              label: titleCase(slice.label),
            }))}
          />
        </div>
        <div className="glass panel">
          <BarList
            title="Broadcasts by status"
            slices={byStatus.map((slice) => ({
              ...slice,
              label: titleCase(slice.label),
            }))}
          />
        </div>
      </div>

      <section className="glass panel stack">
        <h3 className="h3">Widest reach</h3>
        {topByReach.length === 0 ? (
          <p className="muted">Nothing has been sent yet.</p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Broadcast</th>
                  <th scope="col">Category</th>
                  <th scope="col">Audience</th>
                  <th scope="col">Delivered</th>
                  <th scope="col">Failed</th>
                  <th scope="col">Rate</th>
                  <th scope="col">Sent</th>
                </tr>
              </thead>
              <tbody>
                {topByReach.map((entry) => (
                  <tr key={entry.id}>
                    <td>{entry.title}</td>
                    <td>{titleCase(entry.category)}</td>
                    <td className="numeric">
                      {formatNumber(entry.audienceCount)}
                    </td>
                    <td className="numeric">
                      {formatNumber(entry.deliveredCount)}
                    </td>
                    <td className="numeric">
                      {formatNumber(entry.failedCount)}
                    </td>
                    <td className="numeric">{entry.deliveryRate}%</td>
                    <td>{formatDateTime(entry.sentAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
