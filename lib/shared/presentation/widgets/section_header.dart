import 'package:flutter/material.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          AppPressable(
            enabled: onAction != null,
            haptic: AppPressableHaptic.selection,
            child: TextButton(onPressed: onAction, child: Text(action!)),
          ),
      ],
    );
  }
}
