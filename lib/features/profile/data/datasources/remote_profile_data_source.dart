import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/farm_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

typedef ProfileTokenProvider = Future<String?> Function({bool forceRefresh});

class RemoteProfileDataSource {
  const RemoteProfileDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });
  final String baseUrl;
  final ProfileTokenProvider accessTokenProvider;
  final http.Client? client;
  Future<UserProfile> getUser() async =>
      UserProfile.fromJson(await _request('/api/profile'));
  Future<UserProfile> updateUser(UserProfile value) async =>
      UserProfile.fromJson(
        await _request(
          '/api/profile',
          method: 'PUT',
          body: {
            'name': value.fullName,
            'preferredLanguage': value.preferredLanguage,
            'profilePhotoUrl': value.profilePhotoUrl,
            'state': value.state,
            'district': value.district,
            'village': value.village,
          },
        ),
      );
  Future<FarmProfile?> getFarm() async {
    final data = await _request('/api/profile/farm', allowNull: true);
    return data.isEmpty ? null : FarmProfile.fromJson(data);
  }

  Future<FarmProfile> updateFarm(FarmProfile value) async =>
      FarmProfile.fromJson(
        await _request(
          '/api/profile/farm',
          method: 'PUT',
          body: value.toJson()..remove('updatedAt'),
        ),
      );
  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool allowNull = false,
  }) async {
    final token = await accessTokenProvider(forceRefresh: false);
    if (token == null) {
      throw const ProfileFailure(ProfileFailureType.unauthorized);
    }
    final requestClient = client ?? http.Client();
    try {
      Future<http.Response> send(String accessToken) {
        final uri = Uri.parse(baseUrl).resolve(path);
        final headers = {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          if (body != null) 'Content-Type': 'application/json',
        };
        return method == 'PUT'
            ? requestClient.put(uri, headers: headers, body: jsonEncode(body))
            : requestClient.get(uri, headers: headers);
      }

      var response = await send(token).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) {
        final fresh = await accessTokenProvider(forceRefresh: true);
        if (fresh != null) {
          response = await send(fresh).timeout(const Duration(seconds: 15));
        }
      }
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProfileFailure(
          response.statusCode == 401
              ? ProfileFailureType.unauthorized
              : response.statusCode == 400
              ? ProfileFailureType.validation
              : ProfileFailureType.server,
        );
      }
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data == null && allowNull) return {};
      if (data is! Map<String, dynamic>) {
        throw const ProfileFailure(ProfileFailureType.server);
      }
      return data;
    } on SocketException {
      throw const ProfileFailure(ProfileFailureType.offline);
    } on TimeoutException {
      throw const ProfileFailure(ProfileFailureType.timeout);
    } on http.ClientException {
      throw const ProfileFailure(ProfileFailureType.offline);
    } on FormatException {
      throw const ProfileFailure(ProfileFailureType.server);
    } finally {
      if (client == null) requestClient.close();
    }
  }
}
