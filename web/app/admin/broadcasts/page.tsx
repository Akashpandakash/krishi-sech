'use client';

import { useState } from 'react';

import { BroadcastAnalytics } from '@/components/admin/broadcast-analytics';
import { useAuth } from '@/components/admin/auth-context';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { describeError, useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { formatDateTime, formatNumber, titleCase } from '@/lib/format';
import {
  broadcastCategories,
  canWrite,
  type BroadcastAudience,
  type BroadcastCategory,
  type BroadcastStatus,
} from '@/lib/types';

const STATUS_TONE: Record<BroadcastStatus, string> = {
  draft: 'neutral',
  scheduled: 'warning',
  sending: 'warning',
  sent: 'good',
  failed: 'critical',
  cancelled: 'neutral',
};

const STATUS_GLYPH: Record<BroadcastStatus, string> = {
  draft: '',
  scheduled: '▲',
  sending: '▲',
  sent: '●',
  failed: '■',
  cancelled: '',
};

const EMPTY_AUDIENCE: BroadcastAudience = {
  language: null,
  state: null,
  farmerType: null,
  onlyActive: true,
};

export default function BroadcastsPage() {
  const { admin } = useAuth();
  const editable = canWrite(admin?.role);

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [category, setCategory] = useState<BroadcastCategory>('general');
  const [deepLink, setDeepLink] = useState('');
  const [audience, setAudience] = useState<BroadcastAudience>(EMPTY_AUDIENCE);
  const [scheduledAt, setScheduledAt] = useState('');
  const [estimate, setEstimate] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const filters = useAsync(() => adminApi.filters(), []);
  const list = useAsync(() => adminApi.broadcasts({ limit: 50 }), []);

  const patchAudience = (changes: Partial<BroadcastAudience>) => {
    setAudience((current) => ({ ...current, ...changes }));
    setEstimate(null);
  };

  const runEstimate = async () => {
    setBusy(true);
    setError(null);
    try {
      const result = await adminApi.estimateAudience(audience);
      setEstimate(result.deviceCount);
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const submit = async (sendNow: boolean) => {
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      const created = await adminApi.createBroadcast({
        title: title.trim(),
        body: body.trim(),
        category,
        deepLink: deepLink.trim() || null,
        audience,
        scheduledAt: scheduledAt
          ? new Date(scheduledAt).toISOString()
          : null,
        sendNow,
      });
      setSuccess(
        sendNow
          ? `Broadcast sent to ${formatNumber(created.audienceCount)} farmers.`
          : 'Broadcast saved.',
      );
      setTitle('');
      setBody('');
      setDeepLink('');
      setScheduledAt('');
      setEstimate(null);
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const act = async (
    id: string,
    action: 'send' | 'cancel' | 'delete',
  ): Promise<void> => {
    setBusy(true);
    setError(null);
    try {
      if (action === 'send') await adminApi.sendBroadcast(id);
      if (action === 'cancel') await adminApi.cancelBroadcast(id);
      if (action === 'delete') await adminApi.deleteBroadcast(id);
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h1 className="h2">Broadcasts</h1>
            <p className="muted">
              Push a notification to the farmers who match an audience filter.
            </p>
          </div>
          {!editable ? (
            <span className="badge badge--neutral">Read-only (analyst)</span>
          ) : null}
        </div>

        {/* Sending into an unconfigured transport looks identical to success
            from in here, so say so before anyone composes a message. */}
        {list.data && !list.data.transport.configured ? (
          <p className="notice notice--info" role="status">
            Push transport <strong>{list.data.transport.name}</strong> is not
            configured, so broadcasts will land in the in-app inbox only — no
            device notification will be delivered.
          </p>
        ) : null}

        {error ? (
          <p className="notice notice--error" role="alert">
            {error}
          </p>
        ) : null}
        {success ? (
          <p className="notice notice--success" role="status">
            {success}
          </p>
        ) : null}

        {editable ? (
          <form
            className="stack"
            onSubmit={(event) => {
              event.preventDefault();
              void submit(false);
            }}
          >
            <div className="field">
              <label htmlFor="bc-title">Title (3–80 characters)</label>
              <input
                id="bc-title"
                className="input"
                required
                minLength={3}
                maxLength={80}
                value={title}
                onChange={(event) => setTitle(event.target.value)}
              />
            </div>

            <div className="field">
              <label htmlFor="bc-body">Message (3–500 characters)</label>
              <textarea
                id="bc-body"
                className="input"
                required
                minLength={3}
                maxLength={500}
                value={body}
                onChange={(event) => setBody(event.target.value)}
              />
              <span className="muted" style={{ fontSize: '0.75rem' }}>
                {body.length}/500
              </span>
            </div>

            <div className="filters">
              <div className="field">
                <label htmlFor="bc-category">Category</label>
                <select
                  id="bc-category"
                  className="input"
                  value={category}
                  onChange={(event) =>
                    setCategory(event.target.value as BroadcastCategory)
                  }
                >
                  {broadcastCategories.map((option) => (
                    <option key={option} value={option}>
                      {titleCase(option)}
                    </option>
                  ))}
                </select>
              </div>

              <div className="field" style={{ flex: '1 1 200px' }}>
                <label htmlFor="bc-link">Deep link (optional)</label>
                <input
                  id="bc-link"
                  className="input"
                  maxLength={200}
                  placeholder="krishisech://crop-calendar"
                  value={deepLink}
                  onChange={(event) => setDeepLink(event.target.value)}
                />
              </div>

              <div className="field">
                <label htmlFor="bc-when">Schedule for (optional)</label>
                <input
                  id="bc-when"
                  className="input"
                  type="datetime-local"
                  value={scheduledAt}
                  onChange={(event) => setScheduledAt(event.target.value)}
                />
              </div>
            </div>

            <fieldset
              className="stack"
              style={{ border: 0, padding: 0, margin: 0 }}
            >
              <legend className="eyebrow">Audience</legend>
              <div className="filters">
                <div className="field">
                  <label htmlFor="bc-lang">Language</label>
                  <select
                    id="bc-lang"
                    className="input"
                    value={audience.language ?? ''}
                    onChange={(event) =>
                      patchAudience({ language: event.target.value || null })
                    }
                  >
                    <option value="">All languages</option>
                    {(filters.data?.languages ?? []).map((option) => (
                      <option key={option} value={option}>
                        {option}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="field">
                  <label htmlFor="bc-state">State</label>
                  <select
                    id="bc-state"
                    className="input"
                    value={audience.state ?? ''}
                    onChange={(event) =>
                      patchAudience({ state: event.target.value || null })
                    }
                  >
                    <option value="">All states</option>
                    {(filters.data?.states ?? []).map((option) => (
                      <option key={option} value={option}>
                        {option}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="field">
                  <label htmlFor="bc-type">Farmer type</label>
                  <select
                    id="bc-type"
                    className="input"
                    value={audience.farmerType ?? ''}
                    onChange={(event) =>
                      patchAudience({ farmerType: event.target.value || null })
                    }
                  >
                    <option value="">All types</option>
                    {(filters.data?.farmerTypes ?? []).map((option) => (
                      <option key={option} value={option}>
                        {titleCase(option)}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="field">
                  <label htmlFor="bc-active">Recipients</label>
                  <select
                    id="bc-active"
                    className="input"
                    value={audience.onlyActive ? 'active' : 'all'}
                    onChange={(event) =>
                      patchAudience({ onlyActive: event.target.value === 'active' })
                    }
                  >
                    <option value="active">Active accounts only</option>
                    <option value="all">Include blocked accounts</option>
                  </select>
                </div>

                <button
                  className="btn btn--glass btn--sm"
                  type="button"
                  onClick={runEstimate}
                  disabled={busy}
                >
                  Estimate reach
                </button>
              </div>

              {estimate !== null ? (
                <p className="notice notice--info" role="status">
                  This audience currently reaches{' '}
                  <strong>{formatNumber(estimate)}</strong> registered{' '}
                  {estimate === 1 ? 'device' : 'devices'}. Farmers who have not
                  enabled push are counted in the audience but will only see
                  this in the in-app inbox.
                </p>
              ) : null}
            </fieldset>

            <div className="row">
              <button className="btn btn--glass" type="submit" disabled={busy}>
                Save as draft
              </button>
              <button
                className="btn btn--primary"
                type="button"
                disabled={busy}
                onClick={() => void submit(true)}
              >
                {busy ? 'Working…' : 'Send now'}
              </button>
            </div>
          </form>
        ) : null}
      </section>

      <BroadcastAnalytics />

      <section className="glass panel stack">
        <h2 className="h2">History</h2>
        {list.error ? (
          <ErrorNotice message={list.error} onRetry={list.reload} />
        ) : list.loading || !list.data ? (
          <LoadingPanel label="Loading broadcasts" />
        ) : list.data.broadcasts.length === 0 ? (
          <p className="muted">No broadcasts yet.</p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Title</th>
                  <th scope="col">Category</th>
                  <th scope="col">Status</th>
                  <th scope="col">Audience</th>
                  <th scope="col">Delivered</th>
                  <th scope="col">Failed</th>
                  <th scope="col">Sent</th>
                  <th scope="col">By</th>
                  <th scope="col">
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {list.data.broadcasts.map((broadcast) => (
                  <tr key={broadcast.id}>
                    <td title={broadcast.body}>{broadcast.title}</td>
                    <td>{titleCase(broadcast.category)}</td>
                    <td>
                      <span
                        className={`badge badge--${STATUS_TONE[broadcast.status]}`}
                        data-glyph={STATUS_GLYPH[broadcast.status]}
                      >
                        {titleCase(broadcast.status)}
                      </span>
                    </td>
                    <td className="numeric">
                      {formatNumber(broadcast.audienceCount)}
                    </td>
                    <td className="numeric">
                      {formatNumber(broadcast.deliveredCount)}
                    </td>
                    <td className="numeric">
                      {formatNumber(broadcast.failedCount)}
                    </td>
                    <td>
                      {formatDateTime(broadcast.sentAt ?? broadcast.scheduledAt)}
                    </td>
                    <td>{broadcast.createdByAdminEmail}</td>
                    <td>
                      {editable ? (
                        <span className="row" style={{ gap: '0.35rem' }}>
                          {broadcast.status === 'draft' ||
                          broadcast.status === 'scheduled' ? (
                            <button
                              className="btn btn--glass btn--sm"
                              disabled={busy}
                              onClick={() => void act(broadcast.id, 'send')}
                            >
                              Send
                            </button>
                          ) : null}
                          {broadcast.status === 'scheduled' ? (
                            <button
                              className="btn btn--ghost btn--sm"
                              disabled={busy}
                              onClick={() => void act(broadcast.id, 'cancel')}
                            >
                              Cancel
                            </button>
                          ) : null}
                          {broadcast.status === 'draft' ||
                          broadcast.status === 'cancelled' ||
                          broadcast.status === 'failed' ? (
                            <button
                              className="btn btn--ghost btn--sm"
                              disabled={busy}
                              onClick={() => void act(broadcast.id, 'delete')}
                            >
                              Delete
                            </button>
                          ) : null}
                        </span>
                      ) : null}
                    </td>
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
