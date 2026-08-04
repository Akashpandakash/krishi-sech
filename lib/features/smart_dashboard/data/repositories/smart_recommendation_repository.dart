import 'package:krishi_sech/features/disease_scan/data/datasources/local_disease_diagnosis_store.dart';
import 'package:krishi_sech/features/smart_dashboard/data/datasources/remote_smart_recommendation_data_source.dart';
import 'package:krishi_sech/features/smart_dashboard/data/datasources/smart_recommendation_cache.dart';
import 'package:krishi_sech/features/smart_dashboard/domain/entities/smart_recommendation_snapshot.dart';

class SmartRecommendationRepository {
  const SmartRecommendationRepository(
    this.remote,
    this.cache,
    this.diseaseStore,
  );
  final RemoteSmartRecommendationDataSource remote;
  final SmartRecommendationCache cache;
  final LocalDiseaseDiagnosisStore diseaseStore;
  Future<SmartRecommendationSnapshot> load(String language) async {
    final cached = await cache.load();
    final diagnosis = await diseaseStore.getLast();
    try {
      final response = await remote.fetch(language: language);
      final merged = SmartRecommendationSnapshot(
        irrigation: response.irrigation ?? cached?.irrigation,
        fertilizer: response.fertilizer ?? cached?.fertilizer,
        diseaseSeverity: diagnosis?.severity ?? cached?.diseaseSeverity,
        fromCache:
            response.irrigation == null && cached?.irrigation != null ||
            response.fertilizer == null && cached?.fertilizer != null,
        irrigationFailed: response.irrigationFailed,
        fertilizerFailed: response.fertilizerFailed,
      );
      if (merged.irrigation != null || merged.fertilizer != null) {
        await cache.save(merged);
      }
      return merged;
    } catch (_) {
      return (cached ?? const SmartRecommendationSnapshot(fromCache: true))
          .copyWith(diseaseSeverity: diagnosis?.severity, fromCache: true);
    }
  }
}
