enum ChatAuthor { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.createdAt,
    this.text,
    this.isError = false,
  });

  final ChatAuthor author;
  final DateTime createdAt;
  final String? text;

  /// Marks an assistant turn where the request failed and no answer was
  /// produced. The transcript keeps the turn so the farmer can see their
  /// question went unanswered, and the UI renders it as a failure rather than
  /// substituting advice the assistant never gave.
  final bool isError;
}
