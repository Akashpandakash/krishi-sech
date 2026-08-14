'use client';

import { useState } from 'react';

import { useAuth } from '@/components/admin/auth-context';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { describeError, useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { formatDateTime, formatRelative, titleCase } from '@/lib/format';
import { adminRoles, isOwner, type AdminRole } from '@/lib/types';

const ROLE_HELP: Record<AdminRole, string> = {
  owner: 'Full access, including managing admin accounts.',
  admin: 'Can act on farmers and broadcasts, but not manage admins.',
  analyst: 'Read-only across the whole panel.',
};

export default function AdminsPage() {
  const { admin } = useAuth();

  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<AdminRole>('analyst');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [resetFor, setResetFor] = useState<string | null>(null);
  const [resetPassword, setResetPassword] = useState('');

  const list = useAsync(() => adminApi.admins(), []);

  // The route is owner-only server-side; hiding it here just avoids a
  // guaranteed 403 rather than being the actual control.
  if (!isOwner(admin?.role)) {
    return (
      <div className="glass panel stack">
        <h1 className="h2">Admin accounts</h1>
        <p className="notice notice--info">
          Only an owner can manage admin accounts.
        </p>
      </div>
    );
  }

  const create = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      const created = await adminApi.createAdmin({
        email: email.trim(),
        name: name.trim(),
        password,
        role,
      });
      setSuccess(`Created ${created.role} account for ${created.email}.`);
      setEmail('');
      setName('');
      setPassword('');
      setRole('analyst');
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const update = async (
    id: string,
    changes: { role?: AdminRole; isActive?: boolean },
  ) => {
    setBusy(true);
    setError(null);
    try {
      await adminApi.updateAdmin(id, changes);
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const submitReset = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!resetFor) return;
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      await adminApi.resetAdminPassword(resetFor, resetPassword);
      setSuccess('Password reset. Their existing sessions are now invalid.');
      setResetFor(null);
      setResetPassword('');
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div>
          <h1 className="h2">Admin accounts</h1>
          <p className="muted">
            Owners manage who can reach this panel and what they may do.
          </p>
        </div>

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

        <form className="filters" onSubmit={create}>
          <div className="field" style={{ flex: '1 1 200px' }}>
            <label htmlFor="new-email">Email</label>
            <input
              id="new-email"
              className="input"
              type="email"
              required
              maxLength={200}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </div>

          <div className="field" style={{ flex: '1 1 160px' }}>
            <label htmlFor="new-name">Name</label>
            <input
              id="new-name"
              className="input"
              required
              minLength={2}
              maxLength={80}
              value={name}
              onChange={(event) => setName(event.target.value)}
            />
          </div>

          <div className="field" style={{ flex: '1 1 180px' }}>
            <label htmlFor="new-password">Password (min 12 characters)</label>
            <input
              id="new-password"
              className="input"
              type="password"
              required
              minLength={12}
              maxLength={200}
              autoComplete="new-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </div>

          <div className="field">
            <label htmlFor="new-role">Role</label>
            <select
              id="new-role"
              className="input"
              value={role}
              onChange={(event) => setRole(event.target.value as AdminRole)}
            >
              {adminRoles.map((option) => (
                <option key={option} value={option}>
                  {titleCase(option)}
                </option>
              ))}
            </select>
          </div>

          <button className="btn btn--primary btn--sm" type="submit" disabled={busy}>
            Create
          </button>
        </form>

        <p className="muted" style={{ fontSize: '0.75rem' }}>
          {ROLE_HELP[role]}
        </p>
      </section>

      {resetFor ? (
        <section className="glass panel stack">
          <h2 className="h3">Reset password</h2>
          <form className="filters" onSubmit={submitReset}>
            <div className="field" style={{ flex: '1 1 220px' }}>
              <label htmlFor="reset-password">New password (min 12)</label>
              <input
                id="reset-password"
                className="input"
                type="password"
                required
                minLength={12}
                maxLength={200}
                autoComplete="new-password"
                value={resetPassword}
                onChange={(event) => setResetPassword(event.target.value)}
              />
            </div>
            <button className="btn btn--primary btn--sm" type="submit" disabled={busy}>
              Reset
            </button>
            <button
              className="btn btn--ghost btn--sm"
              type="button"
              onClick={() => {
                setResetFor(null);
                setResetPassword('');
              }}
            >
              Cancel
            </button>
          </form>
        </section>
      ) : null}

      {list.error ? (
        <ErrorNotice message={list.error} onRetry={list.reload} />
      ) : list.loading || !list.data ? (
        <LoadingPanel label="Loading admin accounts" />
      ) : (
        <section className="glass panel">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Name</th>
                  <th scope="col">Email</th>
                  <th scope="col">Role</th>
                  <th scope="col">Status</th>
                  <th scope="col">Last login</th>
                  <th scope="col">Created</th>
                  <th scope="col">
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {list.data.map((account) => {
                  const self = account.id === admin?.id;
                  return (
                    <tr key={account.id}>
                      <td>
                        {account.name}
                        {self ? <span className="muted"> (you)</span> : null}
                      </td>
                      <td>{account.email}</td>
                      <td>
                        <select
                          className="input"
                          style={{ minHeight: 32, fontSize: '0.8125rem' }}
                          value={account.role}
                          disabled={busy || self}
                          onChange={(event) =>
                            void update(account.id, {
                              role: event.target.value as AdminRole,
                            })
                          }
                        >
                          {adminRoles.map((option) => (
                            <option key={option} value={option}>
                              {titleCase(option)}
                            </option>
                          ))}
                        </select>
                      </td>
                      <td>
                        {account.isActive ? (
                          <span className="badge badge--good" data-glyph="●">
                            Active
                          </span>
                        ) : (
                          <span className="badge badge--critical" data-glyph="■">
                            Disabled
                          </span>
                        )}
                      </td>
                      <td>{formatRelative(account.lastLoginAt)}</td>
                      <td>{formatDateTime(account.createdAt)}</td>
                      <td>
                        <span className="row" style={{ gap: '0.35rem' }}>
                          <button
                            className="btn btn--glass btn--sm"
                            disabled={busy}
                            onClick={() => setResetFor(account.id)}
                          >
                            Reset password
                          </button>
                          {/* Disabling your own account would lock you out. */}
                          <button
                            className="btn btn--ghost btn--sm"
                            disabled={busy || self}
                            onClick={() =>
                              void update(account.id, {
                                isActive: !account.isActive,
                              })
                            }
                          >
                            {account.isActive ? 'Disable' : 'Enable'}
                          </button>
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
