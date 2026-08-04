import 'dart:convert';

import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAiChatHistoryStore {
  const LocalAiChatHistoryStore(this.preferences);

  static const historyKey = 'ai_chat_history_json';
  final SharedPreferences preferences;

  Future<List<ChatMessage>> load() async {
    final raw = preferences.getString(historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ChatMessage> messages) async {
    await preferences.setString(
      historyKey,
      jsonEncode(messages.map(_toJson).toList()),
    );
  }

  Future<void> clear() async {
    await preferences.remove(historyKey);
  }

  Map<String, dynamic> _toJson(ChatMessage message) => {
    'author': message.author.name,
    'createdAt': message.createdAt.toIso8601String(),
    'text': message.text,
    'responseType': message.responseType?.name,
  };

  ChatMessage _fromJson(Map<String, dynamic> json) => ChatMessage(
    author: ChatAuthor.values.byName(json['author'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    text: json['text'] as String?,
    responseType: json['responseType'] == null
        ? null
        : AiResponseType.values.byName(json['responseType'] as String),
  );
}
