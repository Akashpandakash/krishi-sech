import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { loadMandiConfig } from '../../config/mandi-config.js';
import { DataGovMandiPriceProvider } from '../providers/data-gov-mandi-price-provider.js';
import type {
  MandiPriceProvider,
  MandiPriceQuote,
} from '../providers/mandi-price-provider.js';
import {
  feedWritableQuotes,
  mandiRecordId,
  mandiSeriesKey,
  type MandiPriceRecord,
  type MandiPriceRepository,
} from '../repositories/mandi-price-repository.js';
import { MandiPriceService } from './mandi-price-service.js';

const config = loadMandiConfig({ DATA_GOV_API_KEY: 'test-key' });

function quote(overrides: Partial<MandiPriceQuote> = {}): MandiPriceQuote {
  return {
    state: 'West Bengal',
    district: 'Nadia',
    market: 'Bethuadahari',
    commodity: 'Potato',
    variety: 'Jyoti',
    grade: 'FAQ',
    arrivalDate: new Date('2026-08-14T00:00:00Z'),
    minPrice: 1000,
    maxPrice: 1200,
    modalPrice: 1100,
    ...overrides,
  };
}

/** Records what was written so the trend path can be exercised end to end. */
class FakeRepository implements MandiPriceRepository {
  saved: MandiPriceQuote[] = [];
  manual: MandiPriceQuote[] = [];
  constructor(private readonly previous = new Map<string, number>()) {}
  async saveQuotes(quotes: MandiPriceQuote[]) {
    this.saved.push(...quotes);
  }
  async findPreviousModalPrices(cutoffs: Map<string, Date>) {
    return new Map(
      [...cutoffs.keys()]
        .filter((key) => this.previous.has(key))
        .map((key) => [key, this.previous.get(key)!]),
    );
  }
  async listRecords() {
    return this.manual.map((quote) => this.toRecord(quote));
  }
  async findManualQuotes() {
    return this.manual;
  }
  async saveManual(quote: MandiPriceQuote) {
    this.manual.push(quote);
    return this.toRecord(quote);
  }
  async deleteRecord(id: string) {
    const before = this.manual.length;
    this.manual = this.manual.filter((quote) => mandiRecordId(quote) !== id);
    return this.manual.length < before;
  }
  async filterOptions() {
    return { states: [], districts: [], commodities: [] };
  }
  private toRecord(quote: MandiPriceQuote): MandiPriceRecord {
    return {
      ...quote,
      id: mandiRecordId(quote),
      seriesKey: mandiSeriesKey(quote),
      source: 'manual',
      recordedAt: new Date('2026-08-14T00:00:00Z'),
    };
  }
}

describe('mandi price service', () => {
  it('reports an unknown trend when no earlier price is held', async () => {
    const provider: MandiPriceProvider = { fetchQuotes: async () => [quote()] };
    const { prices } = await new MandiPriceService(
      provider,
      new FakeRepository(),
      config,
    ).prices({ state: 'West Bengal' });

    assert.equal(prices.length, 1);
    assert.equal(prices[0]!.trend, 'unknown');
    assert.equal(prices[0]!.previousModalPrice, null);
  });

  it('derives the trend from the previous published day', async () => {
    const provider: MandiPriceProvider = { fetchQuotes: async () => [quote()] };
    const repository = new FakeRepository(
      new Map([[mandiSeriesKey(quote()), 900]]),
    );
    const { prices } = await new MandiPriceService(
      provider,
      repository,
      config,
    ).prices({ state: 'West Bengal' });

    assert.equal(prices[0]!.trend, 'up');
    assert.equal(prices[0]!.previousModalPrice, 900);
  });

  it('treats a move inside the deadband as stable, not as a rise', async () => {
    const provider: MandiPriceProvider = { fetchQuotes: async () => [quote()] };
    const repository = new FakeRepository(
      new Map([[mandiSeriesKey(quote()), 1095]]),
    );
    const { prices } = await new MandiPriceService(
      provider,
      repository,
      config,
    ).prices({ state: 'West Bengal' });

    assert.equal(prices[0]!.trend, 'stable');
  });

  it('keeps only the newest arrival date per market and commodity', async () => {
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => [
        quote({ arrivalDate: new Date('2026-08-12T00:00:00Z'), modalPrice: 800 }),
        quote({ arrivalDate: new Date('2026-08-14T00:00:00Z'), modalPrice: 1100 }),
      ],
    };
    const repository = new FakeRepository();
    const { prices } = await new MandiPriceService(
      provider,
      repository,
      config,
    ).prices({ state: 'West Bengal' });

    assert.equal(prices.length, 1);
    assert.equal(prices[0]!.modalPrice, 1100);
    // Only the surviving row is persisted, so a backfilled older row cannot
    // overwrite the current price in history.
    assert.equal(repository.saved.length, 1);
  });

  it('lets an admin entry override the published price for the same series', async () => {
    const provider: MandiPriceProvider = { fetchQuotes: async () => [quote()] };
    const repository = new FakeRepository();
    const service = new MandiPriceService(provider, repository, config);
    await service.saveManual(quote({ modalPrice: 1500, maxPrice: 1600 }));

    const { prices } = await service.prices({ state: 'West Bengal' });
    assert.equal(prices.length, 1);
    assert.equal(prices[0]!.modalPrice, 1500);
  });

  it('does not let an older correction outrank a fresher published price', async () => {
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => [
        quote({ arrivalDate: new Date('2026-08-14T00:00:00Z'), modalPrice: 1100 }),
      ],
    };
    const service = new MandiPriceService(provider, new FakeRepository(), config);
    await service.saveManual(
      quote({ arrivalDate: new Date('2026-08-10T00:00:00Z'), modalPrice: 1500 }),
    );

    const { prices } = await service.prices({ state: 'West Bengal' });
    assert.equal(prices.length, 1);
    // A four-day-old correction is history; today's published price is today's.
    assert.equal(prices[0]!.modalPrice, 1100);
  });

  it('keeps a correction that covers a market the feed never reports', async () => {
    const provider: MandiPriceProvider = { fetchQuotes: async () => [quote()] };
    const service = new MandiPriceService(provider, new FakeRepository(), config);
    await service.saveManual(
      quote({
        market: 'Krishnanagar',
        arrivalDate: new Date('2026-08-10T00:00:00Z'),
      }),
    );

    const { prices } = await service.prices({ state: 'West Bengal' });
    assert.equal(prices.length, 2);
    assert.ok(prices.some((price) => price.market === 'Krishnanagar'));
  });

  it('reports a live answer when the feed responds', async () => {
    const provider: MandiPriceProvider = { fetchQuotes: async () => [quote()] };
    const result = await new MandiPriceService(
      provider,
      new FakeRepository(),
      config,
    ).prices({ state: 'West Bengal' });

    assert.equal(result.live, true);
  });

  it('serves admin entries when the upstream feed fails, flagged as not live', async () => {
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => {
        throw new Error('DATA_GOV_API_KEY is not configured');
      },
    };
    const repository = new FakeRepository();
    const service = new MandiPriceService(provider, repository, config);
    await service.saveManual(quote({ market: 'Krishnanagar' }));

    const { prices, live } = await service.prices({ state: 'West Bengal' });
    assert.equal(prices.length, 1);
    assert.equal(prices[0]!.market, 'Krishnanagar');
    // A handful of hand-entered rows is not the day's market; saying otherwise
    // is the same lie as inventing prices.
    assert.equal(live, false);
  });

  it('retries the feed shortly after a degraded answer', async () => {
    let failing = true;
    let calls = 0;
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => {
        calls += 1;
        if (failing) throw new Error('upstream unavailable');
        return [quote()];
      },
    };
    let clock = 0;
    const service = new MandiPriceService(
      provider,
      new FakeRepository(),
      config,
      () => clock,
    );
    await service.saveManual(quote({ market: 'Krishnanagar' }));

    assert.equal((await service.prices({ state: 'West Bengal' })).live, false);
    // Well inside the normal 30-minute TTL, which must not pin a partial list.
    failing = false;
    clock += 2 * 60 * 1000;

    assert.equal((await service.prices({ state: 'West Bengal' })).live, true);
    assert.equal(calls, 2);
  });

  it('still fails when the feed is down and nothing was entered by hand', async () => {
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => {
        throw new Error('upstream unavailable');
      },
    };
    await assert.rejects(
      () =>
        new MandiPriceService(provider, new FakeRepository(), config).prices({
          state: 'West Bengal',
        }),
      /upstream unavailable/,
    );
  });

  it('drops the cache when an admin edits a price', async () => {
    let calls = 0;
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => {
        calls += 1;
        return [quote()];
      },
    };
    const service = new MandiPriceService(provider, new FakeRepository(), config);
    await service.prices({ state: 'West Bengal' });
    await service.saveManual(quote({ modalPrice: 1300 }));
    const { prices } = await service.prices({ state: 'West Bengal' });

    assert.equal(calls, 2);
    assert.equal(prices[0]!.modalPrice, 1300);
  });

  it('serves a second request for the same query from cache', async () => {
    let calls = 0;
    const provider: MandiPriceProvider = {
      fetchQuotes: async () => {
        calls += 1;
        return [quote()];
      },
    };
    const service = new MandiPriceService(provider, new FakeRepository(), config);
    await service.prices({ state: 'West Bengal' });
    await service.prices({ state: 'west bengal' });
    assert.equal(calls, 1);
  });
});

describe('mandi feed write guard', () => {
  it('skips the rows an operator has corrected', () => {
    const corrected = quote({ modalPrice: 1500 });
    const untouched = quote({ market: 'Ranaghat' });
    const writable = feedWritableQuotes(
      [corrected, untouched],
      [mandiRecordId(corrected)],
    );

    assert.equal(writable.length, 1);
    assert.equal(writable[0]!.market, 'Ranaghat');
  });

  it('writes every row when nothing has been corrected', () => {
    assert.equal(feedWritableQuotes([quote()], []).length, 1);
  });

  it('only shields the corrected day, not the whole series', () => {
    const corrected = quote();
    const nextDay = quote({ arrivalDate: new Date('2026-08-15T00:00:00Z') });
    const writable = feedWritableQuotes(
      [corrected, nextDay],
      [mandiRecordId(corrected)],
    );

    assert.equal(writable.length, 1);
    assert.equal(
      writable[0]!.arrivalDate.toISOString(),
      '2026-08-15T00:00:00.000Z',
    );
  });
});

describe('data.gov.in mandi provider', () => {
  it('parses the published record shape', async () => {
    const provider = new DataGovMandiPriceProvider(
      config,
      async () =>
        new Response(
          JSON.stringify({
            records: [
              {
                state: 'West Bengal',
                district: 'Nadia',
                market: 'Bethuadahari',
                commodity: 'Potato',
                variety: 'Jyoti',
                grade: 'FAQ',
                arrival_date: '14/08/2026',
                min_price: '1000',
                max_price: '1200',
                modal_price: '1100',
              },
            ],
          }),
          { status: 200 },
        ),
    );
    const quotes = await provider.fetchQuotes({ state: 'West Bengal' });
    assert.equal(quotes.length, 1);
    assert.equal(quotes[0]!.commodity, 'Potato');
    assert.equal(quotes[0]!.modalPrice, 1100);
    assert.equal(
      quotes[0]!.arrivalDate.toISOString(),
      '2026-08-14T00:00:00.000Z',
    );
  });

  it('reads the older capitalised field names too', async () => {
    const provider = new DataGovMandiPriceProvider(
      config,
      async () =>
        new Response(
          JSON.stringify({
            records: [
              {
                State: 'Punjab',
                District: 'Ludhiana',
                Market: 'Khanna',
                Commodity: 'Wheat',
                Arrival_Date: '2026-08-14',
                Min_Price: '2400',
                Max_Price: '2500',
                Modal_Price: '2450',
              },
            ],
          }),
          { status: 200 },
        ),
    );
    const quotes = await provider.fetchQuotes({ state: 'Punjab' });
    assert.equal(quotes.length, 1);
    assert.equal(quotes[0]!.commodity, 'Wheat');
    assert.equal(quotes[0]!.variety, null);
  });

  it('drops rows that cannot be rendered as a price', async () => {
    const provider = new DataGovMandiPriceProvider(
      config,
      async () =>
        new Response(
          JSON.stringify({
            records: [
              { state: 'Bihar', district: 'Patna', market: 'Patna City' },
              {
                state: 'Bihar',
                district: 'Patna',
                market: 'Patna City',
                commodity: 'Onion',
                arrival_date: '14/08/2026',
                min_price: '0',
                max_price: '1500',
                modal_price: '1400',
              },
            ],
          }),
          { status: 200 },
        ),
    );
    assert.deepEqual(await provider.fetchQuotes({ state: 'Bihar' }), []);
  });

  it('fails loudly when no API key is configured', async () => {
    const provider = new DataGovMandiPriceProvider(loadMandiConfig({}));
    await assert.rejects(
      () => provider.fetchQuotes({ state: 'West Bengal' }),
      /DATA_GOV_API_KEY/,
    );
  });
});
