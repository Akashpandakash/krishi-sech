import 'package:flutter/material.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class OtpPageArguments {
  const OtpPageArguments({required this.phone, this.debugOtp});
  final String phone;
  final String? debugOtp;
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.arguments});
  final OtpPageArguments arguments;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final debugOtp = widget.arguments.debugOtp;
    if (AppEnvironment.demoModeEnabled &&
        debugOtp != null &&
        RegExp(r'^\d{6}$').hasMatch(debugOtp)) {
      _otpController.text = debugOtp;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showFailure(context.l10n.authInvalidOtp);
      return;
    }
    final controller = AuthScope.of(context);
    final isDemo =
        AppEnvironment.demoModeEnabled &&
        widget.arguments.phone == '+919999999999';
    final verified = isDemo
        ? await controller.verifyDemoOtp(otp)
        : await controller.verifyOtp(widget.arguments.phone, otp);
    if (!mounted) return;
    final failure = controller.failure;
    if (!verified || failure != null) {
      _showFailure(_failureMessage(failure), retry: _verify);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
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
    AuthFailureType.validation =>
      failure?.message ?? context.l10n.authInvalidOtp,
    _ => context.l10n.authRequestFailed,
  };

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.authVerifyOtp)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.authOtpSent(widget.arguments.phone),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (AppEnvironment.demoModeEnabled) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      context.l10n.demoMode,
                      key: const Key('otp_demo_mode_label'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                TextField(
                  key: const Key('otp_field'),
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: context.l10n.authOtpLabel,
                  ),
                ),
                const SizedBox(height: 24),
                AppPressable(
                  enabled: !authController.isLoading,
                  haptic: AppPressableHaptic.medium,
                  child: FilledButton(
                    key: const Key('verify_otp_button'),
                    onPressed: authController.isLoading ? null : _verify,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: authController.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.authVerifyOtp),
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
