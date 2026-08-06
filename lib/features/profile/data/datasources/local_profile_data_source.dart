import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';

class LocalProfileDataSource {
  LocalProfileDataSource(this.preferences, {String? storageNamespace})
    : _userKey = storageNamespace == null
          ? 'cached_user_profile_v1'
          : 'cached_user_profile_v1_$storageNamespace',
      _farmKey = storageNamespace == null
          ? 'cached_farm_profile_v1'
          : 'cached_farm_profile_v1_$storageNamespace';
  final SharedPreferences preferences;
  final String _userKey;
  final String _farmKey;
  UserProfile? readUser() {
    final value = preferences.getString(_userKey);
    return value == null
        ? null
        : UserProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  FarmProfile? readFarm() {
    final value = preferences.getString(_farmKey);
    return value == null
        ? null
        : FarmProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> writeUser(UserProfile value) =>
      preferences.setString(_userKey, jsonEncode(value.toJson()));
  Future<void> writeFarm(FarmProfile value) =>
      preferences.setString(_farmKey, jsonEncode(value.toJson()));
}
