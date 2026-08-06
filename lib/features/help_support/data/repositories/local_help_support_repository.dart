import 'package:krishi_sech/features/help_support/data/datasources/local_support_report_data_source.dart';
import 'package:krishi_sech/features/help_support/domain/entities/support_report.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/help_support_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalHelpSupportRepository implements HelpSupportRepository {
  const LocalHelpSupportRepository(this._dataSource);

  final LocalSupportReportDataSource _dataSource;

  static Future<LocalHelpSupportRepository> create() async =>
      LocalHelpSupportRepository(
        LocalSupportReportDataSource(await SharedPreferences.getInstance()),
      );

  @override
  Future<List<SupportReport>> getReports() => _dataSource.getReports();

  @override
  Future<SupportReport> submitReport({
    required String subject,
    required String description,
    String? screenshotPath,
  }) async {
    final reports = await _dataSource.getReports();
    final now = DateTime.now();
    final report = SupportReport(
      id: 'local-${now.microsecondsSinceEpoch}',
      subject: subject,
      description: description,
      screenshotPath: screenshotPath,
      createdAt: now,
    );
    await _dataSource.saveReports([...reports, report]);
    return report;
  }
}
