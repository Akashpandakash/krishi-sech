import 'package:krishi_sech/features/help_support/domain/entities/support_report.dart';

abstract interface class HelpSupportRepository {
  Future<List<SupportReport>> getReports();

  Future<SupportReport> submitReport({
    required String subject,
    required String description,
    String? screenshotPath,
  });
}
