import 'package:flutter/material.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/login/presentation/pages/otp_page.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _demoPhone = '+919999999999';
  static const _demoOtp = '123456';

  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      _showFailure(context.l10n.authInvalidPhone);
      return;
    }
    final phone = '+91$digits';
    if (AppEnvironment.demoModeEnabled && phone == _demoPhone) {
      _isSubmitting = false;
      AppRouter.navigatorKey.currentState?.pushNamed(
        AppRoutes.otp,
        arguments: const OtpPageArguments(
          phone: _demoPhone,
          debugOtp: _demoOtp,
        ),
      );
      return;
    }
    _isSubmitting = true;
    final controller = AuthScope.of(context);
    try {
      final dispatch = await controller.sendOtp(phone);
      final failure = controller.failure;
      if (dispatch == null || failure != null) {
        if (mounted) {
          _showFailure(_failureMessage(failure), retry: _continue);
        }
        return;
      }
      AppRouter.navigatorKey.currentState?.pushNamed(
        AppRoutes.otp,
        arguments: OtpPageArguments(phone: phone, debugOtp: dispatch.debugOtp),
      );
    } finally {
      if (mounted) _isSubmitting = false;
    }
  }

  void _showFailure(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: retry == null
            ? null
            : SnackBarAction(label: context.l10n.retry, onPressed: retry),
      ),
    );
  }

  String _failureMessage(AuthFailure? failure) => switch (failure?.type) {
    AuthFailureType.offline => context.l10n.authOffline,
    AuthFailureType.timeout => context.l10n.authTimeout,
    AuthFailureType.validation => context.l10n.authRequestFailed,
    _ => context.l10n.authRequestFailed,
  };

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  context.l10n.loginWelcome,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (AppEnvironment.demoModeEnabled) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      context.l10n.demoMode,
                      key: const Key('demo_mode_label'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 42),
                Text(
                  context.l10n.mobileNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: '',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: '+91  ',
                    hintText: context.l10n.enterMobileNumber,
                  ),
                ),
                const SizedBox(height: 24),
                AppPressable(
                  enabled: !authController.isLoading,
                  haptic: AppPressableHaptic.medium,
                  child: FilledButton(
                    onPressed: authController.isLoading ? null : _continue,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authController.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.continueLabel),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  context.l10n.termsNotice,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
