import '../config/load-environment.js';

import { createHash } from 'node:crypto';

import { loadAppConfig } from '../config/app-config.js';
import {
  mandiRecordId,
  mandiSeriesKey,
} from '../mandi/repositories/mandi-price-repository.js';
import {
  MongoDatabase,
  type BroadcastDocument,
  type BroadcastReceiptDocument,
  type CalendarTaskDocument,
  type CropDocument,
  type DeviceDocument,
  type FarmProfileDocument,
  type FertilizerRecommendationDocument,
  type IrrigationRecommendationDocument,
  type MandiPriceDocument,
  type MarketProductDocument,
  type UserDocument,
} from './mongo-database.js';

/**
 * Fills a development database with believable farm data.
 *
 * Two properties make this safe to run repeatedly: every document id is
 * derived from a fixed string rather than generated, and every write is an
 * upsert on that id. Re-running updates the same rows instead of growing the
 * database, and `--reset` can delete exactly what the seed owns without
 * touching anything a human created.
 *
 * Usage:
 *   npm run db:seed
 *   npm run db:seed -- --farmers 12
 *   npm run db:seed -- --reset
 *   npm run db:seed -- --clean
 */

// ---------------------------------------------------------------------------
// Deterministic identity
// ---------------------------------------------------------------------------

/**
 * A stable UUID for a seed key. This is UUIDv5 in shape — a hash of a
 * namespace plus a name, with the version and variant bits set — so the ids
 * look and validate exactly like the `randomUUID()` values the app writes.
 *
 * Crop ids in particular *must* be real UUIDs: `GET /api/crops/:id` and the
 * recommendation endpoints validate them with `z.uuid()` and would reject a
 * readable placeholder.
 */
function seedUuid(key: string): string {
  const hash = createHash('sha1').update(`krishi-sech-seed:${key}`).digest();
  const bytes = Buffer.from(hash.subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x50; // version 5
  bytes[8] = (bytes[8]! & 0x3f) | 0x80; // RFC 4122 variant
  const hex = bytes.toString('hex');
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32),
  ].join('-');
}

/**
 * Small deterministic PRNG. `Math.random()` would make every run produce a
 * different database, which defeats the point of stable ids.
 */
function randomFor(key: string): () => number {
  let state = createHash('sha1').update(key).digest().readUInt32BE(0);
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick<T>(random: () => number, values: readonly T[]): T {
  return values[Math.floor(random() * values.length)]!;
}

function integer(random: () => number, min: number, max: number): number {
  return min + Math.floor(random() * (max - min + 1));
}

const DAY_MS = 24 * 60 * 60 * 1000;

function daysFromNow(days: number, hour = 6): Date {
  const date = new Date(Date.now() + days * DAY_MS);
  date.setUTCHours(hour, 0, 0, 0);
  return date;
}

/** Mandi arrival dates are compared by day, so they must sit at UTC midnight. */
function utcMidnight(daysAgo: number): Date {
  const date = new Date(Date.now() - daysAgo * DAY_MS);
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
}

// ---------------------------------------------------------------------------
// Source material
// ---------------------------------------------------------------------------

interface Place {
  state: string;
  district: string;
  village: string;
  market: string;
}

const places: readonly Place[] = [
  { state: 'West Bengal', district: 'Nadia', village: 'Haringhata', market: 'Ranaghat' },
  { state: 'West Bengal', district: 'Bardhaman', village: 'Memari', market: 'Bardhaman' },
  { state: 'West Bengal', district: 'Hooghly', village: 'Polba', market: 'Chinsurah' },
  { state: 'Bihar', district: 'Muzaffarpur', village: 'Kanti', market: 'Muzaffarpur' },
  { state: 'Bihar', district: 'Samastipur', village: 'Pusa', market: 'Samastipur' },
  { state: 'Uttar Pradesh', district: 'Varanasi', village: 'Pindra', market: 'Varanasi' },
  { state: 'Odisha', district: 'Cuttack', village: 'Salepur', market: 'Cuttack' },
  { state: 'Assam', district: 'Nagaon', village: 'Dhing', market: 'Nagaon' },
];

const farmerNames = [
  'Ranjan Das',
  'Sabita Mondal',
  'Arun Kumar Sah',
  'Phulmani Hembram',
  'Nitai Ghosh',
  'Rekha Devi',
  'Sanjib Barman',
  'Anwara Begum',
  'Dipak Pradhan',
  'Kalpana Bhuyan',
  'Haren Saikia',
  'Mira Patra',
] as const;

const farmerTypes = ['marginal', 'smallholder', 'medium', 'large'] as const;
const irrigationSources = ['canal', 'borewell', 'pond', 'river lift', 'rainfed'] as const;
const languages = ['bn', 'hi', 'en', 'or', 'as'] as const;

interface CropSeed {
  cropName: string;
  varieties: readonly string[];
  commodity: string;
}

const cropCatalogue: readonly CropSeed[] = [
  { cropName: 'Rice', varieties: ['Swarna', 'IR-64', 'Ranjit'], commodity: 'Rice' },
  { cropName: 'Potato', varieties: ['Kufri Jyoti', 'Kufri Chandramukhi'], commodity: 'Potato' },
  { cropName: 'Mustard', varieties: ['Pusa Bold', 'Varuna'], commodity: 'Mustard' },
  { cropName: 'Wheat', varieties: ['HD-2967', 'PBW-343'], commodity: 'Wheat' },
  { cropName: 'Jute', varieties: ['JRO-524'], commodity: 'Jute' },
  { cropName: 'Onion', varieties: ['Nasik Red', 'Bhima Shakti'], commodity: 'Onion' },
];

const growthStages = [
  'sowing',
  'germination',
  'seedling',
  'vegetative',
  'flowering',
  'fruiting',
  'maturity',
  'harvested',
] as const;
const landUnits = ['acre', 'hectare', 'bigha', 'katha'] as const;
const soilTypes = ['alluvial', 'black', 'red', 'laterite', 'sandy', 'clay', 'loamy'] as const;
const irrigationMethods = ['drip', 'sprinkler', 'flood', 'rainFed', 'manual'] as const;
const healthStatuses = ['healthy', 'healthy', 'moderate', 'needsAttention'] as const;
const taskTypes = ['irrigation', 'fertilizer', 'pestInspection', 'harvest'] as const;

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

interface SeedData {
  users: UserDocument[];
  farmProfiles: FarmProfileDocument[];
  crops: CropDocument[];
  calendarTasks: CalendarTaskDocument[];
  irrigationRecommendations: IrrigationRecommendationDocument[];
  fertilizerRecommendations: FertilizerRecommendationDocument[];
  devices: DeviceDocument[];
  marketProducts: MarketProductDocument[];
  mandiPrices: MandiPriceDocument[];
  broadcasts: BroadcastDocument[];
  broadcastReceipts: BroadcastReceiptDocument[];
}

function buildFarmers(count: number): {
  users: UserDocument[];
  farmProfiles: FarmProfileDocument[];
  crops: CropDocument[];
  calendarTasks: CalendarTaskDocument[];
  irrigationRecommendations: IrrigationRecommendationDocument[];
  fertilizerRecommendations: FertilizerRecommendationDocument[];
  devices: DeviceDocument[];
} {
  const users: UserDocument[] = [];
  const farmProfiles: FarmProfileDocument[] = [];
  const crops: CropDocument[] = [];
  const calendarTasks: CalendarTaskDocument[] = [];
  const irrigationRecommendations: IrrigationRecommendationDocument[] = [];
  const fertilizerRecommendations: FertilizerRecommendationDocument[] = [];
  const devices: DeviceDocument[] = [];

  for (let index = 0; index < count; index += 1) {
    const random = randomFor(`farmer:${index}`);
    const userId = seedUuid(`user:${index}`);
    const place = places[index % places.length]!;
    const name = farmerNames[index % farmerNames.length]!;
    const joinedDaysAgo = integer(random, 20, 300);
    const createdAt = daysFromNow(-joinedDaysAgo, 9);
    // Every account is reachable at +9198000000NN, a block reserved for the
    // seed so real numbers can never collide with it.
    const phone = `+9198000000${String(index + 1).padStart(2, '0')}`;
    // A tenth of accounts are blocked, so the admin panel has both states.
    const isActive = index % 10 !== 4;

    users.push({
      _id: userId,
      phone,
      email: null,
      googleId: null,
      name,
      preferredLanguage: pick(random, languages),
      profilePhotoUrl: null,
      state: place.state,
      district: place.district,
      village: place.village,
      isActive,
      fcmToken: null,
      fcmTokenUpdatedAt: null,
      createdAt,
      updatedAt: daysFromNow(-integer(random, 0, 10), 11),
    });

    // One account in six never completed farm setup — the app has a real
    // "profile missing" path and it should be exercised.
    if (index % 6 !== 3) {
      const landArea = Number((random() * 9 + 0.5).toFixed(1));
      farmProfiles.push({
        _id: seedUuid(`farm:${index}`),
        userId,
        farmName: `${name.split(' ')[0]} Family Farm`,
        farmerType: pick(random, farmerTypes),
        totalLandArea: landArea,
        landUnit: 'acre',
        soilType: pick(random, soilTypes),
        irrigationSource: pick(random, irrigationSources),
        mainCrops: [
          pick(random, cropCatalogue).cropName,
          pick(random, cropCatalogue).cropName,
        ].filter((value, position, all) => all.indexOf(value) === position),
        coarseLocation: `${place.village}, ${place.district}`,
        createdAt,
        updatedAt: createdAt,
      });
    }

    const cropCount = integer(random, 1, 3);
    for (let cropIndex = 0; cropIndex < cropCount; cropIndex += 1) {
      const cropRandom = randomFor(`crop:${index}:${cropIndex}`);
      const cropId = seedUuid(`crop:${index}:${cropIndex}`);
      const catalogue = pick(cropRandom, cropCatalogue);
      const sowingDaysAgo = integer(cropRandom, 15, 120);
      const sowingDate = daysFromNow(-sowingDaysAgo, 6);
      const cropCreatedAt = daysFromNow(-sowingDaysAgo + 1, 8);
      const irrigationMethod = pick(cropRandom, irrigationMethods);

      crops.push({
        _id: cropId,
        userId,
        cropName: catalogue.cropName,
        variety: pick(cropRandom, catalogue.varieties),
        // Never in the future: the crop schema rejects that on write, and a
        // seeded row that the API would refuse is a trap for the next person.
        sowingDate,
        growthStage: pick(cropRandom, growthStages.slice(0, 7)),
        landArea: Number((cropRandom() * 4 + 0.3).toFixed(2)),
        landUnit: pick(cropRandom, landUnits),
        soilType: pick(cropRandom, soilTypes),
        irrigationMethod,
        expectedHarvestDate: daysFromNow(
          -sowingDaysAgo + integer(cropRandom, 100, 160),
          6,
        ),
        healthStatus: pick(cropRandom, healthStatuses),
        notes: cropIndex === 0 ? 'Transplanted from the north seedbed.' : null,
        createdAt: cropCreatedAt,
        updatedAt: daysFromNow(-integer(cropRandom, 0, 14), 10),
      } as CropDocument);

      // Tasks spread across the past and the future so the calendar shows
      // completed, pending and overdue at once.
      const taskOffsets = [-21, -9, -2, 3, 11, 24];
      taskOffsets.forEach((offset, taskIndex) => {
        const taskRandom = randomFor(`task:${index}:${cropIndex}:${taskIndex}`);
        calendarTasks.push({
          _id: seedUuid(`task:${index}:${cropIndex}:${taskIndex}`),
          userId,
          cropId,
          taskType: pick(taskRandom, taskTypes),
          dueDate: daysFromNow(offset, integer(taskRandom, 5, 16)),
          // Past tasks are mostly done; the stragglers become the overdue
          // count the admin dashboard reports.
          status: offset < 0 && taskRandom() > 0.25 ? 'completed' : 'pending',
          notes: taskIndex === 2 ? 'Check the field drain first.' : null,
          reminderEnabled: taskRandom() > 0.35,
          createdAt: cropCreatedAt,
          updatedAt: cropCreatedAt,
        });
      });

      // Advisory history, so the recommendation screens have something behind
      // them on first open.
      if (cropIndex === 0) {
        const landType = irrigationMethod === 'rainFed' ? 'rainfed' : 'irrigated';
        for (let pass = 0; pass < 2; pass += 1) {
          const advisoryRandom = randomFor(`advisory:${index}:${pass}`);
          const createdAtAdvisory = daysFromNow(-(pass + 1) * 7, 7);
          irrigationRecommendations.push({
            _id: seedUuid(`irrigation:${index}:${pass}`),
            userId,
            cropId,
            irrigationRequired: advisoryRandom() > 0.35,
            waterQuantity: {
              value: integer(advisoryRandom, 8000, 16000),
              unit: 'liters',
              per: 'acre',
            },
            bestIrrigationTime: 'Early morning, 5–7 AM',
            irrigationMethod,
            nextIrrigationDate: daysFromNow(-(pass + 1) * 7 + 4, 6),
            confidence: Number((0.6 + advisoryRandom() * 0.35).toFixed(2)),
            reasoning:
              'Vegetative stage with no rain forecast and six days since the last irrigation.',
            language: 'en',
            landType,
            engineVersion: 'rules-v1',
            createdAt: createdAtAdvisory,
          } as IrrigationRecommendationDocument);

          fertilizerRecommendations.push({
            _id: seedUuid(`fertilizer:${index}:${pass}`),
            userId,
            cropId,
            recommendedFertilizer: pick(advisoryRandom, [
              'Urea',
              'DAP',
              'MOP',
              'NPK 10:26:26',
            ]),
            quantity: {
              value: integer(advisoryRandom, 20, 60),
              unit: 'kg',
              per: 'acre',
            },
            applicationMethod:
              'Broadcast evenly over moist soil, then irrigate lightly.',
            bestApplicationTime: 'Early morning before the wind picks up',
            safetyPrecautions: [
              'Wear gloves and cover your mouth while spreading.',
              'Do not apply within 24 hours of heavy rain.',
            ],
            organicAlternative: 'Well-rotted farmyard manure, 2 tonnes per acre',
            nextRecommendationDate: daysFromNow(-(pass + 1) * 7 + 19, 6),
            confidence: Number((0.6 + advisoryRandom() * 0.3).toFixed(2)),
            language: 'en',
            engineVersion: 'rules-v1',
            createdAt: createdAtAdvisory,
          } as FertilizerRecommendationDocument);
        }
      }
    }

    // Two accounts in three carry a push registration; the rest are the
    // "sent but unreachable" case the broadcast counters have to survive.
    if (index % 3 !== 2) {
      const token = `seed-fcm-${seedUuid(`device:${index}`)}-${index}`;
      const updatedAt = daysFromNow(-integer(random, 0, 6), 12);
      devices.push({
        _id: seedUuid(`device:${index}`),
        userId,
        token,
        platform: index % 4 === 1 ? 'ios' : 'android',
        createdAt,
        updatedAt,
      });
      users[users.length - 1]!.fcmToken = token;
      users[users.length - 1]!.fcmTokenUpdatedAt = updatedAt;
    }
  }

  return {
    users,
    farmProfiles,
    crops,
    calendarTasks,
    irrigationRecommendations,
    fertilizerRecommendations,
    devices,
  };
}

interface ProductSeed {
  key: string;
  en: string;
  bn: string;
  hi: string;
  descriptionEn: string;
  descriptionBn: string;
  category: 'seeds' | 'fertilizers' | 'tools';
  price: number;
  unit: 'bag' | 'pack' | 'piece' | 'kg' | 'litre';
  stock: number;
  vendor: string;
}

const productCatalogue: readonly ProductSeed[] = [
  {
    key: 'swarna-paddy-seed',
    en: 'Swarna paddy seed',
    bn: 'স্বর্ণ ধানের বীজ',
    hi: 'स्वर्ण धान बीज',
    descriptionEn: 'High-yield aman paddy seed, 10 kg bag.',
    descriptionBn: 'উচ্চ ফলনশীল আমন ধানের বীজ, ১০ কেজি ব্যাগ।',
    category: 'seeds', price: 850, unit: 'bag', stock: 42,
    vendor: 'Nadia Agro Supplies',
  },
  {
    key: 'kufri-jyoti-seed-potato',
    en: 'Kufri Jyoti seed potato',
    bn: 'কুফরি জ্যোতি বীজ আলু',
    hi: 'कुफरी ज्योति बीज आलू',
    descriptionEn: 'Certified seed potato, 50 kg bag.',
    descriptionBn: 'প্রত্যয়িত বীজ আলু, ৫০ কেজি ব্যাগ।',
    category: 'seeds', price: 1450, unit: 'bag', stock: 18,
    vendor: 'Bardhaman Seed House',
  },
  {
    key: 'mustard-pusa-bold',
    en: 'Pusa Bold mustard seed',
    bn: 'পুসা বোল্ড সরিষার বীজ',
    hi: 'पूसा बोल्ड सरसों बीज',
    descriptionEn: 'Short-duration mustard, 1 kg pack.',
    descriptionBn: 'স্বল্পমেয়াদি সরিষা, ১ কেজি প্যাক।',
    category: 'seeds', price: 210, unit: 'pack', stock: 0,
    vendor: 'Pusa Krishi Kendra',
  },
  {
    key: 'urea-45kg',
    en: 'Urea 46% N',
    bn: 'ইউরিয়া ৪৬% নাইট্রোজেন',
    hi: 'यूरिया 46% नाइट्रोजन',
    descriptionEn: 'Nitrogen fertilizer, 45 kg bag.',
    descriptionBn: 'নাইট্রোজেন সার, ৪৫ কেজি ব্যাগ।',
    category: 'fertilizers', price: 267, unit: 'bag', stock: 320,
    vendor: 'IFFCO Depot',
  },
  {
    key: 'dap-50kg',
    en: 'DAP 18:46:0',
    bn: 'ডিএপি ১৮:৪৬:০',
    hi: 'डीएपी 18:46:0',
    descriptionEn: 'Phosphate fertilizer, 50 kg bag.',
    descriptionBn: 'ফসফেট সার, ৫০ কেজি ব্যাগ।',
    category: 'fertilizers', price: 1350, unit: 'bag', stock: 96,
    vendor: 'IFFCO Depot',
  },
  {
    key: 'neem-oil-1l',
    en: 'Neem oil concentrate',
    bn: 'নিম তেল কনসেনট্রেট',
    hi: 'नीम तेल सांद्र',
    descriptionEn: 'Organic pest control, 1 litre.',
    descriptionBn: 'জৈব কীটনাশক, ১ লিটার।',
    category: 'fertilizers', price: 480, unit: 'litre', stock: 54,
    vendor: 'Green Earth Organics',
  },
  {
    key: 'vermicompost-25kg',
    en: 'Vermicompost',
    bn: 'কেঁচো সার',
    hi: 'वर्मी कम्पोस्ट',
    descriptionEn: 'Organic soil conditioner, 25 kg bag.',
    descriptionBn: 'জৈব মাটির উপকরণ, ২৫ কেজি ব্যাগ।',
    category: 'fertilizers', price: 390, unit: 'bag', stock: 140,
    vendor: 'Green Earth Organics',
  },
  {
    key: 'knapsack-sprayer-16l',
    en: 'Knapsack sprayer 16 L',
    bn: 'ন্যাপস্যাক স্প্রেয়ার ১৬ লিটার',
    hi: 'नैपसैक स्प्रेयर 16 लीटर',
    descriptionEn: 'Manual lever sprayer with brass nozzle.',
    descriptionBn: 'পিতলের নজলসহ হাতে চালানো স্প্রেয়ার।',
    category: 'tools', price: 1690, unit: 'piece', stock: 23,
    vendor: 'Ranaghat Farm Tools',
  },
  {
    key: 'sickle-forged',
    en: 'Forged harvesting sickle',
    bn: 'কামারের তৈরি কাস্তে',
    hi: 'लोहार का हंसिया',
    descriptionEn: 'Hand-forged carbon steel blade, wooden handle.',
    descriptionBn: 'হাতে তৈরি কার্বন স্টিলের ফলা, কাঠের হাতল।',
    category: 'tools', price: 240, unit: 'piece', stock: 87,
    vendor: 'Ranaghat Farm Tools',
  },
  {
    key: 'drip-lateral-100m',
    en: 'Drip lateral pipe 100 m',
    bn: 'ড্রিপ ল্যাটারাল পাইপ ১০০ মিটার',
    hi: 'ड्रिप लेटरल पाइप 100 मीटर',
    descriptionEn: '16 mm inline dripper pipe, 30 cm spacing.',
    descriptionBn: '১৬ মিমি ইনলাইন ড্রিপার পাইপ, ৩০ সেমি ব্যবধান।',
    category: 'tools', price: 2350, unit: 'piece', stock: 11,
    vendor: 'Jain Irrigation Dealer',
  },
  {
    key: 'discontinued-hybrid-maize',
    en: 'Hybrid maize seed (discontinued)',
    bn: 'হাইব্রিড ভুট্টার বীজ (বন্ধ)',
    hi: 'हाइब्रिड मक्का बीज (बंद)',
    descriptionEn: 'Delisted line, retained for order history.',
    descriptionBn: 'তালিকা থেকে সরানো, অর্ডার ইতিহাসের জন্য রাখা।',
    category: 'seeds', price: 690, unit: 'bag', stock: 0,
    vendor: 'Pusa Krishi Kendra',
  },
];

function buildMarketProducts(): MarketProductDocument[] {
  return productCatalogue.map((product, index) => {
    const createdAt = daysFromNow(-integer(randomFor(`product:${index}`), 30, 200), 10);
    return {
      _id: `seed-product-${product.key}`,
      name: { en: product.en, bn: product.bn, hi: product.hi },
      description: { en: product.descriptionEn, bn: product.descriptionBn },
      category: product.category,
      price: product.price,
      unit: product.unit,
      stockQuantity: product.stock,
      vendor: product.vendor,
      // The last entry is delisted on purpose: it must stay out of the farmer
      // catalogue while remaining visible to an admin.
      isActive: product.key !== 'discontinued-hybrid-maize',
      createdAt,
      updatedAt: createdAt,
    } as MarketProductDocument;
  });
}

/**
 * Fourteen days of quotes per market and commodity. The upstream feed only
 * ever publishes the current day, so a seeded history is the only way the
 * stored series — and any trend built on it — has more than one point.
 */
function buildMandiPrices(): MandiPriceDocument[] {
  const rows: MandiPriceDocument[] = [];
  const markets = places.slice(0, 5);
  // Today's rows for one market are admin-entered, so the app has a real
  // example of an operator-owned row that a feed refresh must not overwrite.
  // It has to be a market that is actually seeded, or the case never appears.
  const manualMarket = markets[2]!.market;
  const commodities = [
    { commodity: 'Rice', variety: 'Swarna', base: 2300 },
    { commodity: 'Potato', variety: 'Jyoti', base: 1150 },
    { commodity: 'Mustard', variety: null, base: 5600 },
    { commodity: 'Onion', variety: 'Nasik Red', base: 1800 },
  ] as const;

  for (const place of markets) {
    for (const entry of commodities) {
      for (let daysAgo = 13; daysAgo >= 0; daysAgo -= 1) {
        const random = randomFor(
          `mandi:${place.market}:${entry.commodity}:${daysAgo}`,
        );
        // A slow drift plus daily noise, so a chart of the series looks like a
        // market rather than a random walk.
        const drift = 1 + (13 - daysAgo) * 0.004;
        const modalPrice = Math.round(
          entry.base * drift * (0.96 + random() * 0.08),
        );
        const spread = Math.round(modalPrice * (0.04 + random() * 0.05));
        const quote = {
          state: place.state,
          district: place.district,
          market: place.market,
          commodity: entry.commodity,
          variety: entry.variety,
          grade: 'FAQ',
          arrivalDate: utcMidnight(daysAgo),
          minPrice: modalPrice - spread,
          maxPrice: modalPrice + spread,
          modalPrice,
        };
        rows.push({
          _id: mandiRecordId(quote),
          seriesKey: mandiSeriesKey(quote),
          ...quote,
          source:
            daysAgo === 0 && place.market === manualMarket
              ? 'manual'
              : 'agmarknet',
          recordedAt: new Date(quote.arrivalDate.getTime() + 6 * 60 * 60 * 1000),
        } as MandiPriceDocument);
      }
    }
  }
  return rows;
}

function buildBroadcasts(
  users: UserDocument[],
  reachableCount: number,
  admin: { id: string; email: string },
): {
  broadcasts: BroadcastDocument[];
  broadcastReceipts: BroadcastReceiptDocument[];
} {
  const drafts = [
    {
      key: 'monsoon-advisory',
      title: 'Heavy rain expected in Nadia',
      body: 'Delay irrigation for the next two days and check field drainage.',
      category: 'weather',
      deepLink: 'krishisech://weather',
      audience: { language: 'bn', state: 'West Bengal', farmerType: null, onlyActive: true },
      status: 'sent',
      daysAgo: 2,
    },
    {
      key: 'mandi-price-alert',
      title: 'Potato prices up 8% at Bardhaman',
      body: 'Modal price reached ₹1,240 per quintal this morning.',
      category: 'market',
      deepLink: 'krishisech://market',
      audience: { language: null, state: 'West Bengal', farmerType: null, onlyActive: true },
      status: 'sent',
      daysAgo: 6,
    },
    {
      key: 'pest-advisory',
      title: 'Brown planthopper watch',
      body: 'Inspect the base of paddy stems this week and report damage early.',
      category: 'advisory',
      deepLink: null,
      audience: { language: null, state: null, farmerType: null, onlyActive: true },
      status: 'sent',
      daysAgo: 12,
    },
    {
      key: 'maintenance-window',
      title: 'Scheduled maintenance on Sunday',
      body: 'The app may be briefly unavailable between 1 AM and 3 AM.',
      category: 'maintenance',
      deepLink: null,
      audience: { language: null, state: null, farmerType: null, onlyActive: true },
      status: 'scheduled',
      daysAgo: -3,
    },
    {
      key: 'rabi-sowing-draft',
      title: 'Rabi sowing window opens',
      body: 'Prepare seedbeds now for wheat and mustard sowing.',
      category: 'advisory',
      deepLink: null,
      audience: { language: 'hi', state: 'Bihar', farmerType: null, onlyActive: true },
      status: 'draft',
      daysAgo: 0,
    },
  ] as const;

  const broadcasts: BroadcastDocument[] = [];
  const broadcastReceipts: BroadcastReceiptDocument[] = [];

  for (const draft of drafts) {
    const id = `seed-broadcast-${draft.key}`;
    const sent = draft.status === 'sent';
    const at = daysFromNow(-draft.daysAgo, 4);
    // Delivery is never perfect: a fraction of registered devices fail, which
    // is what makes deliveredCount < audienceCount the normal case.
    const failed = sent ? Math.max(0, Math.round(reachableCount * 0.08)) : 0;

    broadcasts.push({
      _id: id,
      title: draft.title,
      body: draft.body,
      category: draft.category,
      deepLink: draft.deepLink,
      audience: draft.audience,
      status: draft.status,
      createdByAdminId: admin.id,
      createdByAdminEmail: admin.email,
      scheduledAt: draft.status === 'scheduled' ? at : null,
      sentAt: sent ? at : null,
      audienceCount: sent ? reachableCount : 0,
      deliveredCount: sent ? reachableCount - failed : 0,
      failedCount: failed,
      failureReason: null,
      createdAt: at,
      updatedAt: at,
    } as BroadcastDocument);

    // Roughly half the recipients have opened each sent broadcast, so the
    // inbox shows both read and unread without any of them being empty.
    if (!sent) continue;
    users.forEach((user, index) => {
      if (!user.isActive || index % 2 === 1) return;
      broadcastReceipts.push({
        _id: seedUuid(`receipt:${draft.key}:${user._id}`),
        broadcastId: id,
        userId: user._id,
        readAt: new Date(at.getTime() + 3 * 60 * 60 * 1000),
      });
    });
  }

  return { broadcasts, broadcastReceipts };
}

// ---------------------------------------------------------------------------
// Writing
// ---------------------------------------------------------------------------

interface WritableModel {
  bulkWrite(operations: unknown[]): Promise<unknown>;
  deleteMany(filter: Record<string, unknown>): Promise<{ deletedCount?: number }>;
}

async function upsertAll(
  model: unknown,
  documents: { _id: string }[],
): Promise<number> {
  if (documents.length === 0) return 0;
  // replaceOne rather than insertOne: a second run must refresh the same rows
  // instead of failing on duplicate ids.
  await (model as WritableModel).bulkWrite(
    documents.map((document) => ({
      replaceOne: { filter: { _id: document._id }, replacement: document, upsert: true },
    })),
  );
  return documents.length;
}

async function deleteAll(
  model: unknown,
  documents: { _id: string }[],
): Promise<number> {
  if (documents.length === 0) return 0;
  const result = await (model as WritableModel).deleteMany({
    _id: { $in: documents.map((document) => document._id) },
  });
  return result.deletedCount ?? 0;
}

/**
 * Anything owned by a seeded farmer, including rows a developer created while
 * signed in as one. `--reset` clears these before re-seeding so a run always
 * lands on a known state; a plain run leaves them alone.
 */
async function deleteOwnedByUsers(
  database: MongoDatabase,
  userIds: string[],
): Promise<number> {
  const filter = { userId: { $in: userIds } };
  const results = await Promise.all([
    database.crops.deleteMany(filter),
    database.calendarTasks.deleteMany(filter),
    database.farmProfiles.deleteMany(filter),
    database.irrigationRecommendations.deleteMany(filter),
    database.fertilizerRecommendations.deleteMany(filter),
    database.devices.deleteMany(filter),
    database.broadcastReceipts.deleteMany(filter),
  ]);
  return results.reduce((total, result) => total + (result.deletedCount ?? 0), 0);
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function buildAll(
  farmerCount: number,
  admin: { id: string; email: string },
): SeedData {
  const farmers = buildFarmers(farmerCount);
  const reachable = farmers.devices.filter((device) =>
    farmers.users.some((user) => user._id === device.userId && user.isActive),
  ).length;
  const { broadcasts, broadcastReceipts } = buildBroadcasts(
    farmers.users,
    reachable,
    admin,
  );
  return {
    ...farmers,
    marketProducts: buildMarketProducts(),
    mandiPrices: buildMandiPrices(),
    broadcasts,
    broadcastReceipts,
  };
}

/** Collection label paired with its documents, in write order. */
function describe(data: SeedData): [string, { _id: string }[]][] {
  return [
    ['users', data.users],
    ['farm profiles', data.farmProfiles],
    ['crops', data.crops],
    ['calendar tasks', data.calendarTasks],
    ['irrigation recommendations', data.irrigationRecommendations],
    ['fertilizer recommendations', data.fertilizerRecommendations],
    ['devices', data.devices],
    ['market products', data.marketProducts],
    ['mandi prices', data.mandiPrices],
    ['broadcasts', data.broadcasts],
    ['broadcast receipts', data.broadcastReceipts],
  ];
}

interface Options {
  farmers: number;
  reset: boolean;
  clean: boolean;
  dryRun: boolean;
}

function parseOptions(argv: string[]): Options {
  const options: Options = { farmers: 8, reset: false, clean: false, dryRun: false };
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]!;
    if (token === '--reset') options.reset = true;
    else if (token === '--clean') options.clean = true;
    else if (token === '--dry-run') options.dryRun = true;
    else if (token.startsWith('--farmers')) {
      const [, inline] = token.split('=');
      const value = Number.parseInt(inline ?? argv[++index] ?? '', 10);
      if (Number.isFinite(value) && value > 0) options.farmers = Math.min(value, 200);
    }
  }
  return options;
}

async function main(): Promise<void> {
  const options = parseOptions(process.argv.slice(2));
  const config = loadAppConfig();

  // Mock farmers in a production database would corrupt every metric the
  // admin panel reports, and there is no way to tell them apart afterwards.
  if (config.appEnv === 'production') {
    console.error('Refusing to seed: APP_ENV is production.');
    process.exitCode = 1;
    return;
  }

  // Built before connecting, so `--dry-run` can prove the generator works
  // against a machine with no database at all.
  const placeholderAdmin = { id: 'seed-admin', email: 'seed@krishisech.local' };
  const preview = buildAll(options.farmers, placeholderAdmin);

  if (options.dryRun) {
    console.log(`Dry run — ${options.farmers} farmer(s), nothing written.`);
    for (const [label, documents] of describe(preview)) {
      console.log(`  ${String(documents.length).padStart(5)}  ${label}`);
    }
    const [firstUser] = preview.users;
    const [firstCrop] = preview.crops;
    console.log('');
    console.log('Sample farmer:', JSON.stringify(firstUser, null, 2));
    console.log('Sample crop:  ', JSON.stringify(firstCrop, null, 2));
    return;
  }

  const uri = process.env.MONGODB_URI?.trim();
  if (!uri) {
    console.error('MONGODB_URI is required to seed the database.');
    process.exitCode = 1;
    return;
  }

  const database = new MongoDatabase(uri, process.env.MONGODB_DB_NAME);
  try {
    await database.ping();

    // Broadcasts record who sent them. Reuse a real admin when one exists so
    // the panel shows a familiar address instead of a fabricated one.
    const existingAdmin = await database.adminUsers.findOne().lean();
    const data = existingAdmin
      ? buildAll(options.farmers, {
          id: existingAdmin._id,
          email: existingAdmin.email,
        })
      : preview;

    // Keyed off `describe` so a collection can never be built and then
    // silently left unwritten.
    const models: Record<string, unknown> = {
      users: database.users,
      'farm profiles': database.farmProfiles,
      crops: database.crops,
      'calendar tasks': database.calendarTasks,
      'irrigation recommendations': database.irrigationRecommendations,
      'fertilizer recommendations': database.fertilizerRecommendations,
      devices: database.devices,
      'market products': database.marketProducts,
      'mandi prices': database.mandiPrices,
      broadcasts: database.broadcasts,
      'broadcast receipts': database.broadcastReceipts,
    };
    const collections = describe(data).map(([label, documents]) => {
      const model = models[label];
      if (!model) throw new Error(`No model registered for "${label}"`);
      return [label, model, documents] as const;
    });

    if (options.clean || options.reset) {
      const userIds = data.users.map((user) => user._id);
      let removed = await deleteOwnedByUsers(database, userIds);
      for (const [, model, documents] of collections) {
        removed += await deleteAll(model, documents);
      }
      console.log(`Removed ${removed} seeded document(s).`);
      if (options.clean) {
        console.log('Clean complete. Nothing was written.');
        return;
      }
    }

    console.log(`Seeding ${options.farmers} farmer(s) into ${config.appEnv}…`);
    for (const [label, model, documents] of collections) {
      const count = await upsertAll(model, documents);
      console.log(`  ${String(count).padStart(5)}  ${label}`);
    }

    const [first] = data.users;
    console.log('');
    console.log('Done. Sign in from the app with any seeded number:');
    console.log(`  phone  ${first?.phone ?? '+919800000001'}`);
    console.log('  otp    read it from the send-otp response (DEBUG_OTP_ENABLED)');
    console.log('');
    console.log('Not seeded, on purpose:');
    console.log('  admin accounts   run `npm run admin:create`');
    console.log('  sessions, OTPs   auth state should never be faked');
    console.log('  audit log        it records what admins actually did');
    console.log('');
    console.log('Re-run any time — ids are deterministic, so rows are replaced,');
    console.log('not duplicated. `--clean` removes everything this script wrote.');
  } finally {
    await database.close();
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
