import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:krishi_sech/features/disease_scan/domain/entities/disease_scan_state.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/disease_scan_repository.dart';

class DiseaseScanController extends ChangeNotifier {
  DiseaseScanController(this._repository, {this.lowConfidenceThreshold = 0.65});

  final DiseaseScanRepository _repository;
  final double lowConfidenceThreshold;

  DiseaseScanState _state = const DiseaseScanLoading();
  DiseaseScanState get state => _state;

  Future<void> scan(DiseaseScanRequest request) async {
    _state = const DiseaseScanLoading();
    notifyListeners();
    try {
      final result = await _repository.scan(
        request.withUploadProgress((progress) {
          _state = DiseaseScanLoading(uploadProgress: progress.clamp(0, 1));
          notifyListeners();
        }),
      );
      _state = result.confidence < lowConfidenceThreshold
          ? DiseaseScanLowConfidence(result)
          : result.needsExpertReview
          ? DiseaseScanExpertReview(result)
          : DiseaseScanSuccess(result);
    } catch (error) {
      _state = DiseaseScanError(error);
    }
    notifyListeners();
  }
}
