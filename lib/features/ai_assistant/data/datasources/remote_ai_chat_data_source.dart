import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_chat_gateway.dart';

typedef AiAccessTokenProvider = Future<String?> Function({bool forceRefresh});

enum AiChatFailureType { transient, unauthorized, server }

class AiChatFailure implements Exception {
  const AiChatFailure(this.type);
  final AiChatFailureType type;
}

class RemoteAiChatDataSource implements AiChatGateway {
  const RemoteAiChatDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });

  final String baseUrl;
  final AiAccessTokenProvider accessTokenProvider;
  final http.Client? client;

  @override
  Future<AiChatReply> sendMessage({
    required String question,
    required String language,
    required List<ChatMessage> history,
  }) async {
    if (!AppEnvironment.openAiEnabled) {
      throw const AiChatFailure(AiChatFailureType.server);
    }
    AiChatFailure? lastFailure;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _send(
          question: question,
          language: language,
          history: history,
          forceRefresh: lastFailure?.type == AiChatFailureType.unauthorized,
        );
      } on AiChatFailure catch (failure) {
        lastFailure = failure;
        if (attempt == 1 || failure.type == AiChatFailureType.server) rethrow;
      }
    }
    throw lastFailure ?? const AiChatFailure(AiChatFailureType.server);
  }

  Future<AiChatReply> _send({
    required String question,
    required String language,
    required List<ChatMessage> history,
    required bool forceRefresh,
  }) async {
    final token = await accessTokenProvider(forceRefresh: forceRefresh);
    if (token == null) {
      throw const AiChatFailure(AiChatFailureType.unauthorized);
    }
    final requestClient = client ?? http.Client();
    final stopwatch = Stopwatch()..start();
    int? statusCode;
    try {
      final response = await requestClient
          .post(
            Uri.parse(baseUrl).resolve('/api/ai/chat'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'message': question,
              'language': _supportedLanguage(language),
              'history': history.reversed
                  .where((message) => message.text?.trim().isNotEmpty ?? false)
                  .take(12)
                  .toList()
                  .reversed
                  .map(
                    (message) => {
                      'role': message.author == ChatAuthor.user
                          ? 'user'
                          : 'assistant',
                      'content': message.text,
                    },
                  )
                  .toList(),
            }),
          )
          .timeout(AppEnvironment.requestTimeout);
      statusCode = response.statusCode;
      if (response.statusCode == 401) {
        throw const AiChatFailure(AiChatFailureType.unauthorized);
      }
      if ({408, 429, 500, 502, 503, 504}.contains(response.statusCode)) {
        throw const AiChatFailure(AiChatFailureType.transient);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AiChatFailure(AiChatFailureType.server);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const AiChatFailure(AiChatFailureType.server);
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic> || data['reply'] is! String) {
        throw const AiChatFailure(AiChatFailureType.server);
      }
      return AiChatReply(
        text: (data['reply'] as String).trim(),
        model: data['model'] as String?,
      );
    } on SocketException {
      throw const AiChatFailure(AiChatFailureType.transient);
    } on TimeoutException {
      throw const AiChatFailure(AiChatFailureType.transient);
    } on http.ClientException {
      throw const AiChatFailure(AiChatFailureType.transient);
    } on FormatException {
      throw const AiChatFailure(AiChatFailureType.server);
    } finally {
      if (kDebugMode && AppEnvironment.loggingEnabled) {
        debugPrint(
          'AI chat status=${statusCode ?? 'unavailable'} '
          'responseTimeMs=${stopwatch.elapsedMilliseconds}',
        );
      }
      if (client == null) requestClient.close();
    }
  }

  String _supportedLanguage(String language) =>
      const {'bn', 'en', 'hi'}.contains(language) ? language : 'en';
}
