import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/help_support/domain/entities/support_report.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/help_support_repository.dart';

class HelpSupportController extends ChangeNotifier {
  HelpSupportController(this.repository);

  final HelpSupportRepository repository;
  List<SupportReport> reports = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  Object? error;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      reports = await repository.getReports();
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String subject,
    required String description,
    String? screenshotPath,
  }) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      final report = await repository.submitReport(
        subject: subject,
        description: description,
        screenshotPath: screenshotPath,
      );
      reports = [...reports, report];
      return true;
    } catch (value) {
      error = value;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
