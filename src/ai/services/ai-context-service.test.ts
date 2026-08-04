import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import type {
  AuthOtp,
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
} from '../../auth/repositories/auth-repository.js';
import type {
  CropInput,
  CropRecord,
  CropRepository,
} from '../../crops/repositories/crop-repository.js';
import type {
  AiContextRepository,
  AiLocationContext,
} from '../repositories/ai-context-repository.js';
import { AiContextService } from './ai-context-service.js';
import type {
  AiCompletionMessage,
  AiCompletionProvider,
} from '../providers/ai-completion-provider.js';
import { AiChatService } from './ai-chat-service.js';
import type {
  AiVisionDiagnosis,
  AiVisionProvider,
} from '../providers/ai-completion-provider.js';
import { AiDiseaseScanService } from './ai-disease-scan-service.js';

const user: AuthUser = {
  id: 'user-1',
  phone: '+919876543210',
  name: 'Amit',
  preferredLanguage: 'hi',
  isActive: true,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

class ContextAuthRepository implements AuthRepository {
  async findUserById(id: string) {
    return id === user.id ? user : null;
  }
  async createOtp(_phone: string, _hash: string, _expires: Date) {}
  async countOtpRequests(_phone: string, _since: Date) { return 0; }
  async findLatestOtp(_phone: string): Promise<AuthOtp | null> { return null; }
  async incrementOtpAttempts(_id: string) {}
  async consumeOtp(_id: string) {}
  async findUserByPhone(_phone: string): Promise<AuthUser | null> { return null; }
  async createUser(_phone: string): Promise<AuthUser> { return user; }
  async ensureDemoUser(_phone: string): Promise<AuthUser> { return user; }
  async createRefreshToken(_userId: string, _hash: string, _expires: Date) {}
  async findRefreshToken(_hash: string): Promise<AuthRefreshToken | null> { return null; }
  async rotateRefreshToken(_id: string, _userId: string, _hash: string, _expires: Date) {}
  async revokeRefreshToken(_id: string) {}
}

class ContextCropRepository implements CropRepository {
  constructor(readonly crops: CropRecord[]) {}
  async findAllByUser(userId: string) {
    return this.crops.filter((crop) => crop.userId === userId);
  }
  async create(_userId: string, _input: CropInput): Promise<CropRecord> { throw new Error('unused'); }
  async findByIdAndUser(_id: string, _userId: string): Promise<CropRecord | null> { return null; }
  async update(_id: string, _userId: string, _input: CropInput): Promise<CropRecord> { throw new Error('unused'); }
  async delete(_id: string, _userId: string) {}
}

class ContextSources implements AiContextRepository {
  async findLocation(_userId: string): Promise<AiLocationContext> {
    return { city: 'Kolkata', district: 'Kolkata', state: 'West Bengal', country: 'India', latitude: 22.57, longitude: 88.36 };
  }
  async findCurrentWeather(_userId: string) {
    return { temperatureCelsius: 31, condition: 'Cloudy', humidityPercent: 78, windSpeedKmh: 9, rainProbabilityPercent: 60, updatedAt: new Date('2026-08-03T08:00:00Z') };
  }
  async findUpcomingTasks(_userId: string) {
    return [{ id: 'task-1', cropId: 'crop-2', title: 'Irrigate', taskType: 'irrigation', dueAt: new Date('2026-08-04') }];
  }
  async findLastIrrigation(_userId: string) {
    return { cropId: 'crop-2', occurredAt: new Date('2026-08-01'), details: 'Drip irrigation' };
  }
  async findLastFertilizer(_userId: string) { return null; }
  async findRecentDiseaseScans(_userId: string) {
    return [{ scanId: 'scan-1', cropId: 'crop-2', possibleDisease: 'Leaf spot', confidence: 0.82, severity: 'medium', createdAt: new Date('2026-08-02') }];
  }
}

function crop(id: string, stage: CropRecord['growthStage'], updatedAt: string): CropRecord {
  return {
    id,
    userId: user.id,
    cropName: id === 'crop-1' ? 'Wheat' : 'Paddy',
    variety: 'Local',
    sowingDate: new Date('2026-06-01'),
    growthStage: stage,
    landArea: 1,
    landUnit: 'acre',
    soilType: 'alluvial',
    irrigationMethod: 'flood',
    expectedHarvestDate: null,
    healthStatus: id === 'crop-2' ? 'moderate' : 'healthy',
    notes: null,
    createdAt: new Date('2026-06-01'),
    updatedAt: new Date(updatedAt),
  };
}

describe('AI context service', () => {
  it('aggregates structured context and selects the latest active crop', async () => {
    const service = new AiContextService(
      new ContextAuthRepository(),
      new ContextCropRepository([
        crop('crop-1', 'harvested', '2026-08-03'),
        crop('crop-2', 'vegetative', '2026-08-02'),
      ]),
      new ContextSources(),
    );

    const context = await service.getContext(user.id);
    assert.equal(context.user.preferredLanguage, 'hi');
    assert.equal(context.location?.city, 'Kolkata');
    assert.equal(context.crops.length, 2);
    assert.equal(context.currentCrop?.id, 'crop-2');
    assert.equal(context.growthStage, 'vegetative');
    assert.equal(context.cropHealth, 'moderate');
    assert.equal(context.upcomingTasks.length, 1);
    assert.equal(context.recentDiseaseScans.length, 1);
  });

  it('returns null and empty context safely when no crop or feature data exists', async () => {
    const emptySources: AiContextRepository = {
      findLocation: async () => null,
      findCurrentWeather: async () => null,
      findUpcomingTasks: async () => [],
      findLastIrrigation: async () => null,
      findLastFertilizer: async () => null,
      findRecentDiseaseScans: async () => [],
    };
    const service = new AiContextService(
      new ContextAuthRepository(),
      new ContextCropRepository([]),
      emptySources,
    );
    const context = await service.getContext(user.id);
    assert.equal(context.currentCrop, null);
    assert.equal(context.growthStage, null);
    assert.deepEqual(context.upcomingTasks, []);
  });
});

class CapturingCompletionProvider implements AiCompletionProvider {
  messages: AiCompletionMessage[] = [];

  async complete(messages: AiCompletionMessage[]) {
    this.messages = messages;
    return { text: 'আজ সেচ স্থগিত রাখুন।', model: 'test-model', usage: null };
  }
}

describe('AI chat service', () => {
  it('uses complete farming context without identity or exact location', async () => {
    const contextService = new AiContextService(
      new ContextAuthRepository(),
      new ContextCropRepository([crop('crop-2', 'vegetative', '2026-08-02')]),
      new ContextSources(),
    );
    const provider = new CapturingCompletionProvider();
    const service = new AiChatService(contextService, provider);

    const result = await service.chat(user.id, {
      message: 'আজ কি সেচ দেব?',
      language: 'bn',
      history: [],
    });

    assert.equal(result.reply, 'আজ সেচ স্থগিত রাখুন।');
    const prompt = provider.messages[0].content;
    assert.match(prompt, /Bangla/);
    assert.match(prompt, /Kolkata/);
    assert.match(prompt, /Paddy/);
    assert.match(prompt, /cropList/);
    assert.match(prompt, /growthStage/);
    assert.match(prompt, /cropCalendar/);
    assert.match(prompt, /irrigationHistory/);
    assert.match(prompt, /fertilizerHistory/);
    assert.match(prompt, /diseaseHistory/);
    assert.match(prompt, /Leaf spot/);
    assert.doesNotMatch(prompt, /user-1/);
    assert.doesNotMatch(prompt, /\+919876543210/);
    assert.doesNotMatch(prompt, /Amit/);
    assert.doesNotMatch(prompt, /22\.57|88\.36/);
    assert.doesNotMatch(prompt, /scan-1/);
  });

  it('instructs greeting, irrigation, and minimum follow-up behavior', async () => {
    const contextService = new AiContextService(
      new ContextAuthRepository(),
      new ContextCropRepository([crop('crop-2', 'vegetative', '2026-08-02')]),
      new ContextSources(),
    );
    const provider = new CapturingCompletionProvider();
    const service = new AiChatService(contextService, provider);

    await service.chat(user.id, {
      message: 'Hello',
      language: 'en',
      history: [],
    });
    const greetingPrompt = provider.messages[0].content;
    assert.match(greetingPrompt, /For greetings/);
    assert.match(greetingPrompt, /current crop or current weather/);
    assert.equal(provider.messages.at(-1)?.content, 'Hello');

    await service.chat(user.id, {
      message: 'আজ কি সেচ দেব?',
      language: 'bn',
      history: [],
    });
    const irrigationPrompt = provider.messages[0].content;
    assert.match(irrigationPrompt, /evaluate current weather, current crop, growth stage, crop calendar, and last irrigation/);
    assert.match(irrigationPrompt, /ask exactly one minimum follow-up question/);
    assert.match(irrigationPrompt, /Never give a generic chatbot answer/);
    assert.equal(provider.messages.at(-1)?.content, 'আজ কি সেচ দেব?');
  });
});

class CapturingVisionProvider implements AiVisionProvider {
  context: object | null = null;
  language: string | null = null;

  async analyzeCropImage(input: {
    image: Buffer;
    mimeType: string;
    language: 'bn' | 'en' | 'hi';
    context: object;
  }): Promise<AiVisionDiagnosis> {
    this.context = input.context;
    this.language = input.language;
    return {
      crop: 'Paddy',
      disease: 'Leaf spot',
      confidence: 0.82,
      severity: 'medium',
      symptoms: ['Brown leaf spots'],
      treatment: ['Remove badly affected leaves'],
      medicine: ['Use a locally registered fungicide if advised'],
      organicAlternative: ['Apply neem-based treatment'],
      prevention: ['Avoid prolonged leaf wetness'],
      expertConsultationRecommended: false,
    };
  }
}

describe('AI crop disease service', () => {
  it('uses AI context without identity or exact coordinates', async () => {
    const contextService = new AiContextService(
      new ContextAuthRepository(),
      new ContextCropRepository([crop('crop-2', 'vegetative', '2026-08-02')]),
      new ContextSources(),
    );
    const provider = new CapturingVisionProvider();
    const service = new AiDiseaseScanService(contextService, provider);

    const result = await service.scan(
      user.id,
      { buffer: Buffer.from('image'), mimetype: 'image/jpeg' },
      'bn',
    );

    assert.equal(result.crop, 'Paddy');
    assert.equal(result.disease, 'Leaf spot');
    assert.equal(provider.language, 'bn');
    const serialized = JSON.stringify(provider.context);
    assert.match(serialized, /Kolkata|Paddy|vegetative|Leaf spot/);
    assert.doesNotMatch(serialized, /user-1|Amit|\+919876543210|22\.57|88\.36/);
  });
});
