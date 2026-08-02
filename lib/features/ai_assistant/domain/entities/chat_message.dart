enum ChatAuthor { user, assistant }

enum AiResponseType {
  greeting,
  languageSupport,
  cropProblemWheat,
  cropProblemRice,
  cropProblemGeneral,
  irrigationDelayForRain,
  irrigationNormal,
  rainExpected,
  weatherNormal,
  fertilizer,
  pests,
  yellowLeaves,
  cropDisease,
  marketPrice,
  sowingTime,
  governmentSchemes,
  agriculturalExpert,
  general,
}

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.createdAt,
    this.text,
    this.responseType,
  });

  final ChatAuthor author;
  final DateTime createdAt;
  final String? text;
  final AiResponseType? responseType;
}
