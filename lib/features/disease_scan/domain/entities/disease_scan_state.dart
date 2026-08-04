import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';

sealed class DiseaseScanState {
  const DiseaseScanState();
}

class DiseaseScanLoading extends DiseaseScanState {
  const DiseaseScanLoading({this.uploadProgress});

  final double? uploadProgress;
}

class DiseaseScanSuccess extends DiseaseScanState {
  const DiseaseScanSuccess(this.result);

  final DiseaseScanResult result;
}

class DiseaseScanLowConfidence extends DiseaseScanState {
  const DiseaseScanLowConfidence(this.result);

  final DiseaseScanResult result;
}

class DiseaseScanExpertReview extends DiseaseScanState {
  const DiseaseScanExpertReview(this.result);

  final DiseaseScanResult result;
}

class DiseaseScanError extends DiseaseScanState {
  const DiseaseScanError(this.cause);

  final Object cause;
}
