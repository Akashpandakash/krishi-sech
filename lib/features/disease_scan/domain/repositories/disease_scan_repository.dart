import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';

abstract interface class DiseaseScanRepository {
  Future<DiseaseScanResult> scan(DiseaseScanRequest request);
}
