import '../../../login/domain/services/demo_session_policy.dart';
import '../../domain/entities/user_profile.dart';
import '../datasources/local_profile_data_source.dart';

class ProfileStorageMigrator {
  const ProfileStorageMigrator({required this.legacy, required this.demo});

  final LocalProfileDataSource legacy;
  final LocalProfileDataSource demo;

  Future<void> migrateLegacyDemoProfile() async {
    final legacyUser = legacy.readUser();
    if (legacyUser?.phone != DemoSessionPolicy.phone) return;
    final sourceUser = legacyUser!;
    final legacyFarm = legacy.readFarm();
    final currentDemo = demo.readUser();
    await demo.writeUser(_mergeUser(sourceUser, currentDemo));
    if (demo.readFarm() == null && legacyFarm != null) {
      await demo.writeFarm(legacyFarm);
    }

    await legacy.clear();
  }

  UserProfile _mergeUser(UserProfile legacy, UserProfile? current) {
    if (current == null) return legacy;
    return UserProfile(
      id: current.id,
      phone: current.phone,
      fullName: _preferredName(current.fullName, legacy.fullName),
      preferredLanguage: current.preferredLanguage,
      profilePhotoPath: _nonEmpty(
        current.profilePhotoPath,
        legacy.profilePhotoPath,
      ),
      profilePhotoUrl: _nonEmpty(
        current.profilePhotoUrl,
        legacy.profilePhotoUrl,
      ),
      state: _nonEmpty(current.state, legacy.state),
      district: _nonEmpty(current.district, legacy.district),
      village: _nonEmpty(current.village, legacy.village),
      updatedAt: current.updatedAt ?? legacy.updatedAt,
    );
  }

  String? _preferredName(String? current, String? legacy) =>
      _isCustomName(current)
      ? current
      : (_isCustomName(legacy) ? legacy : current);

  bool _isCustomName(String? value) {
    final name = value?.trim();
    return name != null &&
        name.isNotEmpty &&
        name != 'Demo Farmer' &&
        name != 'Ramesh Kumar';
  }

  T? _nonEmpty<T>(T? current, T? legacy) {
    if (current is String && current.trim().isEmpty) return legacy;
    return current ?? legacy;
  }
}
