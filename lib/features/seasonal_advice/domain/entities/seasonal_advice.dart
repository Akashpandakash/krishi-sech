enum SeasonalAdviceType { rain, humidity, heat, wind, normal }

enum AdviceWarningLevel { low, medium, high }

class SeasonalAdvice {
  const SeasonalAdvice({
    required this.type,
    required this.warningLevel,
    required this.updatedAt,
  });

  final SeasonalAdviceType type;
  final AdviceWarningLevel warningLevel;
  final DateTime updatedAt;
}
