'use client';

import { useCallback, useEffect, useState } from 'react';

import { ApiError } from '@/lib/api';

interface AsyncState<T> {
  data: T | null;
  error: string | null;
  loading: boolean;
  reload: () => void;
}

export function describeError(error: unknown): string {
  if (error instanceof ApiError) return error.message;
  if (error instanceof Error) return error.message;
  return 'Something went wrong';
}

/**
 * Runs `load` on mount and whenever `deps` change.
 *
 * Loading is *derived* from whether the settled result belongs to the current
 * request key, rather than set synchronously inside the effect — resetting
 * state in an effect body triggers a second render pass on every dependency
 * change. A stale response is discarded because it carries an older key, and
 * unmount cancels.
 */
export function useAsync<T>(
  load: () => Promise<T>,
  deps: readonly unknown[],
): AsyncState<T> {
  const [nonce, setNonce] = useState(0);
  const key = `${JSON.stringify(deps)}#${nonce}`;

  const [settled, setSettled] = useState<{
    key: string;
    data: T | null;
    error: string | null;
  }>({ key: '', data: null, error: null });

  const reload = useCallback(() => setNonce((value) => value + 1), []);

  useEffect(() => {
    let cancelled = false;
    load()
      .then((result) => {
        if (!cancelled) setSettled({ key, data: result, error: null });
      })
      .catch((caught: unknown) => {
        if (!cancelled) {
          setSettled({ key, data: null, error: describeError(caught) });
        }
      });
    return () => {
      cancelled = true;
    };
    // `load` is intentionally excluded: callers pass an inline closure, so it
    // is a new function every render. `key` encodes the caller's explicit dep
    // list and is what actually decides when a refetch is warranted.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  const current = settled.key === key;
  return {
    data: current ? settled.data : null,
    error: current ? settled.error : null,
    loading: !current,
    reload,
  };
}
