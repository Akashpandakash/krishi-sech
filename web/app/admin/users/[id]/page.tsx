'use client';

import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';

import { useAuth } from '@/components/admin/auth-context';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { describeError, useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import {
  describeFarmer,
  formatDate,
  formatDateTime,
  formatDecimal,
  formatNumber,
  formatRelative,
  titleCase,
} from '@/lib/format';
import { canWrite } from '@/lib/types';

function healthTone(status: string): 'good' | 'warning' | 'critical' | 'neutral' {
  const value = status.toLowerCase();
  if (value.includes('healthy') || value.includes('good')) return 'good';
  if (value.includes('critical') || value.includes('diseased')) return 'critical';
  if (value.includes('moderate') || value.includes('warning')) return 'warning';
  return 'neutral';
}

const TONE_GLYPH = {
  good: '●',
  warning: '▲',
  critical: '■',
  neutral: '',
} as const;

export default function UserDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const { admin } = useAuth();
  const editable = canWrite(admin?.role);
  const id = params.id;

  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [reason, setReason] = useState('');

  const detail = useAsync(() => adminApi.user(id), [id]);

  const toggleStatus = async () => {
    if (!detail.data) return;
    setBusy(true);
    setActionError(null);
    try {
      await adminApi.setUserStatus(id, !detail.data.isActive);
      detail.reload();
    } catch (caught) {
      setActionError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const remove = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setActionError(null);
    try {
      await adminApi.deleteUser(id, reason.trim());
      router.push('/admin/users');
    } catch (caught) {
      setActionError(describeError(caught));
      setBusy(false);
    }
  };

  if (detail.error) {
    return <ErrorNotice message={detail.error} onRetry={detail.reload} />;
  }
  if (detail.loading || !detail.data) {
    return <LoadingPanel label="Loading farmer" />;
  }

  const user = detail.data;

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <p className="eyebrow">
              <Link href="/admin/users">← Back to farmers</Link>
            </p>
            <h1 className="h2">{describeFarmer(user)}</h1>
            <p className="muted">
              Joined {formatDate(user.createdAt)} · last seen{' '}
              {formatRelative(user.lastSeenAt)}
            </p>
          </div>
          <div className="row">
            {user.isActive ? (
              <span className="badge badge--good" data-glyph="●">
                Active
              </span>
            ) : (
              <span className="badge badge--critical" data-glyph="■">
                Blocked
              </span>
            )}
            {editable ? (
              <>
                <button
                  className="btn btn--glass btn--sm"
                  disabled={busy}
                  onClick={toggleStatus}
                >
                  {user.isActive ? 'Block account' : 'Unblock account'}
                </button>
                <button
                  className="btn btn--danger btn--sm"
                  disabled={busy}
                  onClick={() => setConfirmingDelete((value) => !value)}
                >
                  Delete
                </button>
              </>
            ) : null}
          </div>
        </div>

        {actionError ? (
          <p className="notice notice--error" role="alert">
            {actionError}
          </p>
        ) : null}

        {confirmingDelete && editable ? (
          <form className="stack" onSubmit={remove}>
            <p className="notice notice--error">
              This permanently purges the farmer&apos;s account, crops, tasks and
              sessions. It cannot be undone.
            </p>
            <div className="field">
              <label htmlFor="delete-reason">
                Reason (recorded in the audit log, 3–300 characters)
              </label>
              <input
                id="delete-reason"
                className="input"
                required
                minLength={3}
                maxLength={300}
                value={reason}
                onChange={(event) => setReason(event.target.value)}
              />
            </div>
            <div className="row">
              <button className="btn btn--danger" type="submit" disabled={busy}>
                {busy ? 'Deleting…' : 'Permanently delete this farmer'}
              </button>
              <button
                className="btn btn--ghost"
                type="button"
                onClick={() => setConfirmingDelete(false)}
              >
                Cancel
              </button>
            </div>
          </form>
        ) : null}

        <dl className="grid grid--stats">
          <div>
            <dt className="eyebrow">Phone</dt>
            <dd>{user.phone ?? '— (Google account)'}</dd>
          </div>
          <div>
            <dt className="eyebrow">Email</dt>
            <dd>{user.email ?? '—'}</dd>
          </div>
          <div>
            <dt className="eyebrow">Language</dt>
            <dd>{user.preferredLanguage}</dd>
          </div>
          <div>
            <dt className="eyebrow">Location</dt>
            <dd>
              {[user.village, user.district, user.state]
                .filter(Boolean)
                .join(', ') || '—'}
            </dd>
          </div>
        </dl>
      </section>

      <div className="grid grid--halves">
        <section className="glass panel stack">
          <h2 className="h3">Farm profile</h2>
          {user.farm ? (
            <dl className="stack" style={{ gap: '0.5rem' }}>
              <div className="spread">
                <dt className="muted">Farm name</dt>
                <dd>{user.farm.farmName}</dd>
              </div>
              <div className="spread">
                <dt className="muted">Farmer type</dt>
                <dd>{titleCase(user.farm.farmerType)}</dd>
              </div>
              <div className="spread">
                <dt className="muted">Land area</dt>
                <dd className="numeric">
                  {formatDecimal(user.farm.totalLandArea)} {user.farm.landUnit}
                </dd>
              </div>
              <div className="spread">
                <dt className="muted">Soil</dt>
                <dd>{titleCase(user.farm.soilType)}</dd>
              </div>
              <div className="spread">
                <dt className="muted">Irrigation</dt>
                <dd>{titleCase(user.farm.irrigationSource)}</dd>
              </div>
              <div className="spread">
                <dt className="muted">Main crops</dt>
                <dd>{user.farm.mainCrops.join(', ') || '—'}</dd>
              </div>
              <div className="spread">
                <dt className="muted">Coarse location</dt>
                <dd>{user.farm.coarseLocation ?? '—'}</dd>
              </div>
            </dl>
          ) : (
            <p className="muted">This farmer has not completed a farm profile.</p>
          )}
        </section>

        <section className="glass panel stack">
          <div className="spread">
            <h2 className="h3">Push devices</h2>
            {user.devices.length === 0 ? (
              <span className="badge badge--warning" data-glyph="▲">
                Not reachable
              </span>
            ) : (
              <span className="badge badge--good" data-glyph="●">
                {user.devices.length} registered
              </span>
            )}
          </div>
          {user.devices.length === 0 ? (
            <p className="muted">
              This farmer has no registered device, so broadcasts will only
              reach their in-app inbox.
            </p>
          ) : (
            <div className="table-scroll">
              <table className="table">
                <thead>
                  <tr>
                    <th scope="col">Platform</th>
                    <th scope="col">Token</th>
                    <th scope="col">Registered</th>
                    <th scope="col">Last seen</th>
                  </tr>
                </thead>
                <tbody>
                  {user.devices.map((device) => (
                    <tr key={device.tokenSuffix}>
                      <td>{titleCase(device.platform)}</td>
                      <td>
                        <code>…{device.tokenSuffix}</code>
                      </td>
                      <td>{formatDate(device.createdAt)}</td>
                      <td>{formatRelative(device.updatedAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        <section className="glass panel stack">
          <h2 className="h3">Sessions</h2>
          {user.sessions.length === 0 ? (
            <p className="muted">No sessions on record.</p>
          ) : (
            <div className="table-scroll">
              <table className="table">
                <thead>
                  <tr>
                    <th scope="col">Started</th>
                    <th scope="col">Expires</th>
                    <th scope="col">State</th>
                  </tr>
                </thead>
                <tbody>
                  {user.sessions.map((session, index) => (
                    <tr key={`${session.createdAt}-${index}`}>
                      <td>{formatDateTime(session.createdAt)}</td>
                      <td>{formatDateTime(session.expiresAt)}</td>
                      <td>
                        {session.revoked ? (
                          <span className="badge badge--neutral">Revoked</span>
                        ) : (
                          <span className="badge badge--good" data-glyph="●">
                            Live
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>

      <section className="glass panel stack">
        <div className="spread">
          <h2 className="h3">Crops</h2>
          <span className="muted">{formatNumber(user.crops.length)} tracked</span>
        </div>
        {user.crops.length === 0 ? (
          <p className="muted">No crops yet.</p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Crop</th>
                  <th scope="col">Variety</th>
                  <th scope="col">Stage</th>
                  <th scope="col">Health</th>
                  <th scope="col">Area</th>
                  <th scope="col">Sown</th>
                  <th scope="col">Harvest</th>
                </tr>
              </thead>
              <tbody>
                {user.crops.map((crop) => {
                  const tone = healthTone(crop.healthStatus);
                  return (
                    <tr key={crop.id}>
                      <td>{crop.cropName}</td>
                      <td>{crop.variety || '—'}</td>
                      <td>{titleCase(crop.growthStage)}</td>
                      <td>
                        <span
                          className={`badge badge--${tone}`}
                          data-glyph={TONE_GLYPH[tone]}
                        >
                          {titleCase(crop.healthStatus)}
                        </span>
                      </td>
                      <td className="numeric">
                        {formatDecimal(crop.landArea)} {crop.landUnit}
                      </td>
                      <td>{formatDate(crop.sowingDate)}</td>
                      <td>{formatDate(crop.expectedHarvestDate)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="glass panel stack">
        <div className="spread">
          <h2 className="h3">Tasks</h2>
          <span className="muted">{formatNumber(user.tasks.length)} scheduled</span>
        </div>
        {user.tasks.length === 0 ? (
          <p className="muted">No tasks yet.</p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Type</th>
                  <th scope="col">Status</th>
                  <th scope="col">Due</th>
                </tr>
              </thead>
              <tbody>
                {user.tasks.map((task) => (
                  <tr key={task.id}>
                    <td>{titleCase(task.taskType)}</td>
                    <td>{titleCase(task.status)}</td>
                    <td>{formatDate(task.dueDate)}</td>
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
