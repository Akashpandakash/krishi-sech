import { AppError } from '../../common/app-error.js';
import type { MandiConfig } from '../../config/mandi-config.js';
import type {
  MandiPriceProvider,
  MandiPriceQuery,
  MandiPriceQuote,
} from './mandi-price-provider.js';

interface DataGovResponse {
  records?: unknown;
}

/**
 * Field names in this resource have changed casing across data.gov.in
 * revisions (`Arrival_Date` became `arrival_date`), so every read is
 * case-insensitive rather than pinned to one generation of the feed.
 */
function field(record: Record<string, unknown>, name: string): string | null {
  const wanted = name.toLowerCase();
  for (const [key, value] of Object.entries(record)) {
    if (key.toLowerCase() !== wanted) continue;
    if (typeof value === 'number' && Number.isFinite(value)) {
      return String(value);
    }
    if (typeof value !== 'string') continue;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  }
  return null;
}

/** AGMARKNET publishes `DD/MM/YYYY`; some revisions use `YYYY-MM-DD`. */
function parseArrivalDate(raw: string | null): Date | null {
  if (!raw) return null;
  const slashed = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(raw);
  if (slashed) {
    const [, day, month, year] = slashed;
    return new Date(Date.UTC(Number(year), Number(month) - 1, Number(day)));
  }
  const dashed = /^(\d{4})-(\d{2})-(\d{2})$/.exec(raw);
  if (dashed) {
    const [, year, month, day] = dashed;
    return new Date(Date.UTC(Number(year), Number(month) - 1, Number(day)));
  }
  return null;
}

function parsePrice(raw: string | null): number | null {
  if (!raw) return null;
  const parsed = Number.parseFloat(raw.replace(/[^0-9.-]/g, ''));
  if (!Number.isFinite(parsed) || parsed <= 0) return null;
  return Math.round(parsed);
}

export class DataGovMandiPriceProvider implements MandiPriceProvider {
  constructor(
    private readonly config: MandiConfig,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async fetchQuotes(query: MandiPriceQuery): Promise<MandiPriceQuote[]> {
    if (!this.config.apiKey) {
      throw new AppError(
        503,
        'MANDI_NOT_CONFIGURED',
        'Mandi prices are unavailable because DATA_GOV_API_KEY is not set',
      );
    }
    // `<field>.keyword` is the exact-match filter on the current revision of
    // the resource; older revisions only accept the bare field name. Trying
    // the modern form first and falling back on an empty result keeps the
    // module working across both without a config switch.
    const keyworded = await this.request(query, true);
    if (keyworded.length > 0) return keyworded;
    return this.request(query, false);
  }

  private async request(
    query: MandiPriceQuery,
    keywordSuffix: boolean,
  ): Promise<MandiPriceQuote[]> {
    const suffix = keywordSuffix ? '.keyword' : '';
    const uri = new URL(`${this.config.baseUrl}/${this.config.resourceId}`);
    uri.searchParams.set('api-key', this.config.apiKey!);
    uri.searchParams.set('format', 'json');
    uri.searchParams.set('limit', String(this.config.maxRecords));
    uri.searchParams.set(`filters[state${suffix}]`, query.state);
    if (query.district) {
      uri.searchParams.set(`filters[district${suffix}]`, query.district);
    }
    if (query.commodity) {
      uri.searchParams.set(`filters[commodity${suffix}]`, query.commodity);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.config.timeoutMs);
    try {
      const response = await this.fetcher(uri, { signal: controller.signal });
      if (response.status === 401 || response.status === 403) {
        throw new AppError(
          502,
          'MANDI_UPSTREAM_UNAUTHORIZED',
          'The data.gov.in API key was rejected',
        );
      }
      if (!response.ok) {
        throw new AppError(
          502,
          'MANDI_UPSTREAM_ERROR',
          `Mandi price provider returned HTTP ${response.status}`,
        );
      }
      return this.parse((await response.json()) as DataGovResponse);
    } catch (error) {
      if (error instanceof AppError) throw error;
      if (error instanceof Error && error.name === 'AbortError') {
        throw new AppError(
          504,
          'MANDI_TIMEOUT',
          'Mandi price provider timed out',
        );
      }
      throw new AppError(
        502,
        'MANDI_UPSTREAM_ERROR',
        'Mandi price provider could not be reached',
      );
    } finally {
      clearTimeout(timeout);
    }
  }

  private parse(body: DataGovResponse): MandiPriceQuote[] {
    if (!Array.isArray(body.records)) return [];
    const quotes: MandiPriceQuote[] = [];
    for (const entry of body.records) {
      if (typeof entry !== 'object' || entry === null) continue;
      const record = entry as Record<string, unknown>;
      const state = field(record, 'state');
      const district = field(record, 'district');
      const market = field(record, 'market');
      const commodity = field(record, 'commodity');
      const arrivalDate = parseArrivalDate(field(record, 'arrival_date'));
      const minPrice = parsePrice(field(record, 'min_price'));
      const maxPrice = parsePrice(field(record, 'max_price'));
      const modalPrice = parsePrice(field(record, 'modal_price'));
      // A row missing any of these cannot be rendered as a price, and a
      // partially-filled row is worse than an absent one.
      if (
        !state ||
        !district ||
        !market ||
        !commodity ||
        !arrivalDate ||
        minPrice == null ||
        maxPrice == null ||
        modalPrice == null
      ) {
        continue;
      }
      quotes.push({
        state,
        district,
        market,
        commodity,
        variety: field(record, 'variety'),
        grade: field(record, 'grade'),
        arrivalDate,
        minPrice: Math.min(minPrice, maxPrice),
        maxPrice: Math.max(minPrice, maxPrice),
        modalPrice,
      });
    }
    return quotes;
  }
}
