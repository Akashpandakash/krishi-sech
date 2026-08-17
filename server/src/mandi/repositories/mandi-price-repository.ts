import type {
  MandiPriceQuery,
  MandiPriceQuote,
} from '../providers/mandi-price-provider.js';

/** `manual` rows are admin-entered and survive a feed refresh. */
export const mandiPriceSources = ['agmarknet', 'manual'] as const;
export type MandiPriceSource = (typeof mandiPriceSources)[number];

/**
 * A quote as stored. The upstream feed only ever publishes the current day's
 * snapshot, so a price trend can only come from our own history — that is the
 * whole reason quotes are persisted rather than proxied straight through.
 */
export interface MandiPriceRecord extends MandiPriceQuote {
  id: string;
  seriesKey: string;
  source: MandiPriceSource;
  recordedAt: Date;
}

export interface MandiRecordQuery {
  state?: string;
  district?: string;
  commodity?: string;
  source?: MandiPriceSource;
  /** Substring match against the market and the commodity. */
  search?: string;
  limit: number;
}

export interface MandiFilterOptions {
  states: string[];
  districts: string[];
  commodities: string[];
}

/**
 * Identifies one continuous price series: the same produce, in the same
 * market, across days. Trend is the comparison of two points on this series.
 */
export function mandiSeriesKey(
  quote: Pick<
    MandiPriceQuote,
    'state' | 'district' | 'market' | 'commodity' | 'variety'
  >,
): string {
  return [
    quote.state,
    quote.district,
    quote.market,
    quote.commodity,
    quote.variety ?? '',
  ]
    .map((part) => part.trim().toLowerCase())
    .join('|');
}

export function mandiRecordId(quote: MandiPriceQuote): string {
  const day = quote.arrivalDate.toISOString().slice(0, 10);
  return `${mandiSeriesKey(quote)}|${day}`;
}

/**
 * The feed rows a refresh may write: everything except the ids an operator
 * has taken over. Dropping this guard would let a nightly refresh silently
 * undo a correction, so it is kept separate from Mongo to stay testable.
 */
export function feedWritableQuotes(
  quotes: MandiPriceQuote[],
  manualIds: Iterable<string>,
): MandiPriceQuote[] {
  const owned = new Set(manualIds);
  return quotes.filter((quote) => !owned.has(mandiRecordId(quote)));
}

export interface MandiPriceRepository {
  /**
   * Idempotent: the record id is derived from the series and arrival date, so
   * re-reading the same published day overwrites rather than duplicates.
   * Rows an operator has taken over (`source: 'manual'`) are left alone.
   */
  saveQuotes(quotes: MandiPriceQuote[]): Promise<void>;

  /**
   * Modal price on the newest arrival date strictly before each series' own
   * cutoff. Series with no earlier record are absent from the map, which the
   * service reports as an unknown (rather than flat) trend. The cutoff is per
   * series because merged rows do not share one arrival date.
   */
  findPreviousModalPrices(
    cutoffs: Map<string, Date>,
  ): Promise<Map<string, number>>;

  /** Newest first, for the admin table. */
  listRecords(query: MandiRecordQuery): Promise<MandiPriceRecord[]>;

  /** Newest manual quote per series matching an app query, merged over the feed. */
  findManualQuotes(query: MandiPriceQuery): Promise<MandiPriceQuote[]>;

  saveManual(quote: MandiPriceQuote): Promise<MandiPriceRecord>;

  /** False when the row was already gone. */
  deleteRecord(id: string): Promise<boolean>;

  filterOptions(): Promise<MandiFilterOptions>;
}
