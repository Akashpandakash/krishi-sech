export interface MandiConfig {
  /** data.gov.in API key. Null disables the module; requests then 503. */
  apiKey: string | null;
  baseUrl: string;
  /**
   * AGMARKNET "Current Daily Price of Various Commodities from Various
   * Markets (Mandi)" resource, published by the Directorate of Marketing and
   * Inspection. This is the authoritative national mandi feed.
   */
  resourceId: string;
  timeoutMs: number;
  /**
   * The upstream snapshot changes once a day, so a short in-process cache
   * keeps a screenful of farmers from spending the daily API quota.
   */
  cacheTtlMs: number;
  /** Upstream page size. The feed returns every market in a state. */
  maxRecords: number;
}

const defaultResourceId = '9ef84268-d588-465a-a308-a864a43d0070';

function positiveInteger(
  values: NodeJS.ProcessEnv,
  name: string,
  fallback: number,
): number {
  const raw = values[name]?.trim();
  if (!raw) return fallback;
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
  return parsed;
}

export function loadMandiConfig(
  values: NodeJS.ProcessEnv = process.env,
): MandiConfig {
  const baseUrl =
    values.DATA_GOV_API_BASE_URL?.trim() || 'https://api.data.gov.in/resource';
  const parsed = new URL(baseUrl);
  if (!['http:', 'https:'].includes(parsed.protocol)) {
    throw new Error('DATA_GOV_API_BASE_URL must be an HTTP(S) URL');
  }
  return {
    apiKey: values.DATA_GOV_API_KEY?.trim() || null,
    baseUrl: baseUrl.replace(/\/+$/, ''),
    resourceId: values.DATA_GOV_MANDI_RESOURCE_ID?.trim() || defaultResourceId,
    timeoutMs: positiveInteger(values, 'MANDI_TIMEOUT_MS', 12_000),
    cacheTtlMs: positiveInteger(values, 'MANDI_CACHE_TTL_MS', 30 * 60 * 1000),
    maxRecords: positiveInteger(values, 'MANDI_MAX_RECORDS', 1000),
  };
}
