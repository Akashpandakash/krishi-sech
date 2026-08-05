import '../entities/farm_profile.dart';
import '../entities/user_profile.dart';

enum ProfileFailureType { offline, timeout, unauthorized, validation, server }

class ProfileFailure implements Exception {
  const ProfileFailure(this.type, [this.message]);
  final ProfileFailureType type;
  final String? message;
}

abstract interface class ProfileRepository {
  Future<UserProfile?> loadUser();
  Future<UserProfile> saveUser(UserProfile profile);
  Future<FarmProfile?> loadFarm();
  Future<FarmProfile> saveFarm(FarmProfile profile);
}
