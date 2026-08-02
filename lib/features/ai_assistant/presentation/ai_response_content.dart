import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/l10n/l10n.dart';

String localizedAiResponse(BuildContext context, AiResponseType type) {
  return switch (type) {
    AiResponseType.greeting => context.l10n.aiResponseGreeting,
    AiResponseType.languageSupport => context.l10n.aiResponseLanguageSupport,
    AiResponseType.cropProblemWheat => context.l10n.aiResponseCropProblemWheat,
    AiResponseType.cropProblemRice => context.l10n.aiResponseCropProblemRice,
    AiResponseType.cropProblemGeneral =>
      context.l10n.aiResponseCropProblemGeneral,
    AiResponseType.irrigationDelayForRain =>
      context.l10n.aiResponseIrrigationRain,
    AiResponseType.irrigationNormal => context.l10n.aiResponseIrrigationNormal,
    AiResponseType.rainExpected => context.l10n.aiResponseRainExpected,
    AiResponseType.weatherNormal => context.l10n.aiResponseWeatherNormal,
    AiResponseType.fertilizer => context.l10n.aiResponseFertilizer,
    AiResponseType.pests => context.l10n.aiResponsePests,
    AiResponseType.yellowLeaves => context.l10n.aiResponseYellowLeaves,
    AiResponseType.cropDisease => context.l10n.aiResponseCropDisease,
    AiResponseType.marketPrice => context.l10n.aiResponseMarketPrice,
    AiResponseType.sowingTime => context.l10n.aiResponseSowingTime,
    AiResponseType.governmentSchemes =>
      context.l10n.aiResponseGovernmentSchemes,
    AiResponseType.agriculturalExpert =>
      context.l10n.aiResponseAgriculturalExpert,
    AiResponseType.general => context.l10n.aiResponseGeneral,
  };
}
