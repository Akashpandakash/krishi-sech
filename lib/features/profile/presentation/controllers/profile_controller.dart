import 'package:flutter/foundation.dart';
import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(
    this.repository, {
    bool demoMode = false,
    this.demoRepository,
    UserProfile? demoUser,
    FarmProfile? demoFarm,
  }) {
    _demoMode = demoMode;
    if (_demoMode) _setDemoProfile(user: demoUser, farm: demoFarm);
  }
  final ProfileRepository repository;
  final ProfileRepository? demoRepository;
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  UserProfile? user;
  FarmProfile? farm;
  bool isLoading = false;
  ProfileFailure? failure;
  String get greetingName =>
      user?.displayName ?? (demoMode ? 'Ramesh Kumar' : 'Farmer');
  Future<void> load() async {
    if (_demoMode) return;
    await _run(() async {
      user = await repository.loadUser();
      farm = await repository.loadFarm();
    });
  }

  Future<void> enterDemoMode() async {
    _demoMode = true;
    failure = null;
    _setDemoProfile();
    notifyListeners();
    final demo = demoRepository;
    if (demo == null) return;
    try {
      final savedUser = await demo.loadUser();
      final savedFarm = await demo.loadFarm();
      if (!_demoMode) return;
      _setDemoProfile(user: savedUser, farm: savedFarm);
      notifyListeners();
    } catch (_) {
      // Demo cache is optional; retain the safe seed profile if it is invalid.
    }
  }

  void clearSession() {
    _demoMode = false;
    user = null;
    farm = null;
    failure = null;
    notifyListeners();
  }

  Future<bool> saveUser(UserProfile value) async {
    if (_demoMode) {
      final demo = demoRepository;
      if (demo == null) {
        user = value;
        notifyListeners();
        return true;
      }
      await _run(() async => user = await demo.saveUser(value));
      return failure == null;
    }
    await _run(() async => user = await repository.saveUser(value));
    return failure == null;
  }

  Future<bool> saveProfilePhoto(String path) async {
    final current = user;
    if (current == null || isLoading) return false;
    final value = UserProfile(
      id: current.id,
      phone: current.phone,
      fullName: current.fullName,
      preferredLanguage: current.preferredLanguage,
      profilePhotoPath: path,
      profilePhotoUrl: current.profilePhotoUrl,
      state: current.state,
      district: current.district,
      village: current.village,
      updatedAt: current.updatedAt,
    );

    user = value;
    notifyListeners();
    if (_demoMode) {
      final demo = demoRepository;
      if (demo == null) return true;
      await _run(() async => user = await demo.saveUser(value));
      return failure == null;
    }
    await _run(() async => user = await repository.saveUser(value));
    return failure == null;
  }

  Future<bool> saveFarm(FarmProfile value) async {
    if (_demoMode) {
      final demo = demoRepository;
      if (demo == null) {
        farm = value;
        notifyListeners();
        return true;
      }
      await _run(() async => farm = await demo.saveFarm(value));
      return failure == null;
    }
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

  void _setDemoProfile({UserProfile? user, FarmProfile? farm}) {
    this.user =
        user ??
        const UserProfile(
          id: 'demo-farmer',
          phone: '+919999999999',
          fullName: 'Ramesh Kumar',
          preferredLanguage: 'en',
        );
    this.farm = farm;
  }
}
