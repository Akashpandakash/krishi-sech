import 'dart:convert';
import 'package:krishi_sech/features/smart_dashboard/domain/entities/smart_recommendation_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartRecommendationCache {
  static const key = 'smart_recommendation_dashboard_cache_v1';
  Future<SmartRecommendationSnapshot?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SmartRecommendationSnapshot(
        irrigation: json['irrigation'] == null
            ? null
            : IrrigationSummary.fromJson(
                json['irrigation'] as Map<String, dynamic>,
              ),
        fertilizer: json['fertilizer'] == null
            ? null
            : FertilizerSummary.fromCache(
                json['fertilizer'] as Map<String, dynamic>,
              ),
        diseaseSeverity: json['diseaseSeverity'] as String?,
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SmartRecommendationSnapshot value) async {
    await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode({
        'irrigation': value.irrigation?.toJson(),
        'fertilizer': value.fertilizer?.toJson(),
        'diseaseSeverity': value.diseaseSeverity,
      }),
    );
  }
}
