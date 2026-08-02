import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/domain/repositories/ai_response_repository.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';

class AiChatController extends ChangeNotifier {
  AiChatController({
    required this.repository,
    required this.locationController,
    required this.weatherController,
  });

  final AiResponseRepository repository;
  final LocationController locationController;
  final WeatherController weatherController;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _failedQuestion;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get canRetry => _failedQuestion != null;

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

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
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
      return true;
    } catch (_) {
      _failedQuestion = trimmed;
      return false;
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
  }
}
