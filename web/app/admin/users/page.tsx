'use client';

import Link from 'next/link';
import { useState } from 'react';

import { useAuth } from '@/components/admin/auth-context';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { describeError, useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { describeFarmer, formatDate, formatNumber, formatRelative } from '@/lib/format';
import { canWrite, type UserSort, type UserStatusFilter } from '@/lib/types';

const PAGE_SIZE = 20;

const SORTS: { value: UserSort; label: string }[] = [
  { value: 'recent', label: 'Newest first' },
  { value: 'oldest', label: 'Oldest first' },
  { value: 'crops', label: 'Most crops' },
  { value: 'lastSeen', label: 'Recently active' },
];

export default function UsersPage() {
  const { admin } = useAuth();
  const editable = canWrite(admin?.role);

  const [searchInput, setSearchInput] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<UserStatusFilter>('all');
  const [language, setLanguage] = useState('');
  const [state, setState] = useState('');
  const [sort, setSort] = useState<UserSort>('recent');
  const [page, setPage] = useState(1);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const filters = useAsync(() => adminApi.filters(), []);
  const list = useAsync(
    () =>
      adminApi.users({
        search: search || undefined,
        status,
        language: language || undefined,
        state: state || undefined,
        sort,
        page,
        limit: PAGE_SIZE,
      }),
    [search, status, language, state, sort, page],
  );

  const applySearch = (event: React.FormEvent) => {
    event.preventDefault();
    setPage(1);
    setSearch(searchInput.trim());
  };

  const toggleStatus = async (id: string, nextActive: boolean) => {
    setBusyId(id);
    setActionError(null);
    try {
      await adminApi.setUserStatus(id, nextActive);
      list.reload();
    } catch (caught) {
      setActionError(describeError(caught));
    } finally {
      setBusyId(null);
    }
  };

  const totalPages = list.data
    ? Math.max(1, Math.ceil(list.data.total / list.data.limit))
    : 1;

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h1 className="h2">Farmers</h1>
            <p className="muted">
              {list.data
                ? `${formatNumber(list.data.total)} matching ${
                    list.data.total === 1 ? 'farmer' : 'farmers'
                  }`
                : 'Loading…'}
            </p>
          </div>
          {!editable ? (
            <span className="badge badge--neutral">Read-only (analyst)</span>
          ) : null}
        </div>

        <form className="filters" onSubmit={applySearch}>
          <div className="field" style={{ flex: '1 1 220px' }}>
            <label htmlFor="user-search">Search</label>
            <input
              id="user-search"
              className="input"
              placeholder="Name, phone or email"
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>

          <div className="field">
            <label htmlFor="user-status">Status</label>
            <select
              id="user-status"
              className="input"
              value={status}
              onChange={(event) => {
                setPage(1);
                setStatus(event.target.value as UserStatusFilter);
              }}
            >
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="blocked">Blocked</option>
            </select>
          </div>

          <div className="field">
            <label htmlFor="user-language">Language</label>
            <select
              id="user-language"
              className="input"
              value={language}
              onChange={(event) => {
                setPage(1);
                setLanguage(event.target.value);
              }}
            >
              <option value="">Any</option>
              {(filters.data?.languages ?? []).map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </div>

          <div className="field">
            <label htmlFor="user-state">State</label>
            <select
              id="user-state"
              className="input"
              value={state}
              onChange={(event) => {
                setPage(1);
                setState(event.target.value);
              }}
            >
              <option value="">Any</option>
              {(filters.data?.states ?? []).map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </div>

          <div className="field">
            <label htmlFor="user-sort">Sort</label>
            <select
              id="user-sort"
              className="input"
              value={sort}
              onChange={(event) => {
                setPage(1);
                setSort(event.target.value as UserSort);
              }}
            >
              {SORTS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>

          <button className="btn btn--primary btn--sm" type="submit">
            Apply
          </button>
        </form>

        {actionError ? (
          <p className="notice notice--error" role="alert">
            {actionError}
          </p>
        ) : null}
      </section>

      {list.error ? (
        <ErrorNotice message={list.error} onRetry={list.reload} />
      ) : list.loading || !list.data ? (
        <LoadingPanel label="Loading farmers" />
      ) : list.data.users.length === 0 ? (
        <div className="glass panel">
          <p className="muted">No farmers match these filters.</p>
        </div>
      ) : (
        <section className="glass panel stack">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Farmer</th>
                  <th scope="col">Contact</th>
                  <th scope="col">Location</th>
                  <th scope="col">Lang</th>
                  <th scope="col">Crops</th>
                  <th scope="col">Tasks</th>
                  <th scope="col">Joined</th>
                  <th scope="col">Last seen</th>
                  <th scope="col">Status</th>
                  <th scope="col">
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {list.data.users.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <Link href={`/admin/users/${user.id}`}>
                        {describeFarmer(user)}
                      </Link>
                    </td>
                    <td>{user.phone ?? user.email ?? '—'}</td>
                    <td>
                      {[user.village, user.district, user.state]
                        .filter(Boolean)
                        .join(', ') || '—'}
                    </td>
                    <td>{user.preferredLanguage}</td>
                    <td className="numeric">{formatNumber(user.cropCount)}</td>
                    <td className="numeric">{formatNumber(user.taskCount)}</td>
                    <td>{formatDate(user.createdAt)}</td>
                    <td>{formatRelative(user.lastSeenAt)}</td>
                    <td>
                      {user.isActive ? (
                        <span className="badge badge--good" data-glyph="●">
                          Active
                        </span>
                      ) : (
                        <span className="badge badge--critical" data-glyph="■">
                          Blocked
                        </span>
                      )}
                    </td>
                    <td>
                      {editable ? (
                        <button
                          className="btn btn--glass btn--sm"
                          disabled={busyId === user.id}
                          onClick={() => toggleStatus(user.id, !user.isActive)}
                        >
                          {busyId === user.id
                            ? '…'
                            : user.isActive
                              ? 'Block'
                              : 'Unblock'}
                        </button>
                      ) : null}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="pagination">
            <span>
              Page {list.data.page} of {totalPages} ·{' '}
              {formatNumber(list.data.total)} total
            </span>
            <span className="row">
              <button
                className="btn btn--glass btn--sm"
                disabled={page <= 1}
                onClick={() => setPage((value) => Math.max(1, value - 1))}
              >
                Previous
              </button>
              <button
                className="btn btn--glass btn--sm"
                disabled={page >= totalPages}
                onClick={() => setPage((value) => value + 1)}
              >
                Next
              </button>
            </span>
          </div>
        </section>
      )}
    </div>
  );
}
