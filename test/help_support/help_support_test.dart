import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/core/localization/app_localization_config.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/help_support/data/datasources/local_support_report_data_source.dart';
import 'package:krishi_sech/features/help_support/data/repositories/local_help_support_repository.dart';
import 'package:krishi_sech/features/help_support/domain/entities/support_report.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/help_support_repository.dart';
import 'package:krishi_sech/features/help_support/domain/repositories/support_attachment_repository.dart';
import 'package:krishi_sech/features/help_support/presentation/pages/help_support_page.dart';
import 'package:krishi_sech/features/profile/presentation/pages/profile_page.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryHelpSupportRepository implements HelpSupportRepository {
  final List<SupportReport> reports = [];

  @override
  Future<List<SupportReport>> getReports() async => List.of(reports);

  @override
  Future<SupportReport> submitReport({
    required String subject,
    required String description,
    String? screenshotPath,
  }) async {
    final report = SupportReport(
      id: 'report-${reports.length + 1}',
      subject: subject,
      description: description,
      screenshotPath: screenshotPath,
      createdAt: DateTime(2026, 8, 6),
    );
    reports.add(report);
    return report;
  }
}

class _NoopAttachmentRepository implements SupportAttachmentRepository {
  @override
  Future<String?> chooseScreenshot() async => null;
}

class _HelpTestApp extends StatelessWidget {
  const _HelpTestApp({
    required this.controller,
    required this.repository,
    this.showProfile = false,
  });

  final LocaleController controller;
  final HelpSupportRepository repository;
  final bool showProfile;

  @override
  Widget build(BuildContext context) => LocaleScope(
    controller: controller,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        locale: controller.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizationConfig.delegates,
        builder: (context, child) => Directionality(
          textDirection: AppLocalizationConfig.directionFor(controller.locale),
          child: child!,
        ),
        home: showProfile
            ? const Scaffold(body: ProfilePage())
            : HelpSupportPage(
                repository: repository,
                attachmentRepository: _NoopAttachmentRepository(),
              ),
        routes: {
          AppRoutes.helpSupport: (_) => HelpSupportPage(
            repository: repository,
            attachmentRepository: _NoopAttachmentRepository(),
          ),
        },
      ),
    ),
  );
}

void main() {
  late _MemoryHelpSupportRepository repository;

  setUp(() {
    repository = _MemoryHelpSupportRepository();
    SharedPreferences.setMockInitialValues({});
  });

  Future<LocaleController> pumpHelp(
    WidgetTester tester, {
    String locale = 'en',
    bool showProfile = false,
  }) async {
    final controller = LocaleController.inMemory(locale: Locale(locale));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _HelpTestApp(
        controller: controller,
        repository: repository,
        showProfile: showProfile,
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('Profile Help & Support opens the real page and Back returns', (
    tester,
  ) async {
    await pumpHelp(tester, showProfile: true);

    await tester.ensureVisible(find.text('Help & support'));
    await tester.tap(find.text('Help & support'));
    await tester.pumpAndSettle();

    expect(find.byType(HelpSupportPage), findsOneWidget);
    expect(find.text('Frequently Asked Questions'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('FAQ item expands and reveals its answer', (tester) async {
    await pumpHelp(tester);

    expect(find.text('How do I change the app language?'), findsOneWidget);
    expect(find.textContaining('Open Profile, choose Language'), findsNothing);

    await tester.tap(find.byKey(const Key('support_faq_0')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Open Profile, choose Language'),
      findsOneWidget,
    );
  });

  testWidgets('report form validates required fields', (tester) async {
    await pumpHelp(tester);
    final submit = find.byKey(const Key('support_report_submit'));
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Enter a subject.'), findsOneWidget);
    expect(find.text('Describe the problem.'), findsOneWidget);
    expect(repository.reports, isEmpty);
  });

  testWidgets('valid report submits successfully and updates local state', (
    tester,
  ) async {
    await pumpHelp(tester);
    await tester.ensureVisible(find.byKey(const Key('support_report_subject')));
    await tester.enterText(
      find.byKey(const Key('support_report_subject')),
      'Crop page issue',
    );
    await tester.enterText(
      find.byKey(const Key('support_report_description')),
      'The crop card does not refresh.',
    );
    final submit = find.byKey(const Key('support_report_submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.reports, hasLength(1));
    expect(
      find.byKey(const Key('support_report_success_notice')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('support_reports_success')), findsOneWidget);
  });

  test('local repository restores submitted demo reports', () async {
    final preferences = await SharedPreferences.getInstance();
    final first = LocalHelpSupportRepository(
      LocalSupportReportDataSource(preferences),
    );
    await first.submitReport(
      subject: 'Local report',
      description: 'Stored only on this device',
    );

    final restored = LocalHelpSupportRepository(
      LocalSupportReportDataSource(preferences),
    );
    final reports = await restored.getReports();
    expect(reports, hasLength(1));
    expect(reports.single.subject, 'Local report');
  });

  for (final entry in const [
    ('bn', 'সচরাচর জিজ্ঞাসিত প্রশ্ন', 'সমস্যা জানান'),
    ('hi', 'अक्सर पूछे जाने वाले प्रश्न', 'समस्या की रिपोर्ट करें'),
  ]) {
    testWidgets('${entry.$1} renders translated Help & Support labels', (
      tester,
    ) async {
      await pumpHelp(tester, locale: entry.$1);
      expect(find.text(entry.$2), findsOneWidget);
      await tester.ensureVisible(find.text(entry.$3));
      expect(find.text(entry.$3), findsOneWidget);
    });
  }

  testWidgets('fallback locale renders safe English Help & Support labels', (
    tester,
  ) async {
    await pumpHelp(tester, locale: 'gu');
    expect(find.text('Frequently Asked Questions'), findsOneWidget);
    await tester.ensureVisible(find.text('Report a Problem'));
    expect(find.text('Report a Problem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
