import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/disease_scan_repository.dart';

class DemoDiseaseScanRepository implements DiseaseScanRepository {
  const DemoDiseaseScanRepository();

  @override
  Future<DiseaseScanResult> scan(DiseaseScanRequest request) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return DiseaseScanResult(
      scanId: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      cropName: request.cropName?.trim().isNotEmpty == true
          ? request.cropName!.trim()
          : 'Sample crop',
      possibleDisease: 'Leaf spot (sample)',
      confidence: 0.58,
      severity: 'Low',
      visibleSymptoms: const ['Small discoloured spots on the leaves'],
      recommendedActions: const [
        'Keep leaves dry and monitor new growth',
        'Consult a crop expert before treatment',
      ],
      needsExpertReview: true,
      followUpQuestions: const [
        'When did the spots first appear?',
        'Are the spots spreading to new leaves?',
      ],
      treatment: const ['Keep leaves dry'],
      medicine: const [],
      organicAlternative: const ['Remove affected leaves'],
      prevention: const ['Monitor new growth'],
      createdAt: DateTime.now(),
    );
  }
}
