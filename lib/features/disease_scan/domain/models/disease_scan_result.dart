class DiseaseScanResult {
  const DiseaseScanResult({
    required this.scanId,
    required this.cropName,
    required this.possibleDisease,
    required this.confidence,
    required this.severity,
    required this.visibleSymptoms,
    required this.recommendedActions,
    required this.needsExpertReview,
    required this.followUpQuestions,
    required this.treatment,
    required this.medicine,
    required this.organicAlternative,
    required this.prevention,
    required this.createdAt,
    this.isDemo = false,
  });

  final String scanId;
  final String cropName;
  final String possibleDisease;
  final double confidence;
  final String severity;
  final List<String> visibleSymptoms;
  final List<String> recommendedActions;
  final bool needsExpertReview;
  final List<String> followUpQuestions;
  final List<String> treatment;
  final List<String> medicine;
  final List<String> organicAlternative;
  final List<String> prevention;
  final DateTime createdAt;

  /// True only for the debug-gated sample diagnosis. A real diagnosis must
  /// never be labelled a demo, and a demo must never pass for a real one.
  final bool isDemo;

  factory DiseaseScanResult.fromJson(Map<String, dynamic> json) {
    final confidence = _requiredNumber(json, 'confidence').toDouble();
    final severity = _requiredString(json, 'severity').toLowerCase();
    if (confidence < 0 || confidence > 1) {
      throw const FormatException('Invalid confidence');
    }
    if (!const {'low', 'medium', 'high'}.contains(severity)) {
      throw const FormatException('Invalid severity');
    }
    return DiseaseScanResult(
      scanId: _requiredString(json, 'scanId'),
      cropName: _requiredString(
        json,
        json.containsKey('crop') ? 'crop' : 'cropName',
      ),
      possibleDisease: _requiredString(
        json,
        json.containsKey('disease') ? 'disease' : 'possibleDisease',
      ),
      confidence: confidence,
      severity: severity,
      visibleSymptoms: _stringList(
        json,
        json.containsKey('symptoms') ? 'symptoms' : 'visibleSymptoms',
      ),
      recommendedActions: [
        ..._stringList(json, 'treatment'),
        ..._stringList(json, 'medicine'),
        ..._stringList(json, 'organicAlternative'),
        ..._stringList(json, 'prevention'),
        if (!json.containsKey('treatment'))
          ..._stringList(json, 'recommendedActions'),
      ],
      needsExpertReview:
          json['expertConsultationRecommended'] as bool? ??
          json['needsExpertReview'] as bool? ??
          false,
      followUpQuestions: _stringList(json, 'followUpQuestions'),
      treatment: _stringList(json, 'treatment'),
      medicine: _stringList(json, 'medicine'),
      organicAlternative: _stringList(json, 'organicAlternative'),
      prevention: _stringList(json, 'prevention'),
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
    );
  }

  Map<String, dynamic> toJson() => {
    'scanId': scanId,
    'crop': cropName,
    'disease': possibleDisease,
    'confidence': confidence,
    'severity': severity,
    'symptoms': visibleSymptoms,
    'treatment': treatment,
    'medicine': medicine,
    'organicAlternative': organicAlternative,
    'prevention': prevention,
    'expertConsultationRecommended': needsExpertReview,
    'followUpQuestions': followUpQuestions,
    'createdAt': createdAt.toIso8601String(),
  };

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }

  static num _requiredNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) throw FormatException('Missing or invalid $key');
    return value;
  }

  static List<String> _stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}
