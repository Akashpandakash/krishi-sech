import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/core/localization/app_localization_config.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/language_selection/presentation/pages/language_selection_page.dart';
import 'package:krishi_sech/features/profile/presentation/pages/profile_page.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LanguageTestApp extends StatelessWidget {
  const _LanguageTestApp({
    required this.controller,
    this.home = const LanguageSelectionPage(),
  });

  final LocaleController controller;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          locale: controller.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizationConfig.delegates,
          builder: (context, child) => Directionality(
            textDirection: AppLocalizationConfig.directionFor(
              controller.locale,
            ),
            child: child!,
          ),
          home: home,
          routes: {'/login': (_) => const Scaffold(body: Text('Login'))},
        ),
      ),
    );
  }
}

void main() {
  testWidgets('all Scheduled Languages and English appear as options', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.pumpAndSettle();

    expect(AppLanguageCatalog.languages, hasLength(23));
    for (final language in AppLanguageCatalog.languages) {
      expect(find.byKey(Key('language_${language.code}')), findsOneWidget);
      expect(find.text(language.nativeName), findsWidgets);
    }
  });

  testWidgets('language search filters by English name, native name and code', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('language_search')), 'Telugu');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language_te')), findsOneWidget);
    expect(find.byKey(const Key('language_bn')), findsNothing);
  });

  testWidgets('Bangla selection updates the whole app immediately', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.enterText(find.byKey(const Key('language_search')), 'Bangla');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language_bn')));
    await tester.pumpAndSettle();

    expect(controller.locale.languageCode, 'bn');
    expect(find.text('এগিয়ে যেতে ভাষা নির্বাচন করুন'), findsOneWidget);
  });

  testWidgets('Hindi selection updates the whole app immediately', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.enterText(find.byKey(const Key('language_search')), 'Hindi');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language_hi')));
    await tester.pumpAndSettle();

    expect(controller.locale.languageCode, 'hi');
    expect(find.text('जारी रखने के लिए भाषा चुनें'), findsOneWidget);
  });

  test('selected Scheduled Language persists after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await LocaleController.load();
    await first.setLocale(const Locale('mr'));
    first.dispose();

    final restored = await LocaleController.load();
    addTearDown(restored.dispose);
    expect(restored.locale.languageCode, 'mr');
    expect(restored.hasSavedLocale, isTrue);
  });

  for (final entry in const [('gu', 'Gujarati'), ('as', 'Assamese')]) {
    test('${entry.$2} selection persists after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await LocaleController.load();
      await first.setLocale(Locale(entry.$1));
      first.dispose();

      final restored = await LocaleController.load();
      addTearDown(restored.dispose);
      expect(restored.locale.languageCode, entry.$1);
      expect(restored.hasSavedLocale, isTrue);
    });
  }

  test('untranslated service requests safely fall back to English', () {
    expect(AppLanguageCatalog.serviceCodeFor('gu'), 'en');
    expect(AppLanguageCatalog.serviceCodeFor('bn'), 'bn');
    expect(AppLanguageCatalog.serviceCodeFor('hi'), 'hi');
  });

  test('fallback notice consumption persists across restart', () async {
    SharedPreferences.setMockInitialValues({});
    final language = AppLanguageCatalog.fromCode('gu');
    final first = await LocaleController.load();
    expect(await first.consumeFallbackNotice(language), isTrue);
    expect(await first.consumeFallbackNotice(language), isFalse);
    first.dispose();

    final restored = await LocaleController.load();
    addTearDown(restored.dispose);
    expect(await restored.consumeFallbackNotice(language), isFalse);
  });

  testWidgets('untranslated locale renders English fallback without raw keys', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('gu'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Preferred Language'), findsOneWidget);
    expect(find.text('languageTitle'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile keeps the selected fallback language name visible', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('gu'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _LanguageTestApp(controller: controller, home: const ProfilePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gujarati • English fallback'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('fallback notice appears only once for a selected language', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));

    await tester.enterText(
      find.byKey(const Key('language_search')),
      'Gujarati',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language_gu')));
    await tester.pump();

    expect(find.byKey(const Key('fallback_language_notice')), findsOneWidget);
    expect(
      find.textContaining('Full translation is coming soon'),
      findsOneWidget,
    );

    ScaffoldMessenger.of(
      tester.element(find.byType(LanguageSelectionPage)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('language_search')), 'English');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language_en')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('language_search')),
      'Gujarati',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language_gu')));
    await tester.pump();

    expect(find.byKey(const Key('fallback_language_notice')), findsNothing);
  });

  testWidgets('Bangla and Hindi remain marked fully translated', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(locale: const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('language_status_bn'))).data,
      'Fully translated',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('language_status_hi'))).data,
      'Fully translated',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('language_status_gu'))).data,
      'English fallback',
    );
  });

  for (final code in const ['ur', 'ks', 'sd']) {
    testWidgets('$code uses RTL layout', (tester) async {
      final controller = LocaleController.inMemory(locale: Locale(code));
      addTearDown(controller.dispose);
      await tester.pumpWidget(_LanguageTestApp(controller: controller));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LanguageSelectionPage));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('language selector scrolls on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = LocaleController.inMemory(locale: const Locale('bn'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(_LanguageTestApp(controller: controller));
    await tester.pumpAndSettle();

    final english = find.byKey(const Key('language_en'));
    expect(english, findsOneWidget);
    await tester.scrollUntilVisible(
      english,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(english).overlaps(const Rect.fromLTWH(0, 0, 320, 568)),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
