import type { FertilizerRecommendationOutput, RecommendationLanguage } from '../providers/fertilizer-recommendation-provider.js';

export interface FertilizerRecommendationRecord extends FertilizerRecommendationOutput {
  id: string;
  userId: string;
  cropId: string;
  language: RecommendationLanguage;
  engineVersion: string;
  createdAt: Date;
}

export interface FertilizerRecommendationRepository {
  save(input: FertilizerRecommendationRecord): Promise<FertilizerRecommendationRecord>;
  findByUserAndCrop(userId: string, cropId: string): Promise<FertilizerRecommendationRecord[]>;
}
