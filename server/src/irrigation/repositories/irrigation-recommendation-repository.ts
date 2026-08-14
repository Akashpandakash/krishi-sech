import type { IrrigationLanguage, IrrigationRecommendationOutput, LandType } from '../providers/irrigation-recommendation-provider.js';

export interface IrrigationRecommendationRecord extends IrrigationRecommendationOutput {
  id: string;
  userId: string;
  cropId: string;
  language: IrrigationLanguage;
  landType: LandType;
  engineVersion: string;
  createdAt: Date;
}

export interface IrrigationRecommendationRepository {
  save(input: IrrigationRecommendationRecord): Promise<IrrigationRecommendationRecord>;
  findByUserAndCrop(userId: string, cropId: string): Promise<IrrigationRecommendationRecord[]>;
}
