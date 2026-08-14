'use client';

import type { MetricsSource } from '@/lib/types';

export function ErrorNotice({
  message,
  onRetry,
}: {
  message: string;
  onRetry?: () => void;
}) {
  return (
    <div className="glass panel stack" role="alert">
      <p className="notice notice--error">{message}</p>
      {onRetry ? (
        <div>
          <button className="btn btn--glass btn--sm" onClick={onRetry}>
            Try again
          </button>
        </div>
      ) : null}
    </div>
  );
}

export function LoadingPanel({ label }: { label: string }) {
  return (
    <div className="glass panel stack" aria-busy="true">
      <span className="sr-only">{label}</span>
      <div className="skeleton" style={{ height: 16, width: '38%' }} />
      <div className="skeleton" style={{ height: 96 }} />
      <div className="skeleton" style={{ height: 16, width: '62%' }} />
    </div>
  );
}

export function EmptyState({
  title,
  detail,
}: {
  title: string;
  detail?: string;
}) {
  return (
    <div className="glass panel stack" style={{ textAlign: 'center' }}>
      <h3 className="h3">{title}</h3>
      {detail ? <p className="muted">{detail}</p> : null}
    </div>
  );
}

/**
 * Confirms the figures come from the database. The generated-sample-data
 * repository was removed, so there is no longer a second state to warn about.
 */
export function SourceBadge({ source }: { source: MetricsSource }) {
  return (
    <span className="badge badge--good" data-glyph="●">
      {source === 'database' ? 'Live data' : source}
    </span>
  );
}
