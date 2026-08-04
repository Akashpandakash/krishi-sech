import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';

class AiChatReply {
  const AiChatReply({required this.text, this.model});

  final String text;
  final String? model;
}

abstract interface class AiChatGateway {
  Future<AiChatReply> sendMessage({
    required String question,
    required String language,
    required List<ChatMessage> history,
  });
}
