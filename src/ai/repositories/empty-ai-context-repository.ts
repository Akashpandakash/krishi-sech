import type {
  AiActivityContext,
  AiContextRepository,
  AiDiseaseScanContext,
  AiLocationContext,
  AiTaskContext,
  AiWeatherContext,
} from './ai-context-repository.js';

/** Safe production adapter until location, task, activity and scan persistence
 * exists in this backend. It never fabricates context. */
export class EmptyAiContextRepository implements AiContextRepository {
  async findLocation(_userId: string): Promise<AiLocationContext | null> {
    return null;
  }

  async findCurrentWeather(_userId: string): Promise<AiWeatherContext | null> {
    return null;
  }

  async findUpcomingTasks(_userId: string): Promise<AiTaskContext[]> {
    return [];
  }

  async findLastIrrigation(
    _userId: string,
  ): Promise<AiActivityContext | null> {
    return null;
  }

  async findLastFertilizer(
    _userId: string,
  ): Promise<AiActivityContext | null> {
    return null;
  }

  async findRecentDiseaseScans(
    _userId: string,
  ): Promise<AiDiseaseScanContext[]> {
    return [];
  }
}
