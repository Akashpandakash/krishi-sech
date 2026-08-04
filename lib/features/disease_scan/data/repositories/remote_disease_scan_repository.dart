import 'package:krishi_sech/features/disease_scan/data/datasources/remote_disease_scan_data_source.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/disease_scan_repository.dart';
import 'package:krishi_sech/features/disease_scan/data/datasources/local_disease_diagnosis_store.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/core/config/app_environment.dart';

class RemoteDiseaseScanRepository implements DiseaseScanRepository {
  const RemoteDiseaseScanRepository(this.dataSource, this.store);

  final RemoteDiseaseScanDataSource dataSource;
  final LocalDiseaseDiagnosisStore store;

  @override
  Future<DiseaseScanResult> scan(DiseaseScanRequest request) async {
    final result = await dataSource.scan(request);
    await store.save(result);
    if (kDebugMode && AppEnvironment.loggingEnabled) {
      debugPrint('[AI Vision] ✓ step=12 diagnosis saved to history');
    }
    return result;
  }
}
