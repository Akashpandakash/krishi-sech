import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/local_ai_chat_history_store.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/remote_ai_chat_data_source.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_chat_gateway.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('posts authenticated chat and retries one transient failure', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.url.path, '/api/ai/chat');
      expect(request.headers['authorization'], 'Bearer access-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['language'], 'bn');
      expect(body['message'], 'আজ কি সেচ দেব?');
      if (requests == 1) return http.Response('', 503);
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': true,
          'data': {'reply': 'আজ বৃষ্টি হলে সেচ স্থগিত রাখুন।', 'model': 'test'},
        })),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final source = RemoteAiChatDataSource(
      baseUrl: 'http://127.0.0.1:3000',
      accessTokenProvider: ({bool forceRefresh = false}) async =>
          'access-token',
      client: client,
    );

    final reply = await source.sendMessage(
      question: 'আজ কি সেচ দেব?',
      language: 'bn',
      history: const [],
    );

    expect(requests, 2);
    expect(reply.text, 'আজ বৃষ্টি হলে সেচ স্থগিত রাখুন।');
  });

  test(
    'controller persists real replies and restores conversation history',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = LocalAiChatHistoryStore(preferences);
      final controller = AiChatController(
        gateway: const _SuccessfulGateway(),
        historyStore: store,
        languageProvider: () => 'hi',
        locationController: LocationController.inMemory(),
        weatherController: WeatherController.inMemory(),
      );

      expect(await controller.submit('आज सिंचाई करनी चाहिए?'), isTrue);
      expect(controller.messages, hasLength(2));
      expect(
        controller.messages.last.text,
        'मिट्टी की नमी जाँचकर सिंचाई करें।',
      );

      final restored = AiChatController(
        gateway: const _SuccessfulGateway(),
        historyStore: store,
        locationController: LocationController.inMemory(),
        weatherController: WeatherController.inMemory(),
      );
      await restored.restoreHistory();

      expect(restored.messages, hasLength(2));
      expect(restored.messages.first.author, ChatAuthor.user);
      expect(restored.messages.last.text, 'मिट्टी की नमी जाँचकर सिंचाई करें।');
    },
  );

  test('AI failure is reported as a failure, never answered locally', () async {
    final controller = AiChatController(
      gateway: const _FailingGateway(),
      languageProvider: () => 'en',
      locationController: LocationController.inMemory(),
      weatherController: WeatherController.inMemory(),
    );

    expect(await controller.submit('Should I irrigate today?'), isFalse);
    expect(controller.isTyping, isFalse);
    expect(controller.canRetry, isTrue);
    // The turn is marked failed and carries no substituted advice.
    expect(controller.messages.last.isError, isTrue);
    expect(controller.messages.last.text, isNull);
  });

  test('retry replaces the failed turn instead of stacking errors', () async {
    final gateway = _FlakyGateway();
    final controller = AiChatController(
      gateway: gateway,
      languageProvider: () => 'en',
      locationController: LocationController.inMemory(),
      weatherController: WeatherController.inMemory(),
    );

    expect(await controller.submit('Should I irrigate today?'), isFalse);
    expect(controller.messages, hasLength(2));

    expect(await controller.retry(), isTrue);
    expect(controller.messages, hasLength(2));
    expect(controller.messages.last.isError, isFalse);
    expect(controller.messages.last.text, 'Check soil moisture first.');
    expect(controller.canRetry, isFalse);
  });
}

class _SuccessfulGateway implements AiChatGateway {
  const _SuccessfulGateway();

  @override
  Future<AiChatReply> sendMessage({
    required String question,
    required String language,
    required List<ChatMessage> history,
  }) async {
    expect(language, 'hi');
    return const AiChatReply(text: 'मिट्टी की नमी जाँचकर सिंचाई करें।');
  }
}

class _FailingGateway implements AiChatGateway {
  const _FailingGateway();

  @override
  Future<AiChatReply> sendMessage({
    required String question,
    required String language,
    required List<ChatMessage> history,
  }) => throw const AiChatFailure(AiChatFailureType.transient);
}

/// Fails once, then succeeds — the shape a transient outage actually has.
class _FlakyGateway implements AiChatGateway {
  int calls = 0;

  @override
  Future<AiChatReply> sendMessage({
    required String question,
    required String language,
    required List<ChatMessage> history,
  }) async {
    calls++;
    if (calls == 1) throw Exception('upstream unavailable');
    return const AiChatReply(text: 'Check soil moisture first.');
  }
}
