import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';

class AiChatScope extends InheritedNotifier<AiChatController> {
  const AiChatScope({
    required AiChatController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AiChatController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AiChatScope>();
    assert(scope != null, 'AiChatScope is missing above this context.');
    return scope!.notifier!;
  }
}
