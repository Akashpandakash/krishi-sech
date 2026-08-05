import 'package:flutter/foundation.dart';
import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this.repository, {bool demoMode = false}) {
    _demoMode = demoMode;
    if (_demoMode) _setDemoProfile();
  }
  final ProfileRepository repository;
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  UserProfile? user;
  FarmProfile? farm;
  bool isLoading = false;
  ProfileFailure? failure;
  String get greetingName =>
      demoMode ? 'Ramesh Kumar' : (user?.displayName ?? 'Farmer');
  Future<void> load() async {
    if (_demoMode) return;
    await _run(() async {
      user = await repository.loadUser();
      farm = await repository.loadFarm();
    });
  }

  void enterDemoMode() {
    _demoMode = true;
    failure = null;
    _setDemoProfile();
    notifyListeners();
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
      user = value;
      notifyListeners();
      return true;
    }
    await _run(() async => user = await repository.saveUser(value));
    return failure == null;
  }

  Future<bool> saveFarm(FarmProfile value) async {
    if (_demoMode) {
      farm = value;
      notifyListeners();
      return true;
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

  void _setDemoProfile() {
    user = const UserProfile(
      id: 'demo-farmer',
      phone: '+919999999999',
      fullName: 'Ramesh Kumar',
      preferredLanguage: 'en',
    );
    farm = null;
  }
}
