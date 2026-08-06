import 'package:flutter/material.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/l10n/l10n.dart';

String languageAvailabilityLabel(BuildContext context, AppLanguage language) =>
    language.isFullyTranslated
    ? context.l10n.languageStatusFullyTranslated
    : context.l10n.languageStatusEnglishFallback;

Future<void> showFallbackLanguageNotice(
  BuildContext context, {
  required LocaleController controller,
  required AppLanguage language,
}) async {
  if (!await controller.consumeFallbackNotice(language) || !context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('fallback_language_notice'),
      content: Text(context.l10n.fallbackLanguageNotice(language.englishName)),
    ),
  );
}
