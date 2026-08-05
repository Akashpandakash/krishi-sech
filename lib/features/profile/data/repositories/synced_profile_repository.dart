import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/local_profile_data_source.dart';
import '../datasources/remote_profile_data_source.dart';

class SyncedProfileRepository implements ProfileRepository {
  SyncedProfileRepository(this.local, this.remote);
  final LocalProfileDataSource local;
  final RemoteProfileDataSource remote;
  @override
  Future<UserProfile?> loadUser() async {
    try {
      final value = await remote.getUser();
      final cached = local.readUser();
      final merged = UserProfile(
        id: value.id,
        phone: value.phone,
        fullName: value.fullName,
        preferredLanguage: value.preferredLanguage,
        profilePhotoPath: cached?.profilePhotoPath,
        profilePhotoUrl: value.profilePhotoUrl,
        state: value.state,
        district: value.district,
        village: value.village,
        updatedAt: value.updatedAt,
      );
      await local.writeUser(merged);
      return merged;
    } on ProfileFailure catch (e) {
      final cached = local.readUser();
      if (cached != null &&
          (e.type == ProfileFailureType.offline ||
              e.type == ProfileFailureType.timeout)) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> saveUser(UserProfile profile) async {
    await local.writeUser(profile);
    final remoteValue = await remote.updateUser(profile);
    final merged = UserProfile(
      id: remoteValue.id,
      phone: remoteValue.phone,
      fullName: remoteValue.fullName,
      preferredLanguage: remoteValue.preferredLanguage,
      profilePhotoPath: profile.profilePhotoPath,
      profilePhotoUrl: remoteValue.profilePhotoUrl,
      state: remoteValue.state,
      district: remoteValue.district,
      village: remoteValue.village,
      updatedAt: remoteValue.updatedAt,
    );
    await local.writeUser(merged);
    return merged;
  }

  @override
  Future<FarmProfile?> loadFarm() async {
    try {
      final value = await remote.getFarm();
      if (value != null) {
        await local.writeFarm(value);
      }
      return value ?? local.readFarm();
    } on ProfileFailure catch (e) {
      final cached = local.readFarm();
      if (cached != null &&
          (e.type == ProfileFailureType.offline ||
              e.type == ProfileFailureType.timeout)) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<FarmProfile> saveFarm(FarmProfile profile) async {
    await local.writeFarm(profile);
    final value = await remote.updateFarm(profile);
    await local.writeFarm(value);
    return value;
  }
}
