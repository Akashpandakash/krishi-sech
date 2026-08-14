import type { CropRecord } from '../../crops/repositories/crop-repository.js';
import type { AiActivityContext, AiWeatherContext } from '../../ai/repositories/ai-context-repository.js';

export const recommendationLanguages = ['bn', 'en', 'hi'] as const;
export type RecommendationLanguage = (typeof recommendationLanguages)[number];

export interface FertilizerRecommendationInput {
  crop: CropRecord;
  language: RecommendationLanguage;
  currentWeather: AiWeatherContext | null;
  lastFertilizer: AiActivityContext | null;
  fertilizerHistory: AiActivityContext[];
  irrigationHistory: AiActivityContext[];
  now: Date;
}

export interface FertilizerRecommendationOutput {
  recommendedFertilizer: string;
  quantity: { value: number; unit: 'kg'; per: 'acre' };
  applicationMethod: string;
  bestApplicationTime: string;
  safetyPrecautions: string[];
  organicAlternative: string;
  nextRecommendationDate: Date;
  confidence: number;
}

/** Stable provider boundary: a future AI implementation must honor this contract. */
export interface FertilizerRecommendationProvider {
  recommend(input: FertilizerRecommendationInput): FertilizerRecommendationOutput;
}
