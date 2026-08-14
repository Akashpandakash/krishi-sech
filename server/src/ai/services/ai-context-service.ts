import { AppError } from '../../common/app-error.js';
import type { AuthRepository } from '../../auth/repositories/auth-repository.js';
import type {
  CropRecord,
  CropRepository,
} from '../../crops/repositories/crop-repository.js';
import type { AiContextRepository } from '../repositories/ai-context-repository.js';

export class AiContextService {
  constructor(
    private readonly authRepository: AuthRepository,
    private readonly cropRepository: CropRepository,
    private readonly contextRepository: AiContextRepository,
  ) {}

  async getContext(userId: string) {
    const [user, crops, location, weather, tasks, irrigation, fertilizer, scans] =
      await Promise.all([
        this.authRepository.findUserById(userId),
        this.cropRepository.findAllByUser(userId),
        this.contextRepository.findLocation(userId),
        this.contextRepository.findCurrentWeather(userId),
        this.contextRepository.findUpcomingTasks(userId),
        this.contextRepository.findLastIrrigation(userId),
        this.contextRepository.findLastFertilizer(userId),
        this.contextRepository.findRecentDiseaseScans(userId),
      ]);
    if (!user?.isActive) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    }

    const currentCrop = this.selectCurrentCrop(crops);
    return {
      user: {
        id: user.id,
        name: user.name,
        preferredLanguage: user.preferredLanguage,
      },
      location,
      currentWeather: weather,
      crops,
      currentCrop,
      growthStage: currentCrop?.growthStage ?? null,
      cropHealth: currentCrop?.healthStatus ?? null,
      upcomingTasks: tasks,
      lastIrrigation: irrigation,
      lastFertilizer: fertilizer,
      recentDiseaseScans: scans,
      generatedAt: new Date(),
    };
  }

  private selectCurrentCrop(crops: CropRecord[]): CropRecord | null {
    const candidates = crops.filter((crop) => crop.growthStage !== 'harvested');
    const source = candidates.length > 0 ? candidates : crops;
    return [...source].sort(
      (left, right) => right.updatedAt.getTime() - left.updatedAt.getTime(),
    )[0] ?? null;
  }
}
