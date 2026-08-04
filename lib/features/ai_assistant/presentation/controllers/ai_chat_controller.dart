import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/local_ai_chat_history_store.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_chat_gateway.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_response_repository.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';

class AiChatController extends ChangeNotifier {
  AiChatController({
    required this.repository,
    required this.locationController,
    required this.weatherController,
    this.gateway,
    this.historyStore,
    this.languageProvider,
  });

  final AiResponseRepository repository;
  final LocationController locationController;
  final WeatherController weatherController;
  final AiChatGateway? gateway;
  final LocalAiChatHistoryStore? historyStore;
  final String Function()? languageProvider;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _failedQuestion;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get canRetry => _failedQuestion != null;

  Future<void> restoreHistory() async {
    final stored = await historyStore?.load();
    if (stored == null) return;
    _messages
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  Future<bool> submit(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || _isTyping) return false;

    _messages.add(
      ChatMessage(
        author: ChatAuthor.user,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    _isTyping = true;
    _failedQuestion = null;
    notifyListeners();
    await _saveHistory();

    try {
      if (gateway != null) {
        final response = await gateway!.sendMessage(
          question: trimmed,
          language: languageProvider?.call() ?? 'en',
          history: _messages.length > 1
              ? _messages.sublist(0, _messages.length - 1)
              : const [],
        );
        _messages.add(
          ChatMessage(
            author: ChatAuthor.assistant,
            text: response.text,
            createdAt: DateTime.now(),
          ),
        );
        await _saveHistory();
        return true;
      }
      final response = await repository.generateResponse(
        question: trimmed,
        location: locationController.location,
        weather: weatherController.weather,
      );
      _messages.add(
        ChatMessage(
          author: ChatAuthor.assistant,
          responseType: response,
          createdAt: DateTime.now(),
        ),
      );
      await _saveHistory();
      return true;
    } catch (_) {
      _failedQuestion = trimmed;
      final fallback = await repository.generateResponse(
        question: trimmed,
        location: locationController.location,
        weather: weatherController.weather,
      );
      _messages.add(
        ChatMessage(
          author: ChatAuthor.assistant,
          responseType: fallback,
          createdAt: DateTime.now(),
        ),
      );
      await _saveHistory();
      return true;
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<bool> retry() async {
    final question = _failedQuestion;
    if (question == null) return false;
    return submit(question);
  }

  void newChat() {
    _messages.clear();
    _failedQuestion = null;
    _isTyping = false;
    notifyListeners();
    historyStore?.clear();
  }

  Future<void> _saveHistory() async => historyStore?.save(_messages);
}
