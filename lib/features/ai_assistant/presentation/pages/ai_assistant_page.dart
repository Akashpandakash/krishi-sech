import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/ai_chat_scope.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/ai_response_content.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  AiChatController? _chatController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextController = AiChatScope.of(context);
    if (!identical(nextController, _chatController)) {
      _chatController?.removeListener(_scheduleScrollToBottom);
      _chatController = nextController;
      _chatController!.addListener(_scheduleScrollToBottom);
    }
  }

  @override
  void dispose() {
    _chatController?.removeListener(_scheduleScrollToBottom);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit([String? suggestedQuestion]) async {
    final question = suggestedQuestion ?? _messageController.text;
    final submitted = await AiChatScope.of(context).submit(question);
    if (submitted && suggestedQuestion == null) _messageController.clear();
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showVoiceMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.voiceFeatureComingNext)),
    );
  }

  void _showPhotoPlaceholder() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_search_outlined,
                size: 44,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.photoFeatureComingNext,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.photoFeatureDisclaimer,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AiChatScope.of(context);
    final location = LocationScope.of(context).location;
    final weather = WeatherScope.of(context).weather;

    return SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    key: const Key('ai_assistant_back'),
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.arrow_back),
                  )
                else
                  const CircleAvatar(
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.auto_awesome, color: AppColors.primary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.krishiAiAssistant,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(context.l10n.smartFarmingCompanion),
                      Text(
                        location?.displayName ??
                            context.l10n.locationNotSelected,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('ai_new_chat'),
                  tooltip: context.l10n.newChat,
                  onPressed: controller.newChat,
                  icon: const Icon(Icons.add_comment_outlined),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              key: const Key('ai_chat_list'),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                ResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.aiGreetingUser('Ramesh Kumar'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(context.l10n.aiWelcomeMessage),
                      const SizedBox(height: 12),
                      _ContextCard(
                        location:
                            location?.displayName ??
                            context.l10n.locationNotSelected,
                        weather: weather == null
                            ? context.l10n.weatherUnavailable
                            : context.l10n.aiWeatherContext(
                                weather.temperatureCelsius.round(),
                                weather.humidityPercent,
                                weather.rainProbabilityPercent ?? 0,
                              ),
                      ),
                      const SizedBox(height: 18),
                      if (controller.messages.isEmpty) ...[
                        Text(
                          context.l10n.suggestedQuestions,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestions(context)
                              .map(
                                (question) => ActionChip(
                                  label: Text(question),
                                  onPressed: controller.isTyping
                                      ? null
                                      : () => _submit(question),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      for (final message in controller.messages) ...[
                        const SizedBox(height: 12),
                        _MessageBubble(message: message),
                      ],
                      if (controller.isTyping) ...[
                        const SizedBox(height: 12),
                        const _TypingIndicator(),
                      ],
                      if (controller.canRetry) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: controller.retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.l10n.retryResponse),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  key: const Key('ai_photo_button'),
                  onPressed: _showPhotoPlaceholder,
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  key: const Key('ai_voice_button'),
                  onPressed: _showVoiceMessage,
                  icon: const Icon(Icons.mic_none),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('ai_question_field'),
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: context.l10n.askAboutFarm,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('ai_send_button'),
                  onPressed: controller.isTyping ? null : _submit,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _suggestions(BuildContext context) => [
    context.l10n.suggestIrrigation,
    context.l10n.suggestYellowLeaves,
    context.l10n.suggestFertilizer,
    context.l10n.suggestRain,
    context.l10n.suggestPests,
  ];
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.location, required this.weather});

  final String location;
  final String weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('$location\n$weather')),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == ChatAuthor.user;
    final text = isUser
        ? message.text!
        : localizedAiResponse(context, message.responseType!);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(message.createdAt));
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.lightGreen,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(color: isUser ? Colors.white : null)),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(context.l10n.aiTyping),
          ],
        ),
      ),
    );
  }
}
