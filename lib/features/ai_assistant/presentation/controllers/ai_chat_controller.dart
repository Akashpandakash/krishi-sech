import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/data/datasources/local_ai_chat_history_store.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_chat_gateway.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';

class AiChatController extends ChangeNotifier {
  AiChatController({
    required this.gateway,
    required this.locationController,
    required this.weatherController,
    this.historyStore,
    this.languageProvider,
  });

  /// The only source of answers. There is deliberately no local fallback: a
  /// keyword-matched canned reply presented as the assistant's answer is
  /// advice the farmer did not actually receive, and acting on it could cost
  /// them a crop.
  final AiChatGateway gateway;
  final LocationController locationController;
  final WeatherController weatherController;
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
      final response = await gateway.sendMessage(
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
    } catch (_) {
      // The turn is recorded as a failure and the question is held for retry.
      // Nothing is invented to fill the gap.
      _failedQuestion = trimmed;
      _messages.add(
        ChatMessage(
          author: ChatAuthor.assistant,
          isError: true,
          createdAt: DateTime.now(),
        ),
      );
      await _saveHistory();
      return false;
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<bool> retry() async {
    final question = _failedQuestion;
    if (question == null) return false;
    // Drop the failed turn and the question that produced it, so a successful
    // retry leaves one clean exchange rather than a stack of failures.
    if (_messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
      if (_messages.isNotEmpty && _messages.last.author == ChatAuthor.user) {
        _messages.removeLast();
      }
    }
    _failedQuestion = null;
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
