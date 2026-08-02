import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class OnboardingSecondPlaceholderPage extends StatelessWidget {
  const OnboardingSecondPlaceholderPage({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final horizontalPadding = constraints.maxWidth < 360 ? 14.0 : 20.0;

            return Stack(
              children: [
                const Positioned(
                  top: -30,
                  left: -34,
                  child: _BlurredLeaves(size: 132),
                ),
                const Positioned(
                  top: 116,
                  right: -24,
                  child: _BlurredLeaves(size: 78),
                ),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            0,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: const Key('onboarding_second_skip'),
                              onPressed: () => _openLogin(context),
                              label: Text(context.l10n.skip),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              children: [
                                const _Heading(),
                                SizedBox(height: compact ? 10 : 14),
                                Text(
                                  context.l10n.onboarding2Description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                ),
                                SizedBox(height: compact ? 16 : 22),
                                _FarmerVisual(compact: compact),
                                SizedBox(height: compact ? 16 : 22),
                                const _FeatureCard(),
                                const SizedBox(height: 14),
                                const _AiAssistantCard(),
                                const SizedBox(height: 16),
                                _BottomNavigation(
                                  onBack: () {
                                    Navigator.of(context).pushReplacementNamed(
                                      AppRoutes.onboarding,
                                    );
                                  },
                                  onNext: () {
                                    Navigator.of(context).pushReplacementNamed(
                                      AppRoutes.onboardingThird,
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
      height: 1.05,
    );

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.l10n.onboarding2HeadingLine1,
            style: style?.copyWith(color: AppColors.primaryDark),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.l10n.onboarding2HeadingLine2,
            style: style?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 46,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _FarmerVisual extends StatelessWidget {
  const _FarmerVisual({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compact ? 1.72 : 1.62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/splash_farmland.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    AppColors.primaryDark.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.3,
                heightFactor: 0.78,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2).withValues(alpha: 0.96),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(80),
                    ),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(top: 14, right: 14, child: _PlantDoctorCard()),
          ],
        ),
      ),
    );
  }
}

class _PlantDoctorCard extends StatelessWidget {
  const _PlantDoctorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lightGreen,
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.plantDoctor,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                context.l10n.cropLooksHealthy,
                style: const TextStyle(fontSize: 8.5, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard();

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        Icons.camera_alt_outlined,
        context.l10n.diseaseDetection,
        context.l10n.scanCrops,
      ),
      _FeatureData(
        Icons.cloud_outlined,
        context.l10n.weatherAlerts,
        context.l10n.stayPrepared,
      ),
      _FeatureData(
        Icons.water_drop_outlined,
        context.l10n.irrigationAdvice,
        context.l10n.saveWater,
      ),
      _FeatureData(
        Icons.science_outlined,
        context.l10n.fertilizerGuide,
        context.l10n.growBetterShort,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features
            .map((feature) => Expanded(child: _FeatureColumn(data: feature)))
            .toList(),
      ),
    );
  }
}

class _FeatureColumn extends StatelessWidget {
  const _FeatureColumn({required this.data});

  final _FeatureData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.lightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(height: 7),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white24,
            child: Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.aiAssistant247,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.aiAssistant247Subtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_outlined, color: Colors.white70),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          key: const Key('onboarding_second_back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 19),
          label: Text(context.l10n.back),
        ),
        const Spacer(),
        const _PageIndicators(activeIndex: 1),
        const Spacer(),
        FilledButton.icon(
          key: const Key('onboarding_second_next'),
          onPressed: onNext,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          ),
          label: Text(context.l10n.next),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        ),
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final active = index == activeIndex;
        return Container(
          width: active ? 22 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _BlurredLeaves extends StatelessWidget {
  const _BlurredLeaves({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
      child: Opacity(
        opacity: 0.28,
        child: Icon(Icons.eco_rounded, size: size, color: AppColors.primary),
      ),
    );
  }
}

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
