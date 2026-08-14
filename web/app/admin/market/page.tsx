'use client';

import { useMemo, useState } from 'react';

import { useAuth } from '@/components/admin/auth-context';
import { ErrorNotice, LoadingPanel } from '@/components/admin/states';
import { describeError, useAsync } from '@/components/admin/use-async';
import { adminApi } from '@/lib/api';
import { formatNumber, formatRelative, titleCase } from '@/lib/format';
import {
  canWrite,
  localeNames,
  marketCategories,
  marketUnits,
  supportedLocaleCodes,
  type LocalizedText,
  type MarketCategory,
  type MarketProduct,
  type MarketProductInput,
  type MarketUnit,
} from '@/lib/types';

const EMPTY: MarketProductInput = {
  name: { en: '' },
  description: { en: '' },
  category: 'seeds',
  price: 0,
  unit: 'bag',
  stockQuantity: 0,
  vendor: '',
  isActive: true,
};

function toInput(product: MarketProduct): MarketProductInput {
  return {
    name: { ...product.name },
    description: { ...product.description },
    category: product.category,
    price: product.price,
    unit: product.unit,
    stockQuantity: product.stockQuantity,
    vendor: product.vendor,
    isActive: product.isActive,
  };
}

/** Drops blank translations so an empty box never ships as a translation. */
function clean(text: LocalizedText): LocalizedText {
  const result: LocalizedText = { en: text.en.trim() };
  for (const [code, value] of Object.entries(text)) {
    if (code === 'en') continue;
    const trimmed = value.trim();
    if (trimmed) result[code] = trimmed;
  }
  return result;
}

function TranslationFields({
  idPrefix,
  label,
  multiline,
  value,
  locales,
  onChange,
}: {
  idPrefix: string;
  label: string;
  multiline?: boolean;
  value: LocalizedText;
  locales: string[];
  onChange: (next: LocalizedText) => void;
}) {
  const set = (code: string, next: string) =>
    onChange({ ...value, [code]: next } as LocalizedText);

  return (
    <div className="stack">
      {['en', ...locales.filter((code) => code !== 'en')].map((code) => (
        <div className="field" key={code}>
          <label htmlFor={`${idPrefix}-${code}`}>
            {label} · {localeNames[code] ?? code}
            {code === 'en' ? ' (required)' : ''}
          </label>
          {multiline ? (
            <textarea
              id={`${idPrefix}-${code}`}
              className="input"
              required={code === 'en'}
              maxLength={200}
              rows={2}
              value={value[code] ?? ''}
              onChange={(event) => set(code, event.target.value)}
            />
          ) : (
            <input
              id={`${idPrefix}-${code}`}
              className="input"
              required={code === 'en'}
              maxLength={200}
              value={value[code] ?? ''}
              onChange={(event) => set(code, event.target.value)}
            />
          )}
        </div>
      ))}
    </div>
  );
}

export default function MarketPage() {
  const { admin } = useAuth();
  const editable = canWrite(admin?.role);

  const [form, setForm] = useState<MarketProductInput>(EMPTY);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [locales, setLocales] = useState<string[]>(['hi']);
  const [category, setCategory] = useState<'' | MarketCategory>('');
  const [search, setSearch] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const list = useAsync(() => adminApi.products(), []);

  const products = useMemo(() => {
    const all = list.data?.products ?? [];
    const needle = search.trim().toLowerCase();
    return all.filter(
      (product) =>
        (!category || product.category === category) &&
        (!needle ||
          product.name.en.toLowerCase().includes(needle) ||
          product.vendor.toLowerCase().includes(needle)),
    );
  }, [list.data, category, search]);

  const patch = (changes: Partial<MarketProductInput>) =>
    setForm((current) => ({ ...current, ...changes }));

  const reset = () => {
    setForm(EMPTY);
    setEditingId(null);
    setLocales(['hi']);
  };

  const startEdit = (product: MarketProduct) => {
    setForm(toInput(product));
    setEditingId(product.id);
    // Show every language this product already has text in.
    setLocales(
      [
        ...new Set([
          ...Object.keys(product.name),
          ...Object.keys(product.description),
        ]),
      ].filter((code) => code !== 'en'),
    );
    setError(null);
    setSuccess(null);
    if (typeof window !== 'undefined') {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    setSuccess(null);
    const payload: MarketProductInput = {
      ...form,
      name: clean(form.name),
      description: clean(form.description),
      vendor: form.vendor.trim(),
    };
    try {
      if (editingId) await adminApi.updateProduct(editingId, payload);
      else await adminApi.createProduct(payload);
      setSuccess(`"${payload.name.en}" saved.`);
      reset();
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const toggleActive = async (product: MarketProduct) => {
    setBusy(true);
    setError(null);
    try {
      await adminApi.updateProduct(product.id, {
        ...toInput(product),
        isActive: !product.isActive,
      });
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const remove = async (product: MarketProduct) => {
    if (
      typeof window !== 'undefined' &&
      !window.confirm(
        `Delete "${product.name.en}"? Delisting it instead keeps it out of the app without losing the row.`,
      )
    ) {
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await adminApi.deleteProduct(product.id);
      if (editingId === product.id) reset();
      list.reload();
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  const addLocale = (code: string) => {
    if (!code || code === 'en' || locales.includes(code)) return;
    setLocales((current) => [...current, code]);
  };

  return (
    <div className="stack">
      <section className="glass panel stack">
        <div className="spread">
          <div>
            <h1 className="h2">Market catalogue</h1>
            <p className="muted">
              Products farmers see in the Market tab. Anything not listed here
              does not exist in the app.
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
              {editingId ? 'Edit product' : 'Add a product'}
            </h2>

            <TranslationFields
              idPrefix="mkt-name"
              label="Name"
              value={form.name}
              locales={locales}
              onChange={(name) => patch({ name })}
            />

            <TranslationFields
              idPrefix="mkt-desc"
              label="Description"
              multiline
              value={form.description}
              locales={locales}
              onChange={(description) => patch({ description })}
            />

            <div className="field">
              <label htmlFor="mkt-locale">Add another language</label>
              <select
                id="mkt-locale"
                className="input"
                value=""
                onChange={(event) => addLocale(event.target.value)}
              >
                <option value="">Choose a language…</option>
                {supportedLocaleCodes
                  .filter((code) => code !== 'en' && !locales.includes(code))
                  .map((code) => (
                    <option key={code} value={code}>
                      {localeNames[code] ?? code}
                    </option>
                  ))}
              </select>
              <span className="muted" style={{ fontSize: '0.75rem' }}>
                Any language left blank falls back to English in the app.
              </span>
            </div>

            <div className="grid grid--halves">
              <div className="field">
                <label htmlFor="mkt-category">Category</label>
                <select
                  id="mkt-category"
                  className="input"
                  value={form.category}
                  onChange={(event) =>
                    patch({ category: event.target.value as MarketCategory })
                  }
                >
                  {marketCategories.map((option) => (
                    <option key={option} value={option}>
                      {titleCase(option)}
                    </option>
                  ))}
                </select>
              </div>

              <div className="field">
                <label htmlFor="mkt-vendor">Vendor</label>
                <input
                  id="mkt-vendor"
                  className="input"
                  required
                  maxLength={120}
                  value={form.vendor}
                  onChange={(event) => patch({ vendor: event.target.value })}
                />
              </div>

              <div className="field">
                <label htmlFor="mkt-price">Price (₹, whole rupees)</label>
                <input
                  id="mkt-price"
                  className="input"
                  type="number"
                  required
                  min={1}
                  value={form.price || ''}
                  onChange={(event) =>
                    patch({ price: Number(event.target.value) })
                  }
                />
              </div>

              <div className="field">
                <label htmlFor="mkt-unit">Unit</label>
                <select
                  id="mkt-unit"
                  className="input"
                  value={form.unit}
                  onChange={(event) =>
                    patch({ unit: event.target.value as MarketUnit })
                  }
                >
                  {marketUnits.map((option) => (
                    <option key={option} value={option}>
                      {titleCase(option)}
                    </option>
                  ))}
                </select>
              </div>

              <div className="field">
                <label htmlFor="mkt-stock">Stock quantity</label>
                <input
                  id="mkt-stock"
                  className="input"
                  type="number"
                  required
                  min={0}
                  value={form.stockQuantity}
                  onChange={(event) =>
                    patch({ stockQuantity: Number(event.target.value) })
                  }
                />
                <span className="muted" style={{ fontSize: '0.75rem' }}>
                  Zero shows the product as out of stock.
                </span>
              </div>

              <div className="field">
                <label htmlFor="mkt-active">Listing</label>
                <select
                  id="mkt-active"
                  className="input"
                  value={form.isActive ? 'listed' : 'delisted'}
                  onChange={(event) =>
                    patch({ isActive: event.target.value === 'listed' })
                  }
                >
                  <option value="listed">Listed in the app</option>
                  <option value="delisted">Delisted</option>
                </select>
              </div>
            </div>

            <div className="row">
              <button className="btn btn--primary" type="submit" disabled={busy}>
                {busy ? 'Saving…' : editingId ? 'Save changes' : 'Add product'}
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
        <div className="filters">
          <div className="field" style={{ flex: '1 1 220px' }}>
            <label htmlFor="mkt-search">Search</label>
            <input
              id="mkt-search"
              className="input"
              placeholder="Name or vendor"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
          </div>

          <div className="field">
            <label htmlFor="mkt-filter-category">Category</label>
            <select
              id="mkt-filter-category"
              className="input"
              value={category}
              onChange={(event) =>
                setCategory(event.target.value as '' | MarketCategory)
              }
            >
              <option value="">All</option>
              {marketCategories.map((option) => (
                <option key={option} value={option}>
                  {titleCase(option)}
                </option>
              ))}
            </select>
          </div>
        </div>

        {list.error ? (
          <ErrorNotice message={list.error} onRetry={list.reload} />
        ) : list.loading || !list.data ? (
          <LoadingPanel label="Loading products" />
        ) : products.length === 0 ? (
          <p className="muted">
            {list.data.products.length === 0
              ? 'The catalogue is empty — the Market tab has nothing to show until a product is added.'
              : 'No products match these filters.'}
          </p>
        ) : (
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th scope="col">Product</th>
                  <th scope="col">Category</th>
                  <th scope="col">Vendor</th>
                  <th scope="col">Price</th>
                  <th scope="col">Stock</th>
                  <th scope="col">Languages</th>
                  <th scope="col">Status</th>
                  <th scope="col">Updated</th>
                  <th scope="col">
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {products.map((product) => (
                  <tr key={product.id}>
                    <td>{product.name.en}</td>
                    <td>{titleCase(product.category)}</td>
                    <td>{product.vendor}</td>
                    <td className="numeric">
                      ₹{formatNumber(product.price)}/{product.unit}
                    </td>
                    <td className="numeric">
                      {formatNumber(product.stockQuantity)}
                    </td>
                    <td>{Object.keys(product.name).length}</td>
                    <td>
                      {!product.isActive ? (
                        <span className="badge badge--neutral">Delisted</span>
                      ) : product.stockQuantity > 0 ? (
                        <span className="badge badge--good" data-glyph="●">
                          In stock
                        </span>
                      ) : (
                        <span className="badge badge--warning" data-glyph="▲">
                          Out of stock
                        </span>
                      )}
                    </td>
                    <td>{formatRelative(product.updatedAt)}</td>
                    <td>
                      {editable ? (
                        <span className="row">
                          <button
                            className="btn btn--glass btn--sm"
                            onClick={() => startEdit(product)}
                            disabled={busy}
                          >
                            Edit
                          </button>
                          <button
                            className="btn btn--glass btn--sm"
                            onClick={() => toggleActive(product)}
                            disabled={busy}
                          >
                            {product.isActive ? 'Delist' : 'List'}
                          </button>
                          <button
                            className="btn btn--danger btn--sm"
                            onClick={() => remove(product)}
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
