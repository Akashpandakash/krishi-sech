import 'package:krishi_sech/features/disease_scan/data/datasources/remote_disease_scan_data_source.dart';
import 'package:krishi_sech/core/network/api_config.dart';
import 'package:krishi_sech/features/disease_scan/data/datasources/local_disease_diagnosis_store.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/remote_disease_scan_repository.dart';
import 'package:krishi_sech/features/disease_scan/domain/repositories/disease_scan_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/demo_disease_scan_repository.dart';

abstract final class DiseaseScanRepositoryFactory {
  static DiseaseScanRepository create({
    required DiseaseAccessTokenProvider accessTokenProvider,
  }) {
    const demoRequested = bool.fromEnvironment('DISEASE_SCAN_DEMO');
    if (kDebugMode && demoRequested) {
      return const DemoDiseaseScanRepository();
    }
    return RemoteDiseaseScanRepository(
      RemoteDiseaseScanDataSource(
        baseUrl: ApiConfig.baseUrl,
        accessTokenProvider: accessTokenProvider,
      ),
      LocalDiseaseDiagnosisStore(),
    );
  }
}
