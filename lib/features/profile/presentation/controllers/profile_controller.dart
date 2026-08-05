import 'package:flutter/foundation.dart';
import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this.repository, {this.demoMode = false});
  final ProfileRepository repository;
  final bool demoMode;
  UserProfile? user;
  FarmProfile? farm;
  bool isLoading = false;
  ProfileFailure? failure;
  String get greetingName =>
      demoMode ? 'Ramesh Kumar' : (user?.displayName ?? 'Farmer');
  Future<void> load() => _run(() async {
    user = await repository.loadUser();
    farm = await repository.loadFarm();
  });
  Future<bool> saveUser(UserProfile value) async {
    await _run(() async => user = await repository.saveUser(value));
    return failure == null;
  }

  Future<bool> saveFarm(FarmProfile value) async {
    await _run(() async => farm = await repository.saveFarm(value));
    return failure == null;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      await action();
    } on ProfileFailure catch (value) {
      failure = value;
    } catch (_) {
      failure = const ProfileFailure(ProfileFailureType.server);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
