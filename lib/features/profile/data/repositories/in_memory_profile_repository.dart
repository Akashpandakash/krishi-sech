import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({UserProfile? user, FarmProfile? farm}) {
    _user = user;
    _farm = farm;
  }
  UserProfile? _user;
  FarmProfile? _farm;
  @override
  Future<UserProfile?> loadUser() async => _user;
  @override
  Future<FarmProfile?> loadFarm() async => _farm;
  @override
  Future<UserProfile> saveUser(UserProfile profile) async => _user = profile;
  @override
  Future<FarmProfile> saveFarm(FarmProfile profile) async => _farm = profile;
}
