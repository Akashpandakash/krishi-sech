import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import type { CropRecord, CropRepository } from '../../crops/repositories/crop-repository.js';
import type { AiContextService } from '../../ai/services/ai-context-service.js';
import { RuleBasedFertilizerRecommendationProvider } from '../providers/rule-based-fertilizer-recommendation-provider.js';
import type { FertilizerRecommendationRecord, FertilizerRecommendationRepository } from '../repositories/fertilizer-recommendation-repository.js';
import { FertilizerRecommendationService } from './fertilizer-recommendation-service.js';

const crop: CropRecord = {
  id: 'be34fcf5-bb42-4df1-8a53-02d04f1510cb',
  userId: 'user-1',
  cropName: 'Paddy',
  variety: 'Swarna',
  sowingDate: new Date('2026-06-01'),
  growthStage: 'vegetative',
  landArea: 2,
  landUnit: 'acre',
  soilType: 'alluvial',
  irrigationMethod: 'flood',
  expectedHarvestDate: new Date('2026-10-01'),
  healthStatus: 'healthy',
  notes: null,
  createdAt: new Date('2026-06-01'),
  updatedAt: new Date('2026-08-01'),
};

class MemoryHistory implements FertilizerRecommendationRepository {
  records: FertilizerRecommendationRecord[] = [];
  async save(input: FertilizerRecommendationRecord) {
    this.records.push(input);
    return input;
  }
  async findByUserAndCrop(userId: string, cropId: string) {
    return this.records.filter((item) => item.userId === userId && item.cropId === cropId);
  }
}

function fixture(options: { rain?: number; lastFertilizer?: Date } = {}) {
  const history = new MemoryHistory();
  const cropRepository = {
    findByIdAndUser: async (id: string, userId: string) => id === crop.id && userId === crop.userId ? crop : null,
  } as CropRepository;
  const activity = options.lastFertilizer ? {
    cropId: crop.id,
    occurredAt: options.lastFertilizer,
    details: 'Urea',
  } : null;
  const contextService = {
    getContext: async () => ({
      currentCrop: crop,
      currentWeather: {
        temperatureCelsius: 29,
        condition: 'Cloudy',
        humidityPercent: 75,
        windSpeedKmh: 7,
        rainProbabilityPercent: options.rain ?? 20,
        updatedAt: new Date(),
      },
      lastFertilizer: activity,
      lastIrrigation: {
        cropId: crop.id,
        occurredAt: new Date(Date.now() - 86_400_000),
        details: 'Flood irrigation',
      },
    }),
  } as unknown as AiContextService;
  return {
    history,
    service: new FertilizerRecommendationService(
      cropRepository,
      contextService,
      new RuleBasedFertilizerRecommendationProvider(),
      history,
    ),
  };
}

describe('rule-based fertilizer recommendation', () => {
  it('uses crop, stage, soil, weather and activity context and saves history', async () => {
    const { service, history } = fixture({ rain: 80 });
    const result = await service.getRecommendation('user-1', crop.id, 'en');

    assert.equal(result.recommendedFertilizer, 'Urea');
    assert.deepEqual(result.quantity, { value: 30, unit: 'kg', per: 'acre' });
    assert.match(result.bestApplicationTime, /rain/i);
    assert.ok(result.confidence >= 0.8 && result.confidence <= 1);
    assert.equal(result.engineVersion, 'rules-v1');
    assert.equal(history.records.length, 1);
  });

  it('localizes Bangla and Hindi recommendation text', async () => {
    const bangla = await fixture().service.getRecommendation('user-1', crop.id, 'bn');
    const hindi = await fixture().service.getRecommendation('user-1', crop.id, 'hi');
    assert.match(bangla.applicationMethod, /শিকড়/);
    assert.match(hindi.applicationMethod, /जड़/);
  });

  it('avoids another dose when fertilizer was applied within 14 days', async () => {
    const recent = new Date(Date.now() - 2 * 86_400_000);
    const result = await fixture({ lastFertilizer: recent }).service
      .getRecommendation('user-1', crop.id, 'en');
    assert.equal(result.quantity.value, 0);
    assert.equal(result.recommendedFertilizer, 'No additional chemical fertilizer');
  });
});
