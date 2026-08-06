import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/local_profile_data_source.dart';

class LocalOnlyProfileRepository implements ProfileRepository {
  const LocalOnlyProfileRepository(this.local);

  final LocalProfileDataSource local;

  @override
  Future<UserProfile?> loadUser() async => local.readUser();

  @override
  Future<UserProfile> saveUser(UserProfile profile) async {
    await local.writeUser(profile);
    return profile;
  }

  @override
  Future<FarmProfile?> loadFarm() async => local.readFarm();

  @override
  Future<FarmProfile> saveFarm(FarmProfile profile) async {
    await local.writeFarm(profile);
    return profile;
  }
}
