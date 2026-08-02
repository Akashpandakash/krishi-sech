import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _navigationTimer = Timer(const Duration(seconds: 3), _openOnboarding);
  }

  void _openOnboarding() {
    if (mounted) {
      final hasSavedLocale = LocaleScope.of(context).hasSavedLocale;
      Navigator.of(context).pushReplacementNamed(
        hasSavedLocale ? AppRoutes.login : AppRoutes.onboarding,
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF2FAF3)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 650;
              final contentWidth = math.min(constraints.maxWidth, 720.0);
              final farmlandHeight =
                  constraints.maxHeight * (isCompact ? 0.44 : 0.48);

              return FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  children: [
                    const Positioned(
                      top: -18,
                      left: -20,
                      child: _CornerLeaves(turns: -0.08),
                    ),
                    const Positioned(
                      top: -20,
                      right: -22,
                      child: _CornerLeaves(turns: 0.28),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          children: [
                            Expanded(
                              child: _BrandContent(isCompact: isCompact),
                            ),
                            SizedBox(
                              height: farmlandHeight,
                              child: const _FarmlandPanel(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandContent extends StatelessWidget {
  const _BrandContent({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isCompact ? 18 : 34, 24, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: _KrishiLogo(size: isCompact ? 104 : 132)),
          SizedBox(height: isCompact ? 14 : 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              context.l10n.splashTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.8,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            context.l10n.splashTagline,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KrishiLogo extends StatelessWidget {
  const _KrishiLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          Icon(Icons.eco_rounded, size: size * 0.56, color: AppColors.primary),
          Positioned(
            bottom: size * 0.12,
            right: size * 0.08,
            child: Container(
              width: size * 0.31,
              height: size * 0.31,
              decoration: const BoxDecoration(
                color: Color(0xFFDAF0FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: size * 0.2,
                color: const Color(0xFF2387C9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmlandPanel extends StatelessWidget {
  const _FarmlandPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: Image.asset(
            'assets/images/splash_farmland.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.3, 0.72, 1],
              colors: [
                const Color(0xFFF2FAF3),
                Colors.white.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.52),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 22),
            child: _LoadingContent(),
          ),
        ),
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 30,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.8,
          ),
        ),
        const SizedBox(height: 11),
        Text(
          context.l10n.loading,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _CornerLeaves extends StatelessWidget {
  const _CornerLeaves({required this.turns});

  final double turns;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi * 2 * turns,
      child: SizedBox(
        width: 118,
        height: 104,
        child: Stack(
          children: [
            Positioned(
              left: 9,
              top: 13,
              child: Transform.rotate(
                angle: -0.5,
                child: const Icon(
                  Icons.eco,
                  size: 74,
                  color: Color(0xFFB9DEBE),
                ),
              ),
            ),
            Positioned(
              right: 3,
              bottom: 0,
              child: Transform.rotate(
                angle: 0.42,
                child: const Icon(
                  Icons.eco,
                  size: 62,
                  color: Color(0xFFD5ECD8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
