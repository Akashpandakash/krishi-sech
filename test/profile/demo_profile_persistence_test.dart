import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:krishi_sech/features/profile/data/repositories/in_memory_profile_repository.dart';
import 'package:krishi_sech/features/profile/data/repositories/local_only_profile_repository.dart';
import 'package:krishi_sech/features/profile/data/services/profile_storage_migrator.dart';
import 'package:krishi_sech/features/profile/domain/entities/farm_profile.dart';
import 'package:krishi_sech/features/profile/domain/entities/user_profile.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/services/demo_session_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('logout and demo login preserve profile, farm, and photo', () async {
    final preferences = await SharedPreferences.getInstance();
    final demoLocal = LocalProfileDataSource(
      preferences,
      storageNamespace: 'demo',
    );
    final demoRepository = LocalOnlyProfileRepository(demoLocal);
    final controller = ProfileController(
      InMemoryProfileRepository(),
      demoMode: true,
      demoRepository: demoRepository,
    );
    final directory = await Directory.systemTemp.createTemp(
      'krishi_demo_profile_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final photo = File('${directory.path}/profile.jpg');
    await photo.writeAsBytes([1, 2, 3]);

    await controller.saveUser(
      const UserProfile(
        id: 'demo-farmer',
        phone: '+919999999999',
        fullName: 'Saved Demo Farmer',
        preferredLanguage: 'hi',
        state: 'West Bengal',
        district: 'Kolkata',
        village: 'Demo Village',
      ),
    );
    await controller.saveProfilePhoto(photo.path);
    await controller.saveFarm(_farm);

    controller.clearSession();
    expect(controller.user, isNull);
    expect(demoLocal.readUser()?.fullName, 'Saved Demo Farmer');
    expect(demoLocal.readFarm()?.farmName, 'Saved Demo Farm');

    const returningBackendUser = AuthUser(
      id: 'database-generated-demo-uuid',
      phone: '+919999999999',
      name: 'Demo Farmer',
      preferredLanguage: 'en',
      isActive: true,
    );
    expect(
      DemoSessionPolicy.matches(returningBackendUser, demoModeEnabled: true),
      isTrue,
    );
    await controller.enterDemoMode();
    expect(controller.user?.fullName, 'Saved Demo Farmer');
    expect(controller.user?.profilePhotoPath, photo.path);
    expect(File(controller.user!.profilePhotoPath!).existsSync(), isTrue);
    expect(controller.farm?.farmName, 'Saved Demo Farm');
  });

  test('demo policy ignores backend ID and is disabled outside demo mode', () {
    const user = AuthUser(
      id: 'random-postgres-uuid',
      phone: '+919999999999',
      name: 'Demo Farmer',
      preferredLanguage: 'en',
      isActive: true,
    );
    expect(DemoSessionPolicy.matches(user, demoModeEnabled: true), isTrue);
    expect(DemoSessionPolicy.matches(user, demoModeEnabled: false), isFalse);
  });

  test('process restart restores demo data and selected language', () async {
    final preferences = await SharedPreferences.getInstance();
    final demoLocal = LocalProfileDataSource(
      preferences,
      storageNamespace: 'demo',
    );
    const savedUser = UserProfile(
      id: 'demo-farmer',
      phone: '+919999999999',
      fullName: 'Restarted Farmer',
      preferredLanguage: 'bn',
      profilePhotoPath: '/persistent/app/documents/profile.jpg',
    );
    await demoLocal.writeUser(savedUser);
    await demoLocal.writeFarm(_farm);
    final locale = await LocaleController.load();
    await locale.setLocale(const Locale('hi'));
    locale.dispose();

    final restartedLocale = await LocaleController.load();
    final restartedController = ProfileController(
      InMemoryProfileRepository(),
      demoMode: true,
      demoRepository: LocalOnlyProfileRepository(demoLocal),
      demoUser: demoLocal.readUser(),
      demoFarm: demoLocal.readFarm(),
    );

    expect(restartedController.user?.fullName, 'Restarted Farmer');
    expect(
      restartedController.user?.profilePhotoPath,
      '/persistent/app/documents/profile.jpg',
    );
    expect(restartedController.farm?.farmName, 'Saved Demo Farm');
    expect(restartedLocale.locale.languageCode, 'hi');
    restartedLocale.dispose();
  });

  test('legacy demo cache migrates without touching real-user data', () async {
    final preferences = await SharedPreferences.getInstance();
    final legacy = LocalProfileDataSource(preferences);
    final demo = LocalProfileDataSource(preferences, storageNamespace: 'demo');
    const legacyDemo = UserProfile(
      id: 'legacy-backend-generated-uuid',
      phone: '+919999999999',
      fullName: 'Legacy Demo Farmer',
      preferredLanguage: 'en',
      state: 'West Bengal',
      district: 'Kolkata',
      village: 'Legacy Village',
    );
    await legacy.writeUser(legacyDemo);
    await legacy.writeFarm(_farm);
    await demo.writeUser(
      const UserProfile(
        id: 'demo-farmer',
        phone: '+919999999999',
        fullName: 'Demo Farmer',
        preferredLanguage: 'hi',
        profilePhotoPath: '/app/documents/current.jpg',
      ),
    );

    await ProfileStorageMigrator(
      legacy: legacy,
      demo: demo,
    ).migrateLegacyDemoProfile();

    expect(demo.readUser()?.fullName, 'Legacy Demo Farmer');
    expect(demo.readUser()?.id, 'demo-farmer');
    expect(demo.readUser()?.profilePhotoPath, '/app/documents/current.jpg');
    expect(demo.readUser()?.state, 'West Bengal');
    expect(demo.readUser()?.district, 'Kolkata');
    expect(demo.readUser()?.village, 'Legacy Village');
    expect(demo.readUser()?.preferredLanguage, 'hi');
    expect(demo.readFarm()?.farmName, 'Saved Demo Farm');
    expect(legacy.readUser(), isNull);
    expect(legacy.readFarm(), isNull);

    const realUser = UserProfile(
      id: 'real-user',
      phone: '+919876543210',
      fullName: 'Real Farmer',
      preferredLanguage: 'en',
    );
    await legacy.writeUser(realUser);
    await ProfileStorageMigrator(
      legacy: legacy,
      demo: demo,
    ).migrateLegacyDemoProfile();
    expect(legacy.readUser()?.id, 'real-user');
    expect(demo.readUser()?.id, 'demo-farmer');
  });
}

const _farm = FarmProfile(
  farmName: 'Saved Demo Farm',
  farmerType: 'Small farmer',
  totalLandArea: 2,
  landUnit: 'acre',
  soilType: 'loamy',
  irrigationSource: 'canal',
  mainCrops: ['Paddy'],
);
