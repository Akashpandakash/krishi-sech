import { randomUUID } from 'node:crypto';

import type { AiVisionProvider } from '../providers/ai-completion-provider.js';
import type { AiContextService } from './ai-context-service.js';

export class AiDiseaseScanService {
  constructor(
    private readonly contextService: AiContextService,
    private readonly visionProvider: AiVisionProvider,
  ) {}

  async scan(
    userId: string,
    image: { buffer: Buffer; mimetype: string },
    language: 'bn' | 'en' | 'hi',
  ) {
    const totalStarted = performance.now();
    const contextStarted = performance.now();
    let context: Awaited<ReturnType<AiContextService['getContext']>> | null;
    try {
      context = await this.contextService.getContext(userId);
      this.developmentLog(
        `✓ step=6 AI context built durationMs=${this.elapsed(contextStarted)}`,
      );
    } catch (error) {
      context = null;
      this.developmentLog(
        `✓ step=6 AI context built source=safe_fallback durationMs=${this.elapsed(contextStarted)} contextStoreError=${this.reason(error)}`,
      );
    }
    let diagnosis;
    try {
      diagnosis = await this.visionProvider.analyzeCropImage({
      image: image.buffer,
      mimeType: image.mimetype,
      language,
      context: {
        contextAvailable: context != null,
        location: context?.location
          ? {
              city: context.location.city,
              district: context.location.district,
              state: context.location.state,
            }
          : null,
        crops: (context?.crops ?? []).map((crop) => ({
          cropName: crop.cropName,
          variety: crop.variety,
          growthStage: crop.growthStage,
          healthStatus: crop.healthStatus,
        })),
        currentCrop: context?.currentCrop
          ? {
              cropName: context.currentCrop.cropName,
              variety: context.currentCrop.variety,
              growthStage: context.currentCrop.growthStage,
              healthStatus: context.currentCrop.healthStatus,
            }
          : null,
        currentWeather: context?.currentWeather ?? null,
        recentDiseaseHistory: (context?.recentDiseaseScans ?? []).slice(0, 3).map((scan) => ({
          possibleDisease: scan.possibleDisease,
          severity: scan.severity,
          createdAt: scan.createdAt,
        })),
      },
      });
    } catch (error) {
      this.developmentLog(
        `✗ step=9 diagnosis unavailable totalProcessingMs=${this.elapsed(totalStarted)} reason=${this.reason(error)}`,
      );
      throw error;
    }
    this.developmentLog(
      `✓ step=9 structured diagnosis ready totalProcessingMs=${this.elapsed(totalStarted)}`,
    );
    return { scanId: randomUUID(), ...diagnosis, createdAt: new Date() };
  }

  private elapsed(started: number) {
    return Math.round(performance.now() - started);
  }

  private reason(error: unknown) {
    return error instanceof Error
      ? error.message.split('\n').find((line) => line.trim().length > 0)?.trim() ?? error.name
      : 'unknown';
  }

  private developmentLog(message: string) {
    if (
      process.env.LOGGING_ENABLED === 'true' &&
      process.env.NODE_ENV !== 'test'
    ) {
      console.log(`[AI Vision] ${message}`);
    }
  }
}
