import type { MandiPriceDocument, MongoDatabase } from '../../database/mongo-database.js';
import type {
  MandiPriceQuery,
  MandiPriceQuote,
} from '../providers/mandi-price-provider.js';
import {
  feedWritableQuotes,
  mandiRecordId,
  mandiSeriesKey,
  type MandiFilterOptions,
  type MandiPriceRecord,
  type MandiPriceRepository,
  type MandiRecordQuery,
} from './mandi-price-repository.js';

/** Trend only ever looks days back; a wider window would scan for nothing. */
const trendLookbackDays = 30;

/** A manual row this old is history, not today's price. */
const manualVisibilityDays = 30;

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** Case-insensitive exact match; operators type "Nadia", the feed says "NADIA". */
function exact(value: string): RegExp {
  return new RegExp(`^${escapeRegExp(value.trim())}$`, 'i');
}

function toRecord(document: MandiPriceDocument): MandiPriceRecord {
  const { _id, ...rest } = document;
  return {
    ...rest,
    id: _id,
    // Rows written before the column existed are all feed rows.
    source: rest.source ?? 'agmarknet',
  };
}

function toQuote(record: MandiPriceRecord): MandiPriceQuote {
  return {
    state: record.state,
    district: record.district,
    market: record.market,
    commodity: record.commodity,
    variety: record.variety,
    grade: record.grade,
    arrivalDate: record.arrivalDate,
    minPrice: record.minPrice,
    maxPrice: record.maxPrice,
    modalPrice: record.modalPrice,
  };
}

export class MongoMandiPriceRepository implements MandiPriceRepository {
  constructor(private readonly database: MongoDatabase) {}

  async saveQuotes(quotes: MandiPriceQuote[]): Promise<void> {
    if (quotes.length === 0) return;
    const ids = quotes.map(mandiRecordId);
    const owned = await this.database.mandiPrices
      .find({ _id: { $in: ids }, source: 'manual' })
      .select({ _id: 1 })
      .lean();
    const writable = feedWritableQuotes(
      quotes,
      (owned as { _id: string }[]).map((row) => row._id),
    );
    if (writable.length === 0) return;

    const recordedAt = new Date();
    // One published day arrives as one batch; an unordered bulk write keeps a
    // single malformed row from dropping the rest.
    await this.database.mandiPrices.bulkWrite(
      writable.map((quote) => ({
        updateOne: {
          filter: { _id: mandiRecordId(quote) },
          update: {
            $set: {
              ...quote,
              seriesKey: mandiSeriesKey(quote),
              source: 'agmarknet',
              recordedAt,
            },
          },
          upsert: true,
        },
      })),
      { ordered: false },
    );
  }

  async findPreviousModalPrices(
    cutoffs: Map<string, Date>,
  ): Promise<Map<string, number>> {
    if (cutoffs.size === 0) return new Map();
    const newest = Math.max(
      ...[...cutoffs.values()].map((date) => date.getTime()),
    );
    const since = new Date(newest - trendLookbackDays * 24 * 60 * 60 * 1000);
    const documents = await this.database.mandiPrices
      .find({
        seriesKey: { $in: [...cutoffs.keys()] },
        arrivalDate: { $gte: since, $lt: new Date(newest) },
      })
      .sort({ arrivalDate: -1 })
      .lean();

    const previous = new Map<string, number>();
    // Descending by date, so the first row inside a series' own cutoff is its
    // newest earlier point.
    for (const document of documents as MandiPriceDocument[]) {
      const cutoff = cutoffs.get(document.seriesKey);
      if (!cutoff || document.arrivalDate.getTime() >= cutoff.getTime()) {
        continue;
      }
      if (previous.has(document.seriesKey)) continue;
      previous.set(document.seriesKey, document.modalPrice);
    }
    return previous;
  }

  async listRecords(query: MandiRecordQuery): Promise<MandiPriceRecord[]> {
    const filter: Record<string, unknown> = {};
    if (query.state) filter.state = exact(query.state);
    if (query.district) filter.district = exact(query.district);
    if (query.commodity) filter.commodity = exact(query.commodity);
    if (query.source === 'manual') filter.source = 'manual';
    if (query.source === 'agmarknet') filter.source = { $ne: 'manual' };
    if (query.search) {
      const pattern = new RegExp(escapeRegExp(query.search.trim()), 'i');
      filter.$or = [{ market: pattern }, { commodity: pattern }];
    }
    const documents = await this.database.mandiPrices
      .find(filter)
      .sort({ arrivalDate: -1, recordedAt: -1 })
      .limit(query.limit)
      .lean();
    return (documents as MandiPriceDocument[]).map(toRecord);
  }

  async findManualQuotes(query: MandiPriceQuery): Promise<MandiPriceQuote[]> {
    const since = new Date(
      Date.now() - manualVisibilityDays * 24 * 60 * 60 * 1000,
    );
    const filter: Record<string, unknown> = {
      source: 'manual',
      state: exact(query.state),
      arrivalDate: { $gte: since },
    };
    if (query.district) filter.district = exact(query.district);
    if (query.commodity) filter.commodity = exact(query.commodity);

    const documents = await this.database.mandiPrices
      .find(filter)
      .sort({ arrivalDate: -1 })
      .lean();

    const newest = new Map<string, MandiPriceQuote>();
    for (const document of documents as MandiPriceDocument[]) {
      if (newest.has(document.seriesKey)) continue;
      newest.set(document.seriesKey, toQuote(toRecord(document)));
    }
    return [...newest.values()];
  }

  async saveManual(quote: MandiPriceQuote): Promise<MandiPriceRecord> {
    const id = mandiRecordId(quote);
    const record: MandiPriceRecord = {
      ...quote,
      id,
      seriesKey: mandiSeriesKey(quote),
      source: 'manual',
      recordedAt: new Date(),
    };
    const { id: _ignored, ...fields } = record;
    await this.database.mandiPrices.updateOne(
      { _id: id },
      { $set: fields },
      { upsert: true },
    );
    return record;
  }

  async deleteRecord(id: string): Promise<boolean> {
    const result = await this.database.mandiPrices.deleteOne({ _id: id });
    return result.deletedCount > 0;
  }

  async filterOptions(): Promise<MandiFilterOptions> {
    const [states, districts, commodities] = await Promise.all([
      this.database.mandiPrices.distinct('state'),
      this.database.mandiPrices.distinct('district'),
      this.database.mandiPrices.distinct('commodity'),
    ]);
    const clean = (values: unknown[]) =>
      values
        .filter((value): value is string => typeof value === 'string' && value.length > 0)
        .sort((left, right) => left.localeCompare(right));
    return {
      states: clean(states),
      districts: clean(districts),
      commodities: clean(commodities),
    };
  }
}
