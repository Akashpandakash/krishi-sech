import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/smart_dashboard/data/repositories/smart_recommendation_repository.dart';
import 'package:krishi_sech/features/smart_dashboard/domain/entities/smart_recommendation_snapshot.dart';

class SmartRecommendationController extends ChangeNotifier {
  SmartRecommendationController(this.repository);
  final SmartRecommendationRepository repository;
  SmartRecommendationSnapshot? snapshot;
  bool isLoading = false;
  Future<void> refresh(String language) async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();
    try {
      snapshot = await repository.load(language);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
