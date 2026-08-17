import type { MandiConfig } from '../../config/mandi-config.js';
import type {
  MandiPriceProvider,
  MandiPriceQuery,
  MandiPriceQuote,
} from '../providers/mandi-price-provider.js';
import { AppError } from '../../common/app-error.js';
import {
  mandiSeriesKey,
  type MandiFilterOptions,
  type MandiPriceRecord,
  type MandiPriceRepository,
  type MandiRecordQuery,
} from '../repositories/mandi-price-repository.js';

export type MandiPriceTrend = 'up' | 'down' | 'stable' | 'unknown';

export interface MandiPriceView {
  /** Stable across days: identifies the series, not one day's row. */
  id: string;
  state: string;
  district: string;
  market: string;
  commodity: string;
  variety: string | null;
  grade: string | null;
  minPrice: number;
  maxPrice: number;
  modalPrice: number;
  /** AGMARKNET publishes every price per quintal. */
  unit: 'quintal';
  arrivalDate: string;
  trend: MandiPriceTrend;
  previousModalPrice: number | null;
}

export interface MandiPriceResult {
  prices: MandiPriceView[];
  /**
   * False when AGMARKNET failed and the rows are whatever operators had
   * entered by hand. Admin rows are a sparse supplement, not a replacement, so
   * a partial list must never render as the day's full market.
   */
  live: boolean;
}

/**
 * Day-to-day noise of a few rupees is not a movement a farmer should act on,
 * so a modal price within this band of the previous day reads as stable.
 */
const trendDeadbandRatio = 0.01;

/** A degraded answer is held just long enough to absorb a burst of retries. */
const degradedCacheTtlMs = 60_000;

interface CacheEntry {
  expiresAt: number;
  value: MandiPriceResult;
}

export class MandiPriceService {
  private readonly cache = new Map<string, CacheEntry>();

  constructor(
    private readonly provider: MandiPriceProvider,
    private readonly repository: MandiPriceRepository,
    private readonly config: MandiConfig,
    private readonly now: () => number = () => Date.now(),
  ) {}

  async prices(query: MandiPriceQuery): Promise<MandiPriceResult> {
    const cacheKey = [
      query.state,
      query.district ?? '',
      query.commodity ?? '',
    ]
      .map((part) => part.trim().toLowerCase())
      .join('|');
    const cached = this.cache.get(cacheKey);
    if (cached && cached.expiresAt > this.now()) return cached.value;

    const manual = await this.repository.findManualQuotes(query);
    let published: MandiPriceQuote[] = [];
    let live = true;
    try {
      published = await this.provider.fetchQuotes(query);
    } catch (error) {
      // Admin rows are worth showing when the feed is down, but they are a
      // supplement to it — the caller is told the list is incomplete rather
      // than being handed a partial market as if it were the whole one.
      if (manual.length === 0) throw error;
      live = false;
    }

    const latest = this.latestPerSeries(published);
    if (latest.length > 0) {
      // Persisting before reading history is what lets tomorrow's request
      // compute a trend against today.
      await this.repository.saveQuotes(latest);
    }

    // Newest arrival wins, and a tie goes to the operator: a correction beats
    // the day it was made for, but yesterday's correction must not outrank a
    // price the feed published today.
    const merged = new Map(latest.map((quote) => [mandiSeriesKey(quote), quote]));
    for (const quote of manual) {
      const key = mandiSeriesKey(quote);
      const published = merged.get(key);
      if (
        published &&
        published.arrivalDate.getTime() > quote.arrivalDate.getTime()
      ) {
        continue;
      }
      merged.set(key, quote);
    }

    const result: MandiPriceResult = {
      prices: await this.withTrend([...merged.values()]),
      live,
    };
    this.cache.set(cacheKey, {
      expiresAt:
        this.now() + (live ? this.config.cacheTtlMs : degradedCacheTtlMs),
      value: result,
    });
    return result;
  }

  /* ------------------------------------------------------ admin management */

  listRecords(query: MandiRecordQuery): Promise<MandiPriceRecord[]> {
    return this.repository.listRecords(query);
  }

  filterOptions(): Promise<MandiFilterOptions> {
    return this.repository.filterOptions();
  }

  async saveManual(quote: MandiPriceQuote): Promise<MandiPriceRecord> {
    const record = await this.repository.saveManual(quote);
    this.cache.clear();
    return record;
  }

  /** Editing the market or the date moves the row, so the old id is dropped. */
  async updateManual(
    id: string,
    quote: MandiPriceQuote,
  ): Promise<MandiPriceRecord> {
    const record = await this.saveManual(quote);
    if (record.id !== id) await this.repository.deleteRecord(id);
    return record;
  }

  async deleteRecord(id: string): Promise<void> {
    const deleted = await this.repository.deleteRecord(id);
    if (!deleted) {
      throw new AppError(404, 'MANDI_PRICE_NOT_FOUND', 'Price row not found');
    }
    this.cache.clear();
  }

  /**
   * The feed can carry several arrival dates for one market at once (late
   * entries backfill), and only the newest is the current price.
   */
  private latestPerSeries(quotes: MandiPriceQuote[]): MandiPriceQuote[] {
    const bySeries = new Map<string, MandiPriceQuote>();
    for (const quote of quotes) {
      const key = mandiSeriesKey(quote);
      const current = bySeries.get(key);
      if (
        !current ||
        quote.arrivalDate.getTime() > current.arrivalDate.getTime()
      ) {
        bySeries.set(key, quote);
      }
    }
    return [...bySeries.values()];
  }

  private async withTrend(
    quotes: MandiPriceQuote[],
  ): Promise<MandiPriceView[]> {
    if (quotes.length === 0) return [];
    const seriesKeys = quotes.map(mandiSeriesKey);
    const previous = await this.repository.findPreviousModalPrices(
      new Map(quotes.map((quote, index) => [seriesKeys[index]!, quote.arrivalDate])),
    );

    return quotes
      .map((quote, index) => {
        const seriesKey = seriesKeys[index]!;
        const earlier = previous.get(seriesKey) ?? null;
        return {
          id: seriesKey,
          state: quote.state,
          district: quote.district,
          market: quote.market,
          commodity: quote.commodity,
          variety: quote.variety,
          grade: quote.grade,
          minPrice: quote.minPrice,
          maxPrice: quote.maxPrice,
          modalPrice: quote.modalPrice,
          unit: 'quintal' as const,
          arrivalDate: quote.arrivalDate.toISOString(),
          trend: trendFor(quote.modalPrice, earlier),
          previousModalPrice: earlier,
        };
      })
      .sort(
        (left, right) =>
          left.commodity.localeCompare(right.commodity) ||
          left.market.localeCompare(right.market),
      );
  }
}

function trendFor(current: number, previous: number | null): MandiPriceTrend {
  // No earlier point is genuinely unknown, and reporting it as "stable" would
  // claim a comparison that was never made.
  if (previous == null || previous <= 0) return 'unknown';
  const change = (current - previous) / previous;
  if (Math.abs(change) < trendDeadbandRatio) return 'stable';
  return change > 0 ? 'up' : 'down';
}
