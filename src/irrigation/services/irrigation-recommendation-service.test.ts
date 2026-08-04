import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { AiContextService } from '../../ai/services/ai-context-service.js';
import type { CropRecord, CropRepository } from '../../crops/repositories/crop-repository.js';
import { RuleBasedIrrigationRecommendationProvider } from '../providers/rule-based-irrigation-recommendation-provider.js';
import type { IrrigationRecommendationRecord, IrrigationRecommendationRepository } from '../repositories/irrigation-recommendation-repository.js';
import { IrrigationRecommendationService } from './irrigation-recommendation-service.js';

const crop: CropRecord = {
  id: 'be34fcf5-bb42-4df1-8a53-02d04f1510cb', userId: 'user-1',
  cropName: 'Paddy', variety: 'Swarna', sowingDate: new Date('2026-06-01'),
  growthStage: 'vegetative', landArea: 2, landUnit: 'acre', soilType: 'sandy',
  irrigationMethod: 'flood', expectedHarvestDate: new Date('2026-10-01'),
  healthStatus: 'healthy', notes: null, createdAt: new Date('2026-06-01'),
  updatedAt: new Date('2026-08-01'),
};

class MemoryHistory implements IrrigationRecommendationRepository {
  records: IrrigationRecommendationRecord[] = [];
  async save(input: IrrigationRecommendationRecord) { this.records.push(input); return input; }
  async findByUserAndCrop(userId: string, cropId: string) {
    return this.records.filter((item) => item.userId === userId && item.cropId === cropId);
  }
}

function fixture(options: { rain?: number; lastIrrigation?: Date } = {}) {
  const history = new MemoryHistory();
  const cropRepository = {
    findByIdAndUser: async (id: string, userId: string) => id === crop.id && userId === crop.userId ? crop : null,
  } as CropRepository;
  const contextService = {
    getContext: async () => ({
      currentCrop: crop,
      currentWeather: {
        temperatureCelsius: 36, condition: 'Hot', humidityPercent: 45,
        windSpeedKmh: 8, rainProbabilityPercent: options.rain ?? 20,
        updatedAt: new Date(),
      },
      lastIrrigation: options.lastIrrigation ? {
        cropId: crop.id, occurredAt: options.lastIrrigation, details: 'Flood irrigation',
      } : null,
    }),
  } as unknown as AiContextService;
  return {
    history,
    service: new IrrigationRecommendationService(
      cropRepository, contextService,
      new RuleBasedIrrigationRecommendationProvider(), history,
    ),
  };
}

describe('rule-based irrigation recommendation', () => {
  it('uses crop, stage, soil, weather, history and land type and saves history', async () => {
    const { service, history } = fixture();
    const result = await service.getRecommendation('user-1', crop.id, 'en', 'upland');
    assert.equal(result.irrigationRequired, true);
    assert.ok(result.waterQuantity.value > 100_000);
    assert.equal(result.waterQuantity.unit, 'liters');
    assert.match(result.reasoning, /crop stage/i);
    assert.ok(result.confidence >= 0.8);
    assert.equal(result.engineVersion, 'rules-v1');
    assert.equal(history.records.length, 1);
  });

  it('does not recommend irrigation when significant rain is forecast', async () => {
    const result = await fixture({ rain: 85 }).service
      .getRecommendation('user-1', crop.id, 'en', 'lowland');
    assert.equal(result.irrigationRequired, false);
    assert.equal(result.waterQuantity.value, 0);
    assert.match(result.reasoning, /rain/i);
  });

  it('uses recent irrigation history to avoid duplicate watering', async () => {
    const recent = new Date(Date.now() - 12 * 3_600_000);
    const result = await fixture({ lastIrrigation: recent }).service
      .getRecommendation('user-1', crop.id, 'en');
    assert.equal(result.irrigationRequired, false);
    assert.match(result.reasoning, /recently/i);
  });

  it('localizes Bangla and Hindi reasoning and timing', async () => {
    const bangla = await fixture().service.getRecommendation('user-1', crop.id, 'bn');
    const hindi = await fixture().service.getRecommendation('user-1', crop.id, 'hi');
    assert.match(bangla.reasoning, /ফসলের/);
    assert.match(hindi.bestIrrigationTime, /सुबह/);
  });
});
