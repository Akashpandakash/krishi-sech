import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/profile/data/datasources/local_profile_data_source.dart';
import 'package:krishi_sech/features/profile/data/repositories/in_memory_profile_repository.dart';
import 'package:krishi_sech/features/profile/data/repositories/local_only_profile_repository.dart';
import 'package:krishi_sech/features/profile/data/repositories/local_profile_photo_repository.dart';
import 'package:krishi_sech/features/profile/domain/entities/user_profile.dart';
import 'package:krishi_sech/features/profile/domain/repositories/profile_photo_repository.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';
import 'package:krishi_sech/features/profile/presentation/pages/profile_page.dart';
import 'package:krishi_sech/features/profile/presentation/profile_scope.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = UserProfile(
  id: 'demo-farmer',
  phone: '+919999999999',
  fullName: 'Demo Farmer',
  preferredLanguage: 'en',
);

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'krishi_profile_photo_',
    );
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'selected image is validated and copied into app-owned storage',
    () async {
      final source = File('${temporaryDirectory.path}/picked.png');
      await source.writeAsBytes(_onePixelPng);
      final repository = LocalProfilePhotoRepository(
        imagePicker: () async => XFile(source.path),
        directoryProvider: () async => temporaryDirectory,
      );

      final path = await repository.selectAndPersist(userId: _user.id);

      expect(path, isNotNull);
      expect(path, isNot(source.path));
      expect(path, contains('profile_photos'));
      expect(File(path!).readAsBytesSync(), _onePixelPng);
    },
  );

  test('cancel returns null and invalid image is rejected safely', () async {
    final cancelled = LocalProfilePhotoRepository(
      imagePicker: () async => null,
      directoryProvider: () async => temporaryDirectory,
    );
    expect(await cancelled.selectAndPersist(userId: _user.id), isNull);

    final invalid = File('${temporaryDirectory.path}/invalid.jpg');
    await invalid.writeAsString('not an image');
    final invalidRepository = LocalProfilePhotoRepository(
      imagePicker: () async => XFile(invalid.path),
      directoryProvider: () async => temporaryDirectory,
    );
    await expectLater(
      invalidRepository.selectAndPersist(userId: _user.id),
      throwsA(isA<InvalidProfilePhoto>()),
    );
  });

  test(
    'demo photo path persists separately and restores after restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final demoLocal = LocalProfileDataSource(
        preferences,
        storageNamespace: 'demo',
      );
      final realLocal = LocalProfileDataSource(preferences);
      final demoRepository = LocalOnlyProfileRepository(demoLocal);
      final controller = ProfileController(
        InMemoryProfileRepository(),
        demoMode: true,
        demoRepository: demoRepository,
      );
      final photo = File('${temporaryDirectory.path}/profile.jpg');
      await photo.writeAsBytes(_onePixelPng);

      expect(await controller.saveProfilePhoto(photo.path), isTrue);
      final restarted = ProfileController(
        InMemoryProfileRepository(),
        demoMode: true,
        demoRepository: demoRepository,
        demoUser: demoLocal.readUser(),
      );

      expect(restarted.user?.profilePhotoPath, photo.path);
      expect(realLocal.readUser(), isNull);
    },
  );

  testWidgets('successful selection updates avatar immediately', (
    tester,
  ) async {
    final photo = File('assets/logo/krishi_sech_logo.png');
    expect(photo.existsSync(), isTrue);
    final controller = ProfileController(
      InMemoryProfileRepository(),
      demoMode: true,
    );

    await _pumpProfile(
      tester,
      controller,
      photoRepository: _FakePhotoRepository(photo.path),
    );
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.user?.profilePhotoPath, photo.path);
    expect(find.byKey(ValueKey('profile_photo_${photo.path}')), findsOneWidget);
    expect(find.byKey(const Key('profile_photo_fallback')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('cancel keeps fallback and missing file uses fallback', (
    tester,
  ) async {
    final controller = ProfileController(
      InMemoryProfileRepository(),
      demoMode: true,
    );
    await _pumpProfile(
      tester,
      controller,
      photoRepository: _FakePhotoRepository(null),
    );
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.user?.profilePhotoPath, isNull);
    expect(find.byKey(const Key('profile_photo_fallback')), findsOneWidget);

    await controller.saveUser(
      UserProfile(
        id: _user.id,
        phone: _user.phone,
        fullName: _user.fullName,
        preferredLanguage: _user.preferredLanguage,
        profilePhotoPath: '${temporaryDirectory.path}/missing.jpg',
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('profile_photo_fallback')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pumpProfile(
  WidgetTester tester,
  ProfileController controller, {
  required ProfilePhotoRepository photoRepository,
}) async {
  final localeController = LocaleController.inMemory(
    locale: const Locale('en'),
  );
  addTearDown(localeController.dispose);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProfileScope(
      controller: controller,
      child: LocaleScope(
        controller: localeController,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ProfilePage(photoRepository: photoRepository)),
        ),
      ),
    ),
  );
}

class _FakePhotoRepository implements ProfilePhotoRepository {
  const _FakePhotoRepository(this.path);
  final String? path;

  @override
  Future<String?> selectAndPersist({required String userId}) async => path;
}

final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
