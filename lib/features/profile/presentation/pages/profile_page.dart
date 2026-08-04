import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = LocaleScope.of(context);
    final authController = AuthScope.maybeOf(context);
    final currentLanguageName = switch (localeController.locale.languageCode) {
      'hi' => context.l10n.hindi,
      'en' => context.l10n.english,
      _ => context.l10n.bangla,
    };

    return SafeArea(
      child: SingleChildScrollView(
        child: ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.profile,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.person, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                'Ramesh Kumar',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '+91 98765 43210 • Jaipur, Rajasthan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline,
                      title: context.l10n.personalDetails,
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 64),
                    _ProfileTile(
                      icon: Icons.location_on_outlined,
                      title: context.l10n.farmDetails,
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 64),
                    _ProfileTile(
                      icon: Icons.language,
                      title: context.l10n.language,
                      subtitle: currentLanguageName,
                      onTap: () => _showLanguagePicker(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _ProfileTile(
                      icon: Icons.help_outline,
                      title: context.l10n.helpSupport,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppPressable(
                enabled: !(authController?.isLoading ?? false),
                haptic: AppPressableHaptic.medium,
                child: OutlinedButton.icon(
                  onPressed: authController?.isLoading == true
                      ? null
                      : () async {
                          await authController?.logout();
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (_) => false,
                          );
                        },
                  icon: authController?.isLoading == true
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: Text(context.l10n.logOut),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final controller = LocaleScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final options = [
          (const Locale('bn'), sheetContext.l10n.bangla),
          (const Locale('hi'), sheetContext.l10n.hindi),
          (const Locale('en'), sheetContext.l10n.english),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.l10n.languageTitle,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final option in options)
                  AppPressable(
                    haptic: AppPressableHaptic.selection,
                    onTap: () async {
                      await controller.setLocale(option.$1);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: ListTile(
                      leading: const Icon(Icons.translate),
                      title: Text(option.$2),
                      trailing:
                          controller.locale.languageCode ==
                              option.$1.languageCode
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
