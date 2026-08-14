'use client';

import { useState } from 'react';

import { useAuth } from '@/components/admin/auth-context';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { describeError, useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { formatDate, formatNumber, formatRelative } from '@/lib/format';
import {
  canWrite,
  type MandiPriceInput,
  type MandiPriceRecord,
  type MandiSource,
} from '@/lib/types';

const SOURCES: { value: '' | MandiSource; label: string }[] = [
  { value: '', label: 'All rows' },
  { value: 'manual', label: 'Entered here' },
  { value: 'agmarknet', label: 'From AGMARKNET' },
];

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

/** A function, not a constant: a panel left open overnight must not default
 *  the arrival date to yesterday. */
function emptyForm(): MandiPriceInput {
  return {
    state: '',
    district: '',
    market: '',
    commodity: '',
    variety: null,
    grade: null,
    arrivalDate: today(),
    minPrice: 0,
    maxPrice: 0,
    modalPrice: 0,
  };
}

function toInput(record: MandiPriceRecord): MandiPriceInput {
  return {
    state: record.state,
    district: record.district,
    market: record.market,
    commodity: record.commodity,
    variety: record.variety,
    grade: record.grade,
    arrivalDate: record.arrivalDate.slice(0, 10),
    minPrice: record.minPrice,
    maxPrice: record.maxPrice,
    modalPrice: record.modalPrice,
  };
}

export default function MandiPage() {
  const { admin } = useAuth();
  const editable = canWrite(admin?.role);

  const [state, setState] = useState('');
  const [commodity, setCommodity] = useState('');
  const [source, setSource] = useState<'' | MandiSource>('');
  const [searchInput, setSearchInput] = useState('');
  const [search, setSearch] = useState('');

  const [form, setForm] = useState<MandiPriceInput>(emptyForm);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const filters = useAsync(() => adminApi.mandiFilters(), []);
  const list = useAsync(
    () =>
      adminApi.mandiPrices({
        state: state || undefined,
        commodity: commodity || undefined,
        source: source || undefined,
        search: search || undefined,
        limit: 200,
      }),
    [state, commodity, source, search],
  );

  const patch = (changes: Partial<MandiPriceInput>) =>
    setForm((current) => ({ ...current, ...changes }));

  const reset = () => {
    setForm(emptyForm());
    setEditingId(null);
  };

  const startEdit = (record: MandiPriceRecord) => {
    setForm(toInput(record));
    setEditingId(record.id);
    setError(null);
    setSuccess(null);
    if (typeof window !== 'undefined') window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    setSuccess(null);
    const payload: MandiPriceInput = {
      ...form,
      state: form.state.trim(),
      district: form.district.trim(),
      market: form.market.trim(),
      commodity: form.commodity.trim(),
      variety: form.variety?.trim() || null,
      grade: form.grade?.trim() || null,
    };
    try {
      if (editingId) await adminApi.updateMandiPrice(editingId, payload);
      else await adminApi.createMandiPrice(payload);
      setSuccess(
        `${payload.commodity} at ${payload.market} saved. Farmers in ${payload.state} see it on the next refresh.`,
      );
      reset();
      list.reload();
      filters.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const remove = async (record: MandiPriceRecord) => {
    // Deleting a feed row only holds until the next fetch re-publishes it, so
    // say that rather than let it look like a permanent removal.
    const warning =
      record.source === 'manual'
        ? ''
        : '\n\nThis row comes from AGMARKNET and will return on the next refresh. To change the price for good, use Correct instead.';
    if (
      typeof window !== 'undefined' &&
      !window.confirm(
        `Delete ${record.commodity} at ${record.market}?${warning}`,
      )
    ) {
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await adminApi.deleteMandiPrice(record.id);
      if (editingId === record.id) reset();
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
            <h1 className="h2">Mandi prices</h1>
            <p className="muted">
              Rows pulled from AGMARKNET, plus the ones you enter here. A row
              entered here overrides the feed for the same market and survives
              the next refresh.
            </p>
          </div>
          {!editable ? (
            <span className="badge badge--neutral">Read-only (analyst)</span>
          ) : null}
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

        {editable ? (
          <form className="stack" onSubmit={submit}>
            <h2 className="h3">
              {editingId ? 'Edit price' : 'Add a price'}
            </h2>

            <div className="grid grid--halves">
              <div className="field">
                <label htmlFor="mp-state">State</label>
                <input
                  id="mp-state"
                  className="input"
                  required
                  maxLength={80}
                  list="mp-states"
                  value={form.state}
                  onChange={(event) => patch({ state: event.target.value })}
                />
                <datalist id="mp-states">
                  {(filters.data?.states ?? []).map((option) => (
                    <option key={option} value={option} />
                  ))}
                </datalist>
              </div>

              <div className="field">
                <label htmlFor="mp-district">District</label>
                <input
                  id="mp-district"
                  className="input"
                  required
                  maxLength={80}
                  list="mp-districts"
                  value={form.district}
                  onChange={(event) => patch({ district: event.target.value })}
                />
                <datalist id="mp-districts">
                  {(filters.data?.districts ?? []).map((option) => (
                    <option key={option} value={option} />
                  ))}
                </datalist>
              </div>

              <div className="field">
                <label htmlFor="mp-market">Market (mandi)</label>
                <input
                  id="mp-market"
                  className="input"
                  required
                  maxLength={80}
                  value={form.market}
                  onChange={(event) => patch({ market: event.target.value })}
                />
              </div>

              <div className="field">
                <label htmlFor="mp-commodity">Commodity</label>
                <input
                  id="mp-commodity"
                  className="input"
                  required
                  maxLength={80}
                  list="mp-commodities"
                  value={form.commodity}
                  onChange={(event) => patch({ commodity: event.target.value })}
                />
                <datalist id="mp-commodities">
                  {(filters.data?.commodities ?? []).map((option) => (
                    <option key={option} value={option} />
                  ))}
                </datalist>
              </div>

              <div className="field">
                <label htmlFor="mp-variety">Variety (optional)</label>
                <input
                  id="mp-variety"
                  className="input"
                  maxLength={80}
                  value={form.variety ?? ''}
                  onChange={(event) =>
                    patch({ variety: event.target.value || null })
                  }
                />
              </div>

              <div className="field">
                <label htmlFor="mp-grade">Grade (optional)</label>
                <input
                  id="mp-grade"
                  className="input"
                  maxLength={80}
                  placeholder="FAQ"
                  value={form.grade ?? ''}
                  onChange={(event) =>
                    patch({ grade: event.target.value || null })
                  }
                />
              </div>

              <div className="field">
                <label htmlFor="mp-date">Arrival date</label>
                <input
                  id="mp-date"
                  className="input"
                  type="date"
                  required
                  max={today()}
                  value={form.arrivalDate}
                  onChange={(event) =>
                    patch({ arrivalDate: event.target.value })
                  }
                />
              </div>

              <div className="field">
                <label htmlFor="mp-min">Minimum ₹/quintal</label>
                <input
                  id="mp-min"
                  className="input"
                  type="number"
                  required
                  min={1}
                  value={form.minPrice || ''}
                  onChange={(event) =>
                    patch({ minPrice: Number(event.target.value) })
                  }
                />
              </div>

              <div className="field">
                <label htmlFor="mp-modal">Modal ₹/quintal</label>
                <input
                  id="mp-modal"
                  className="input"
                  type="number"
                  required
                  min={1}
                  value={form.modalPrice || ''}
                  onChange={(event) =>
                    patch({ modalPrice: Number(event.target.value) })
                  }
                />
              </div>

              <div className="field">
                <label htmlFor="mp-max">Maximum ₹/quintal</label>
                <input
                  id="mp-max"
                  className="input"
                  type="number"
                  required
                  min={1}
                  value={form.maxPrice || ''}
                  onChange={(event) =>
                    patch({ maxPrice: Number(event.target.value) })
                  }
                />
              </div>
            </div>

            <div className="row">
              <button className="btn btn--primary" type="submit" disabled={busy}>
                {busy ? 'Saving…' : editingId ? 'Save changes' : 'Add price'}
              </button>
              {editingId ? (
                <button
                  className="btn btn--glass"
                  type="button"
                  onClick={reset}
                  disabled={busy}
                >
                  Cancel
                </button>
              ) : null}
            </div>
          </form>
        ) : null}
      </section>

      <section className="glass panel stack">
        <form
          className="filters"
          onSubmit={(event) => {
            event.preventDefault();
            setSearch(searchInput.trim());
          }}
        >
          <div className="field" style={{ flex: '1 1 200px' }}>
            <label htmlFor="mp-search">Search</label>
            <input
              id="mp-search"
              className="input"
              placeholder="Market or commodity"
              value={searchInput}
              onChange={(event) => setSearchInput(event.target.value)}
            />
          </div>

          <div className="field">
            <label htmlFor="mp-filter-state">State</label>
            <select
              id="mp-filter-state"
              className="input"
              value={state}
              onChange={(event) => setState(event.target.value)}
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
            <label htmlFor="mp-filter-commodity">Commodity</label>
            <select
              id="mp-filter-commodity"
              className="input"
              value={commodity}
              onChange={(event) => setCommodity(event.target.value)}
            >
              <option value="">Any</option>
              {(filters.data?.commodities ?? []).map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </div>

          <div className="field">
            <label htmlFor="mp-filter-source">Source</label>
            <select
              id="mp-filter-source"
              className="input"
              value={source}
              onChange={(event) =>
                setSource(event.target.value as '' | MandiSource)
              }
            >
              {SOURCES.map((option) => (
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

        {list.error ? (
          <ErrorNotice message={list.error} onRetry={list.reload} />
        ) : list.loading || !list.data ? (
          <LoadingPanel label="Loading mandi prices" />
        ) : list.data.prices.length === 0 ? (
          <p className="muted">
            No stored rows match. AGMARKNET rows appear here once a farmer opens
            the Market tab for that state.
          </p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Commodity</th>
                  <th scope="col">Market</th>
                  <th scope="col">District</th>
                  <th scope="col">State</th>
                  <th scope="col">Arrival</th>
                  <th scope="col">Min</th>
                  <th scope="col">Modal</th>
                  <th scope="col">Max</th>
                  <th scope="col">Source</th>
                  <th scope="col">Updated</th>
                  <th scope="col">
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {list.data.prices.map((record) => (
                  <tr key={record.id}>
                    <td>
                      {record.commodity}
                      {record.variety ? (
                        <span className="muted"> · {record.variety}</span>
                      ) : null}
                    </td>
                    <td>{record.market}</td>
                    <td>{record.district}</td>
                    <td>{record.state}</td>
                    <td>{formatDate(record.arrivalDate)}</td>
                    <td className="numeric">{formatNumber(record.minPrice)}</td>
                    <td className="numeric">
                      {formatNumber(record.modalPrice)}
                    </td>
                    <td className="numeric">{formatNumber(record.maxPrice)}</td>
                    <td>
                      {record.source === 'manual' ? (
                        <span className="badge badge--good" data-glyph="●">
                          Entered here
                        </span>
                      ) : (
                        <span className="badge badge--neutral">AGMARKNET</span>
                      )}
                    </td>
                    <td>{formatRelative(record.recordedAt)}</td>
                    <td>
                      {editable ? (
                        <span className="row">
                          <button
                            className="btn btn--glass btn--sm"
                            onClick={() => startEdit(record)}
                            disabled={busy}
                          >
                            {record.source === 'manual' ? 'Edit' : 'Correct'}
                          </button>
                          <button
                            className="btn btn--danger btn--sm"
                            onClick={() => remove(record)}
                            disabled={busy}
                          >
                            Delete
                          </button>
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
