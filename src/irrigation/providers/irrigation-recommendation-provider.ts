import type { AiActivityContext, AiWeatherContext } from '../../ai/repositories/ai-context-repository.js';
import type { CropRecord } from '../../crops/repositories/crop-repository.js';

export const irrigationLanguages = ['bn', 'en', 'hi'] as const;
export const landTypes = ['upland', 'lowland', 'irrigated', 'rainfed'] as const;
export type IrrigationLanguage = (typeof irrigationLanguages)[number];
export type LandType = (typeof landTypes)[number];

export interface IrrigationRecommendationInput {
  crop: CropRecord;
  language: IrrigationLanguage;
  landType: LandType;
  currentWeather: AiWeatherContext | null;
  rainForecastPercent: number | null;
  irrigationHistory: AiActivityContext[];
  now: Date;
}

export interface IrrigationRecommendationOutput {
  irrigationRequired: boolean;
  waterQuantity: { value: number; unit: 'liters'; per: 'acre' };
  bestIrrigationTime: string;
  irrigationMethod: string;
  nextIrrigationDate: Date;
  confidence: number;
  reasoning: string;
}

/** Stable provider boundary for a future AI-backed implementation. */
export interface IrrigationRecommendationProvider {
  recommend(input: IrrigationRecommendationInput): IrrigationRecommendationOutput;
}
