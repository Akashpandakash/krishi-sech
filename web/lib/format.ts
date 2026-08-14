/** Presentation helpers. Everything here takes API values and returns strings
 *  for display — no formatting logic belongs in a component body. */

const numberFormat = new Intl.NumberFormat('en-IN');
const compactFormat = new Intl.NumberFormat('en-IN', {
  notation: 'compact',
  maximumFractionDigits: 1,
});

export function formatNumber(value: number): string {
  return numberFormat.format(value);
}

/** For axis ticks and stat tiles, where the full number would not fit. */
export function formatCompact(value: number): string {
  return value < 10_000 ? numberFormat.format(value) : compactFormat.format(value);
}

export function formatDecimal(value: number, places = 1): string {
  return value.toLocaleString('en-IN', {
    minimumFractionDigits: places,
    maximumFractionDigits: places,
  });
}

export function formatPercent(part: number, whole: number): string {
  if (whole <= 0) return '—';
  return `${((part / whole) * 100).toFixed(1)}%`;
}

export function formatDate(iso: string | null): string {
  if (!iso) return '—';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

export function formatDateTime(iso: string | null): string {
  if (!iso) return '—';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

/** Short axis label for a daily series: "4 Aug". */
export function formatDayLabel(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return iso;
  return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
}

export function formatRelative(iso: string | null): string {
  if (!iso) return 'never';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '—';
  const seconds = Math.round((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return 'just now';
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.round(hours / 24);
  if (days < 30) return `${days}d ago`;
  return formatDate(iso);
}

/** Farmers may sign in by phone or by Google, so neither field is guaranteed. */
export function describeFarmer(user: {
  name: string | null;
  phone: string | null;
  email: string | null;
}): string {
  return user.name?.trim() || user.phone || user.email || 'Unnamed farmer';
}

/** The API mixes conventions — `pest_inspection`, `PestInspection`, `marginal`
 *  — so split on separators AND camelCase humps before capitalising. */
export function titleCase(value: string): string {
  return value
    .replace(/[_-]+/g, ' ')
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .trim()
    .toLowerCase()
    .replace(/\b\w/g, (character) => character.toUpperCase());
}
