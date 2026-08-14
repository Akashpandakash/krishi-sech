import { randomUUID } from 'node:crypto';
import { AppError } from '../../common/app-error.js';
import type { CropRepository } from '../../crops/repositories/crop-repository.js';
import type { AiContextService } from '../../ai/services/ai-context-service.js';
import type { FertilizerRecommendationProvider, RecommendationLanguage } from '../providers/fertilizer-recommendation-provider.js';
import type { FertilizerRecommendationRepository } from '../repositories/fertilizer-recommendation-repository.js';

export class FertilizerRecommendationService {
  constructor(
    private readonly cropRepository: CropRepository,
    private readonly contextService: AiContextService,
    private readonly provider: FertilizerRecommendationProvider,
    private readonly historyRepository: FertilizerRecommendationRepository,
  ) {}

  async getRecommendation(userId: string, cropId: string | undefined, language: RecommendationLanguage) {
    const context = await this.contextService.getContext(userId);
    const crop = cropId
      ? await this.cropRepository.findByIdAndUser(cropId, userId)
      : context.currentCrop;
    if (!crop) throw new AppError(404, 'CROP_NOT_FOUND', 'Crop not found');

    const fertilizerHistory = context.lastFertilizer ? [context.lastFertilizer] : [];
    const irrigationHistory = context.lastIrrigation ? [context.lastIrrigation] : [];
    const recommendation = this.provider.recommend({
      crop,
      language,
      currentWeather: context.currentWeather,
      lastFertilizer: context.lastFertilizer,
      fertilizerHistory,
      irrigationHistory,
      now: new Date(),
    });
    return this.historyRepository.save({
      id: randomUUID(),
      userId,
      cropId: crop.id,
      language,
      engineVersion: 'rules-v1',
      ...recommendation,
      createdAt: new Date(),
    });
  }
}
