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
  testWidgets('farm details can be saved, closed, and reopened', (
    tester,
  ) async {
    final repository = _ProfileRepository();
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

    await tester.tap(find.text('Farm details'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(8));
    await tester.enterText(fields.at(0), 'Green Field Farm');
    await tester.enterText(fields.at(1), 'Small farmer');
    await tester.enterText(fields.at(2), '2.5');
    await tester.enterText(fields.at(3), 'acre');
    await tester.enterText(fields.at(4), 'loamy');
    await tester.enterText(fields.at(5), 'canal');
    await tester.enterText(fields.at(6), 'Paddy, Wheat');
    await tester.enterText(fields.at(7), 'Kolkata district');

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.farmSaveCount, 1);
    expect(profileController.farm?.farmName, 'Green Field Farm');
    expect(find.text('Green Field Farm'), findsWidgets);

    await tester.tap(find.text('Farm details'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Green Field Farm'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    profileController.dispose();
    localeController.dispose();
  });
}

class _ProfileRepository implements ProfileRepository {
  UserProfile user = const UserProfile(
    id: 'real-user',
    phone: '+919876543210',
    fullName: 'Real Farmer',
    preferredLanguage: 'en',
  );
  FarmProfile? farm;
  int farmSaveCount = 0;

  @override
  Future<FarmProfile?> loadFarm() async => farm;

  @override
  Future<UserProfile?> loadUser() async => user;

  @override
  Future<FarmProfile> saveFarm(FarmProfile profile) async {
    farmSaveCount += 1;
    return farm = profile;
  }

  @override
  Future<UserProfile> saveUser(UserProfile profile) async {
    user = profile;
    return user;
  }
}
