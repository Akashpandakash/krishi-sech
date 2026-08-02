import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_response_repository.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';

enum FarmingIntent {
  greeting,
  languageQuestion,
  cropProblem,
  irrigation,
  weather,
  fertilizer,
  pest,
  yellowLeaves,
  disease,
  sowingTime,
  marketPrice,
  governmentScheme,
  expertSupport,
  unknown,
}

enum DetectedCrop { wheat, rice, unknown }

class LocalAiResponseRepository implements AiResponseRepository {
  const LocalAiResponseRepository();

  static const _languageKeywords = [
    'bengali',
    'bangla',
    'বাংলা',
    'বাংলা জানো',
    'hindi',
    'हिंदी',
    'language',
    'bhasha',
    'ভাষা',
    'भाषा',
  ];
  static const _greetingKeywords = [
    'hello',
    'hi',
    'hey',
    'namaste',
    'namaskar',
    'হ্যালো',
    'নমস্কার',
    'नमस्ते',
    'नमस्कार',
    'salam',
  ];
  static const _wheatKeywords = [
    'wheat',
    'gom',
    'গম',
    'গমে',
    'गेहूं',
    'गेहूँ',
    'गेहु',
    'gehun',
    'gehu',
  ];
  static const _riceKeywords = [
    'rice',
    'paddy',
    'dhan',
    'ধান',
    'ধানে',
    'চাল',
    'चावल',
    'धान',
    'chawal',
  ];
  static const _problemKeywords = [
    'problem',
    'problems',
    'somossa',
    'shomossha',
    'সমস্যা',
    'issue',
    'issues',
    'samasya',
    'समस्या',
    'dikkat',
    'দুর্বল',
  ];
  static const _irrigationKeywords = [
    'irrigation',
    'irrigate',
    'water',
    'watering',
    'sech',
    'সেচ',
    'pani',
    'পানি',
    'জল',
    'sinchai',
    'सिंचाई',
    'पानी',
  ];
  static const _weatherKeywords = [
    'rain',
    'raining',
    'weather',
    'bristi',
    'বৃষ্টি',
    'আবহাওয়া',
    'barish',
    'barsat',
    'baarish',
    'बारिश',
    'बरसात',
    'mausam',
    'मौसम',
  ];
  static const _fertilizerKeywords = [
    'fertilizer',
    'fertiliser',
    'fertilizers',
    'sar',
    'সার',
    'urea',
    'ইউরিয়া',
    'यूरिया',
    'dap',
    'खाद',
    'urvarak',
    'उर्वरक',
    'khaad',
  ];
  static const _pestKeywords = [
    'pest',
    'pests',
    'insect',
    'insects',
    'poka',
    'পোকা',
    'পোকামাকড়',
    'কীট',
    'keet',
    'कीट',
    'कीड़ा',
    'keeda',
  ];
  static const _yellowLeafKeywords = [
    'yellow leaf',
    'yellow leaves',
    'holud pata',
    'হলুদ পাতা',
    'হলুদ পাতা',
    'peeli patti',
    'pili patti',
    'पीली पत्ती',
    'पीले पत्ते',
  ];
  static const _diseaseKeywords = [
    'disease',
    'fungus',
    'fungal',
    'rog',
    'রোগ',
    'ছত্রাক',
    'बीमारी',
    'रोग',
    'bimari',
    'phaphund',
    'फफूंद',
  ];
  static const _sowingKeywords = [
    'sow',
    'sowing',
    'planting',
    'bopon',
    'বপন',
    'buwai',
    'बुवाई',
    'बोना',
  ];
  static const _marketKeywords = [
    'market',
    'price',
    'mandi',
    'bazar',
    'bazaar',
    'বাজার',
    'দাম',
    'भाव',
    'बाजार',
    'मंडी',
  ];
  static const _schemeKeywords = [
    'scheme',
    'schemes',
    'subsidy',
    'yojana',
    'প্রকল্প',
    'ভর্তুকি',
    'योजना',
    'सब्सिडी',
    'sarkari',
    'सरकारी',
  ];
  static const _expertKeywords = [
    'expert',
    'officer',
    'specialist',
    'bisheshoggo',
    'বিশেষজ্ঞ',
    'কর্মকর্তা',
    'visheshagya',
    'विशेषज्ञ',
    'अधिकारी',
    'agronomist',
    'poison',
    'poisoning',
    'zeher',
    'जहर',
    'विष',
    'বিষ',
  ];

  @override
  Future<AiResponseType> generateResponse({
    required String question,
    FarmLocation? location,
    CurrentWeather? weather,
    List<String> savedCrops = const [],
  }) async {
    final query = _normalize(question);
    final crop = _detectCrop(query);
    final intent = detectIntent(query);

    return switch (intent) {
      FarmingIntent.greeting => AiResponseType.greeting,
      FarmingIntent.languageQuestion => AiResponseType.languageSupport,
      FarmingIntent.cropProblem => switch (crop) {
        DetectedCrop.wheat => AiResponseType.cropProblemWheat,
        DetectedCrop.rice => AiResponseType.cropProblemRice,
        DetectedCrop.unknown => AiResponseType.cropProblemGeneral,
      },
      FarmingIntent.irrigation =>
        (weather?.rainProbabilityPercent ?? 0) >= 60
            ? AiResponseType.irrigationDelayForRain
            : AiResponseType.irrigationNormal,
      FarmingIntent.weather =>
        (weather?.rainProbabilityPercent ?? 0) >= 50
            ? AiResponseType.rainExpected
            : AiResponseType.weatherNormal,
      FarmingIntent.fertilizer => AiResponseType.fertilizer,
      FarmingIntent.pest => AiResponseType.pests,
      FarmingIntent.yellowLeaves => AiResponseType.yellowLeaves,
      FarmingIntent.disease => AiResponseType.cropDisease,
      FarmingIntent.sowingTime => AiResponseType.sowingTime,
      FarmingIntent.marketPrice => AiResponseType.marketPrice,
      FarmingIntent.governmentScheme => AiResponseType.governmentSchemes,
      FarmingIntent.expertSupport => AiResponseType.agriculturalExpert,
      FarmingIntent.unknown => AiResponseType.general,
    };
  }

  FarmingIntent detectIntent(String question) {
    final query = _normalize(question);
    if (_contains(query, _languageKeywords)) {
      return FarmingIntent.languageQuestion;
    }
    if (_contains(query, _greetingKeywords)) return FarmingIntent.greeting;
    if (_contains(query, _expertKeywords)) return FarmingIntent.expertSupport;
    if (_contains(query, _yellowLeafKeywords)) {
      return FarmingIntent.yellowLeaves;
    }
    if (_contains(query, _irrigationKeywords)) return FarmingIntent.irrigation;
    if (_contains(query, _weatherKeywords)) return FarmingIntent.weather;
    if (_contains(query, _fertilizerKeywords)) return FarmingIntent.fertilizer;
    if (_contains(query, _pestKeywords)) return FarmingIntent.pest;
    if (_contains(query, _diseaseKeywords)) return FarmingIntent.disease;
    if (_contains(query, _sowingKeywords)) return FarmingIntent.sowingTime;
    if (_contains(query, _marketKeywords)) return FarmingIntent.marketPrice;
    if (_contains(query, _schemeKeywords)) {
      return FarmingIntent.governmentScheme;
    }

    final hasCrop = _detectCrop(query) != DetectedCrop.unknown;
    if (hasCrop && _contains(query, _problemKeywords)) {
      return FarmingIntent.cropProblem;
    }
    if (_contains(query, _problemKeywords)) return FarmingIntent.cropProblem;
    return FarmingIntent.unknown;
  }

  DetectedCrop _detectCrop(String query) {
    if (_contains(query, _wheatKeywords)) return DetectedCrop.wheat;
    if (_contains(query, _riceKeywords)) return DetectedCrop.rice;
    return DetectedCrop.unknown;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0900-\u097f\u0980-\u09ff]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _contains(String query, List<String> keywords) {
    final paddedQuery = ' $query ';
    return keywords.any((keyword) {
      final normalizedKeyword = _normalize(keyword);
      return paddedQuery.contains(' $normalizedKeyword ');
    });
  }
}
