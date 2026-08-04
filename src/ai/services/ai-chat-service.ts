import type { AiCompletionProvider } from '../providers/ai-completion-provider.js';
import type { AiContextService } from './ai-context-service.js';

export interface AiChatInput {
  message: string;
  language: 'bn' | 'en' | 'hi';
  history: Array<{ role: 'user' | 'assistant'; content: string }>;
}

export class AiChatService {
  constructor(
    private readonly contextService: AiContextService,
    private readonly completionProvider: AiCompletionProvider,
  ) {}

  async chat(userId: string, input: AiChatInput) {
    const context = await this.contextService.getContext(userId);
    const languageName = { bn: 'Bangla', en: 'English', hi: 'Hindi' }[
      input.language
    ];
    const completion = await this.completionProvider.complete([
      {
        role: 'system',
        content: this.systemPrompt(
          languageName,
          this.advisorContext(context, input.language),
        ),
      },
      ...input.history.slice(-10),
      { role: 'user', content: input.message },
    ]);
    return {
      reply: completion.text,
      language: input.language,
      model: completion.model,
      usage: completion.usage,
    };
  }

  private systemPrompt(languageName: string, context: object) {
    return [
      `You are Krishi Sech, a professional smart-farming advisor. Always respond in ${languageName}.`,
      'Before answering, inspect every available field in FARMING_CONTEXT and use all fields relevant to the question.',
      'Never give a generic chatbot answer. Ground advice in the farmer’s crop, growth stage, coarse location, weather, calendar, and farming history whenever available.',
      'Do not mention fields that are absent and never invent current conditions or farming events.',
      'For greetings such as Hi, Hello, or Namaste: greet naturally in the requested language and briefly mention the current crop or current weather when either is available.',
      'For irrigation questions such as “আজ কি সেচ দেব?”: evaluate current weather, current crop, growth stage, crop calendar, and last irrigation before advising. Explain the practical reason briefly.',
      'If a safe answer requires missing information, ask exactly one minimum follow-up question for the most important missing fact. Do not ask for information already present.',
      'For disease concerns, use disease history when available, state uncertainty, and do not claim a diagnosis from text alone.',
      'Return the required structured JSON. Put the farmer-facing response only in answer; list the context field names actually used in context_used; list critical unavailable fields in missing_context; otherwise set follow_up_question to null.',
      `FARMING_CONTEXT=${JSON.stringify(context)}`,
    ].join('\n');
  }

  private advisorContext(
    context: Awaited<ReturnType<AiContextService['getContext']>>,
    language: AiChatInput['language'],
  ) {
    const crop = context.currentCrop;
    return {
      userLanguage: language,
      location: context.location
        ? {
            city: context.location.city,
            district: context.location.district,
            state: context.location.state,
          }
        : null,
      currentWeather: context.currentWeather
        ? {
            temperatureCelsius: context.currentWeather.temperatureCelsius,
            condition: context.currentWeather.condition,
            humidityPercent: context.currentWeather.humidityPercent,
            windSpeedKmh: context.currentWeather.windSpeedKmh,
            rainProbabilityPercent:
              context.currentWeather.rainProbabilityPercent,
          }
        : null,
      cropList: context.crops.map((item) => ({
        cropName: item.cropName,
        variety: item.variety,
        growthStage: item.growthStage,
        healthStatus: item.healthStatus,
      })),
      currentCrop: crop
        ? {
            cropName: crop.cropName,
            variety: crop.variety,
            sowingDate: crop.sowingDate,
            growthStage: crop.growthStage,
            irrigationMethod: crop.irrigationMethod,
            expectedHarvestDate: crop.expectedHarvestDate,
            healthStatus: crop.healthStatus,
          }
        : null,
      growthStage: context.growthStage,
      cropCalendar: context.upcomingTasks.slice(0, 5).map((task) => ({
        taskType: task.taskType,
        dueAt: task.dueAt,
      })),
      irrigationHistory: context.lastIrrigation
        ? { lastIrrigationAt: context.lastIrrigation.occurredAt }
        : null,
      fertilizerHistory: context.lastFertilizer
        ? { lastFertilizerAt: context.lastFertilizer.occurredAt }
        : null,
      diseaseHistory: context.recentDiseaseScans.slice(0, 3).map((scan) => ({
        possibleDisease: scan.possibleDisease,
        confidence: scan.confidence,
        severity: scan.severity,
        observedAt: scan.createdAt,
      })),
    };
  }
}
