import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/profile/domain/entities/farm_profile.dart';
import 'package:krishi_sech/features/profile/domain/entities/user_profile.dart';
import 'package:krishi_sech/features/profile/domain/repositories/profile_repository.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';
import 'package:krishi_sech/features/profile/presentation/pages/profile_page.dart';
import 'package:krishi_sech/features/profile/presentation/profile_scope.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'personal details saves once, closes, updates summary and reopens',
    (tester) async {
      final repository = _DelayedProfileRepository();
      final profileController = ProfileController(repository);
      final localeController = LocaleController.inMemory(
        locale: const Locale('en'),
      );
      await profileController.load();
      await tester.pumpWidget(
        ProfileScope(
          controller: profileController,
          child: LocaleScope(
            controller: localeController,
            child: const MaterialApp(
              locale: Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(body: ProfilePage()),
            ),
          ),
        ),
      );

      expect(find.text('Real Farmer'), findsWidgets);

      await tester.tap(find.byKey(const Key('personal_details_tile')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('personal_details_name')),
        'Updated Farmer',
      );
      await tester.enterText(
        find.byKey(const Key('personal_details_state')),
        'West Bengal',
      );
      await tester.enterText(
        find.byKey(const Key('personal_details_district')),
        'Kolkata',
      );
      await tester.enterText(
        find.byKey(const Key('personal_details_village')),
        'Green Village',
      );

      await tester.tap(find.byKey(const Key('personal_details_save')));
      await tester.pump();

      expect(repository.userSaveCount, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('personal_details_save')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const Key('personal_details_save')),
        warnIfMissed: false,
      );
      expect(repository.userSaveCount, 1);

      repository.completeSave();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repository.userSaveCount, 1);
      expect(profileController.user?.fullName, 'Updated Farmer');
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_header_name')))
            .data,
        'Updated Farmer',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('personal_details_tile')),
          matching: find.text('Updated Farmer'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Green Village'), findsOneWidget);
      expect(find.textContaining('Kolkata'), findsOneWidget);
      expect(find.textContaining('West Bengal'), findsOneWidget);

      await tester.tap(find.byKey(const Key('personal_details_tile')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Updated Farmer'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'West Bengal'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Kolkata'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Green Village'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('personal_details_phone')),
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        isTrue,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      profileController.dispose();
      localeController.dispose();
    },
  );

  testWidgets(
    'demo personal save refreshes header and summary immediately',
    (tester) async {
      final profileController = ProfileController(
        _DelayedProfileRepository(),
        demoMode: true,
      );
      final localeController = LocaleController.inMemory(
        locale: const Locale('en'),
      );

      await tester.pumpWidget(
        ProfileScope(
          controller: profileController,
          child: LocaleScope(
            controller: localeController,
            child: const MaterialApp(
              locale: Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(body: ProfilePage()),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('personal_details_tile')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('personal_details_name')),
        'Demo Updated Farmer',
      );
      await tester.tap(find.byKey(const Key('personal_details_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('personal_details_save')), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_header_name')))
            .data,
        'Demo Updated Farmer',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('personal_details_tile')),
          matching: find.text('Demo Updated Farmer'),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      profileController.dispose();
      localeController.dispose();
    },
  );
}

class _DelayedProfileRepository implements ProfileRepository {
  UserProfile user = const UserProfile(
    id: 'real-user',
    phone: '+919876543210',
    fullName: 'Real Farmer',
    preferredLanguage: 'en',
  );
  int userSaveCount = 0;
  Completer<UserProfile>? _pendingSave;
  UserProfile? _pendingValue;

  @override
  Future<FarmProfile?> loadFarm() async => null;

  @override
  Future<UserProfile?> loadUser() async => user;

  @override
  Future<FarmProfile> saveFarm(FarmProfile profile) async => profile;

  @override
  Future<UserProfile> saveUser(UserProfile profile) {
    userSaveCount += 1;
    _pendingValue = profile;
    _pendingSave = Completer<UserProfile>();
    return _pendingSave!.future;
  }

  void completeSave() {
    final value = _pendingValue!;
    user = value;
    _pendingSave!.complete(value);
  }
}
