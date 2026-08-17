import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/notifications/domain/entities/app_notification.dart';

enum NotificationRemoteFailureType { offline, unauthorized, server }

class NotificationRemoteFailure implements Exception {
  const NotificationRemoteFailure(this.type, [this.message]);
  final NotificationRemoteFailureType type;
  final String? message;
}

typedef NotificationAccessTokenProvider = Future<String?> Function({
  bool forceRefresh,
});

class RemoteAppNotificationDataSource {
  const RemoteAppNotificationDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });

  final String baseUrl;
  final NotificationAccessTokenProvider accessTokenProvider;
  final http.Client? client;

  Future<List<AppNotification>> getNotifications() async {
    final data = await _request('GET', '/api/notifications');
    final items = data?['notifications'];
    if (items is! List<dynamic>) {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.server,
      );
    }
    try {
      return items
          .map((value) => _fromJson(value as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.server,
      );
    }
  }

  Future<void> markAsRead(String id) async {
    await _request('POST', '/api/notifications/${Uri.encodeComponent(id)}/read');
  }

  AppNotification _fromJson(Map<String, dynamic> json) {
    final sentAt = DateTime.tryParse(json['sentAt'] as String? ?? '');
    if (sentAt == null) {
      throw const FormatException('Notification is missing a sent time');
    }
    return AppNotification(
      id: json['id'] as String,
      type: _type(json['category'] as String?),
      title: json['title'] as String,
      message: json['body'] as String? ?? '',
      createdAt: sentAt.toLocal(),
      deepLink: json['deepLink'] as String?,
      isRead: json['read'] as bool? ?? false,
    );
  }

  AppNotificationType _type(String? category) => switch (category) {
    'weather' => AppNotificationType.weather,
    'advisory' => AppNotificationType.advisory,
    'market' => AppNotificationType.market,
    'maintenance' => AppNotificationType.maintenance,
    // An unrecognised category still shows: the operator's own title and body
    // carry the meaning, so only the icon degrades.
    _ => AppNotificationType.general,
  };

  Future<Map<String, dynamic>?> _request(
    String method,
    String path, {
    bool retried = false,
  }) async {
    final token = await accessTokenProvider(forceRefresh: retried);
    if (token == null) {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.unauthorized,
      );
    }
    final requestClient = client ?? http.Client();
    try {
      final request = http.Request(method, Uri.parse(baseUrl).resolve(path))
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });
      final streamed = await requestClient
          .send(request)
          .timeout(AppEnvironment.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 && !retried) {
        return _request(method, path, retried: true);
      }
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            'Notification API $method $path failed with HTTP '
            '${response.statusCode}',
          );
        }
        throw NotificationRemoteFailure(
          response.statusCode == 401
              ? NotificationRemoteFailureType.unauthorized
              : NotificationRemoteFailureType.server,
          _errorMessage(decoded),
        );
      }
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const NotificationRemoteFailure(
          NotificationRemoteFailureType.server,
        );
      }
      final data = decoded['data'];
      return data is Map<String, dynamic> ? data : null;
    } on SocketException {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.offline,
      );
    } on TimeoutException {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.offline,
      );
    } on http.ClientException {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.offline,
      );
    } on FormatException {
      throw const NotificationRemoteFailure(
        NotificationRemoteFailureType.server,
      );
    } finally {
      if (client == null) requestClient.close();
    }
  }

  String? _errorMessage(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final error = decoded['error'];
    return error is Map<String, dynamic> ? error['message'] as String? : null;
  }
}
