import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/core/localization/fallback_language_notice.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  AppLanguage _selectedLanguage = AppLanguageCatalog.fromCode('bn');
  String _query = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedLanguage = AppLanguageCatalog.fromCode(
        LocaleScope.of(context).locale.languageCode,
      );
      _initialized = true;
    }
  }

  Future<void> _openLogin() async {
    await LocaleScope.of(context).setLocale(_selectedLanguage.locale);
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = AppLanguageCatalog.search(_query);
    return Scaffold(
      backgroundColor: AppColors.paleGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    4,
                    horizontalPadding,
                    20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('language_skip'),
                              onPressed: _openLogin,
                              child: Text(context.l10n.skip),
                            ),
                          ),
                          _TopIllustration(compact: compact),
                          SizedBox(height: compact ? 14 : 22),
                          Text(
                            context.l10n.languageTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.languageSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: compact ? 20 : 30),
                          TextField(
                            key: const Key('language_search'),
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              hintText: context.l10n.searchLanguages,
                              prefixIcon: const Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final language in languages)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LanguageCard(
                                language: language,
                                selected:
                                    language.code == _selectedLanguage.code,
                                onTap: () async {
                                  setState(() {
                                    _selectedLanguage = language;
                                  });
                                  final localeController = LocaleScope.of(
                                    context,
                                  );
                                  await localeController.setLocale(
                                    language.locale,
                                  );
                                  if (!context.mounted) return;
                                  await showFallbackLanguageNotice(
                                    context,
                                    controller: localeController,
                                    language: language,
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: compact ? 12 : 20),
                          AppPressable(
                            haptic: AppPressableHaptic.medium,
                            child: FilledButton.icon(
                              key: const Key('language_continue'),
                              onPressed: _openLogin,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              label: Text(
                                context.l10n.continueLabel,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                          ),
                          SizedBox(height: compact ? 14 : 22),
                          const _BottomIllustration(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightGreen : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: AppPressable(
        key: Key('language_${language.code}'),
        haptic: AppPressableHaptic.selection,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : AppColors.primary.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.englishName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: language.textDirection,
                      child: Text(
                        language.nativeName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      languageAvailabilityLabel(context, language),
                      key: Key('language_status_${language.code}'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: language.isFullyTranslated
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIllustration extends StatelessWidget {
  const _TopIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 118 : 150,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: compact ? 220 : 270,
              height: compact ? 68 : 82,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.elliptical(150, 70),
                ),
              ),
            ),
          ),
          Icon(
            Icons.agriculture_rounded,
            size: compact ? 105 : 132,
            color: AppColors.primary,
          ),
          Positioned(
            left: 28,
            bottom: 10,
            child: Icon(
              Icons.grass,
              size: compact ? 54 : 68,
              color: AppColors.primaryDark,
            ),
          ),
          Positioned(
            right: 35,
            bottom: 12,
            child: Icon(
              Icons.eco_rounded,
              size: compact ? 48 : 62,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomIllustration extends StatelessWidget {
  const _BottomIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.grass, color: AppColors.primary, size: 42),
              Icon(Icons.eco_rounded, color: AppColors.primaryDark, size: 50),
              Icon(Icons.grass, color: AppColors.primary, size: 38),
              Icon(Icons.local_florist, color: AppColors.primaryDark, size: 44),
            ],
          ),
        ],
      ),
    );
  }
}
