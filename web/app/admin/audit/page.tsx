'use client';

import { useState } from 'react';

import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { formatDateTime, titleCase } from '@/lib/format';

export default function AuditPage() {
  const [actionInput, setActionInput] = useState('');
  const [action, setAction] = useState('');
  const [limit, setLimit] = useState(50);

  const log = useAsync(
    () => adminApi.auditLog({ action: action || undefined, limit }),
    [action, limit],
  );

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div>
          <h1 className="h2">Audit log</h1>
          <p className="muted">
            Every privileged action, newest first. Entries are immutable.
          </p>
        </div>

        <form
          className="filters"
          onSubmit={(event) => {
            event.preventDefault();
            setAction(actionInput.trim());
          }}
        >
          <div className="field" style={{ flex: '1 1 220px' }}>
            <label htmlFor="audit-action">Filter by action</label>
            <input
              id="audit-action"
              className="input"
              placeholder="admin.login, user.blocked, broadcast.sent…"
              maxLength={60}
              value={actionInput}
              onChange={(event) => setActionInput(event.target.value)}
            />
          </div>

          <div className="field">
            <label htmlFor="audit-limit">Show</label>
            <select
              id="audit-limit"
              className="input"
              value={limit}
              onChange={(event) => setLimit(Number(event.target.value))}
            >
              <option value={25}>25 entries</option>
              <option value={50}>50 entries</option>
              <option value={100}>100 entries</option>
              <option value={200}>200 entries</option>
            </select>
          </div>

          <button className="btn btn--primary btn--sm" type="submit">
            Apply
          </button>
          {action ? (
            <button
              className="btn btn--ghost btn--sm"
              type="button"
              onClick={() => {
                setActionInput('');
                setAction('');
              }}
            >
              Clear
            </button>
          ) : null}
        </form>
      </section>

      {log.error ? (
        <ErrorNotice message={log.error} onRetry={log.reload} />
      ) : log.loading || !log.data ? (
        <LoadingPanel label="Loading audit log" />
      ) : log.data.length === 0 ? (
        <div className="glass panel">
          <p className="muted">No audit entries match this filter.</p>
        </div>
      ) : (
        <section className="glass panel">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">When</th>
                  <th scope="col">Admin</th>
                  <th scope="col">Action</th>
                  <th scope="col">Summary</th>
                  <th scope="col">Target</th>
                  <th scope="col">IP</th>
                </tr>
              </thead>
              <tbody>
                {log.data.map((entry) => (
                  <tr key={entry.id}>
                    <td>{formatDateTime(entry.createdAt)}</td>
                    <td>{entry.adminEmail}</td>
                    <td>
                      <span className="badge badge--neutral">{entry.action}</span>
                    </td>
                    <td style={{ whiteSpace: 'normal' }}>{entry.summary}</td>
                    <td>
                      {entry.targetType
                        ? `${titleCase(entry.targetType)} ${entry.targetId ?? ''}`.trim()
                        : '—'}
                    </td>
                    <td>{entry.ipAddress ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
