import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:krishi_sech/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:krishi_sech/features/profile/data/datasources/remote_profile_data_source.dart';
import 'package:krishi_sech/features/profile/data/repositories/in_memory_profile_repository.dart';
import 'package:krishi_sech/features/profile/data/repositories/synced_profile_repository.dart';
import 'package:krishi_sech/features/profile/domain/entities/farm_profile.dart';
import 'package:krishi_sech/features/profile/domain/entities/user_profile.dart';
import 'package:krishi_sech/features/profile/domain/repositories/profile_repository.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const realUser = UserProfile(
    id: 'user-1',
    phone: '+919812345678',
    fullName: 'Akash Farmer',
    preferredLanguage: 'bn',
  );

  test('real authenticated profile never receives demo identity', () async {
    final controller = ProfileController(
      InMemoryProfileRepository(user: realUser),
    );
    await controller.load();
    expect(controller.greetingName, 'Akash Farmer');
    expect(controller.greetingName, isNot('Ramesh Kumar'));
  });

  test('demo identity is available only with explicit demo mode', () async {
    final repository = _CountingProfileRepository(realUser);
    final controller = ProfileController(repository, demoMode: true);
    expect(controller.greetingName, 'Ramesh Kumar');
    expect(controller.user?.id, 'demo-farmer');

    await controller.saveUser(
      const UserProfile(
        id: 'demo-farmer',
        phone: '+919999999999',
        fullName: 'Demo Edited',
        preferredLanguage: 'en',
      ),
    );
    await controller.saveFarm(
      const FarmProfile(
        farmName: 'Demo Farm',
        farmerType: 'Demo',
        totalLandArea: 1,
        landUnit: 'acre',
        soilType: 'loamy',
        irrigationSource: 'demo',
        mainCrops: ['Demo crop'],
      ),
    );
    expect(repository.readCalls, 0);
    expect(repository.writeCalls, 0);

    controller.clearSession();
    await controller.load();
    expect(controller.greetingName, 'Akash Farmer');
    expect(repository.readCalls, 2);
  });

  test('user and farm updates are exposed immediately', () async {
    final controller = ProfileController(
      InMemoryProfileRepository(user: realUser),
    );
    await controller.load();
    final userSaved = await controller.saveUser(
      const UserProfile(
        id: 'user-1',
        phone: '+919812345678',
        fullName: 'Updated Farmer',
        preferredLanguage: 'hi',
        state: 'West Bengal',
      ),
    );
    final farmSaved = await controller.saveFarm(
      const FarmProfile(
        farmName: 'Green Farm',
        farmerType: 'Small farmer',
        totalLandArea: 2.5,
        landUnit: 'acre',
        soilType: 'loamy',
        irrigationSource: 'canal',
        mainCrops: ['Paddy'],
      ),
    );
    expect(userSaved, isTrue);
    expect(farmSaved, isTrue);
    expect(controller.greetingName, 'Updated Farmer');
    expect(controller.farm?.farmName, 'Green Farm');
  });

  test('offline cached edit remains valid and readable', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final local = LocalProfileDataSource(preferences);
    final repository = SyncedProfileRepository(
      local,
      RemoteProfileDataSource(
        baseUrl: 'https://api.example.com',
        accessTokenProvider: ({bool forceRefresh = false}) async => 'token',
        client: MockClient((_) async => throw const SocketException('offline')),
      ),
    );
    const edited = UserProfile(
      id: 'user-1',
      phone: '+919812345678',
      fullName: 'Offline Farmer',
      preferredLanguage: 'en',
      state: 'West Bengal',
    );

    await expectLater(repository.saveUser(edited), throwsA(isA<Exception>()));

    final cached = local.readUser();
    expect(cached?.fullName, 'Offline Farmer');
    expect(cached?.phone, '+919812345678');
    expect(cached?.state, 'West Bengal');
  });
}

class _CountingProfileRepository implements ProfileRepository {
  _CountingProfileRepository(this.realUser);
  final UserProfile realUser;
  int readCalls = 0;
  int writeCalls = 0;

  @override
  Future<UserProfile?> loadUser() async {
    readCalls += 1;
    return realUser;
  }

  @override
  Future<FarmProfile?> loadFarm() async {
    readCalls += 1;
    return null;
  }

  @override
  Future<UserProfile> saveUser(UserProfile profile) async {
    writeCalls += 1;
    return profile;
  }

  @override
  Future<FarmProfile> saveFarm(FarmProfile profile) async {
    writeCalls += 1;
    return profile;
  }
}
