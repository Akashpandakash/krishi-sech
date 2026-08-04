import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/smart_dashboard/domain/entities/smart_recommendation_snapshot.dart';

typedef DashboardAccessTokenProvider =
    Future<String?> Function({bool forceRefresh});

class RemoteSmartRecommendationDataSource {
  const RemoteSmartRecommendationDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });
  final String baseUrl;
  final DashboardAccessTokenProvider accessTokenProvider;
  final http.Client? client;
  Future<SmartRecommendationSnapshot> fetch({required String language}) async {
    final token = await accessTokenProvider(forceRefresh: false);
    if (token == null) throw const HttpException('Authentication required');
    final requestClient = client ?? http.Client();
    try {
      final values = await Future.wait([
        _capture(
          _get(
            requestClient,
            '/api/irrigation/recommendation',
            language,
            token,
          ),
        ),
        _capture(
          _get(
            requestClient,
            '/api/fertilizer/recommendation',
            language,
            token,
          ),
        ),
      ]).timeout(AppEnvironment.requestTimeout);
      final irrigationJson = values[0];
      final fertilizerJson = values[1];
      return SmartRecommendationSnapshot(
        irrigation: irrigationJson == null
            ? null
            : IrrigationSummary.fromJson(irrigationJson),
        fertilizer: fertilizerJson == null
            ? null
            : FertilizerSummary.fromJson(fertilizerJson),
        irrigationFailed: irrigationJson == null,
        fertilizerFailed: fertilizerJson == null,
      );
    } finally {
      if (client == null) {
        requestClient.close();
      }
    }
  }

  Future<Map<String, dynamic>?> _capture(
    Future<Map<String, dynamic>> request,
  ) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _get(
    http.Client client,
    String path,
    String language,
    String token,
  ) async {
    final safeLanguage = const {'bn', 'en', 'hi'}.contains(language)
        ? language
        : 'en';
    final uri = Uri.parse(
      baseUrl,
    ).resolve(path).replace(queryParameters: {'language': safeLanguage});
    final response = await client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Recommendation request failed', uri: uri);
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> ||
        body['success'] != true ||
        body['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid recommendation response');
    }
    return body['data'] as Map<String, dynamic>;
  }
}
