import { randomUUID } from 'node:crypto';
import type { AiContextService } from '../../ai/services/ai-context-service.js';
import { AppError } from '../../common/app-error.js';
import type { CropRepository } from '../../crops/repositories/crop-repository.js';
import type { IrrigationLanguage, IrrigationRecommendationProvider, LandType } from '../providers/irrigation-recommendation-provider.js';
import type { IrrigationRecommendationRepository } from '../repositories/irrigation-recommendation-repository.js';

export class IrrigationRecommendationService {
  constructor(
    private readonly cropRepository: CropRepository,
    private readonly contextService: AiContextService,
    private readonly provider: IrrigationRecommendationProvider,
    private readonly historyRepository: IrrigationRecommendationRepository,
  ) {}

  async getRecommendation(userId: string, cropId: string | undefined, language: IrrigationLanguage, requestedLandType?: LandType) {
    const context = await this.contextService.getContext(userId);
    const crop = cropId
      ? await this.cropRepository.findByIdAndUser(cropId, userId)
      : context.currentCrop;
    if (!crop) throw new AppError(404, 'CROP_NOT_FOUND', 'Crop not found');
    const landType = requestedLandType ?? (crop.irrigationMethod === 'rainFed' ? 'rainfed' : 'irrigated');
    const irrigationHistory = context.lastIrrigation ? [context.lastIrrigation] : [];
    const recommendation = this.provider.recommend({
      crop,
      language,
      landType,
      currentWeather: context.currentWeather,
      rainForecastPercent: context.currentWeather?.rainProbabilityPercent ?? null,
      irrigationHistory,
      now: new Date(),
    });
    return this.historyRepository.save({
      id: randomUUID(), userId, cropId: crop.id, language, landType,
      engineVersion: 'rules-v1', ...recommendation, createdAt: new Date(),
    });
  }
}
