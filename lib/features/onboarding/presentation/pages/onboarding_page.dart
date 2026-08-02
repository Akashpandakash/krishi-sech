import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 720;
            final horizontalPadding = constraints.maxWidth < 360 ? 14.0 : 20.0;

            return Stack(
              children: [
                const Positioned(
                  top: -32,
                  left: -30,
                  child: _DecorativeLeaves(size: 132),
                ),
                const Positioned(
                  top: 132,
                  right: -25,
                  child: _DecorativeLeaves(size: 76),
                ),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              6,
                              horizontalPadding,
                              0,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                key: const Key('onboarding_skip'),
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed(AppRoutes.login);
                                },
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
                                  _WelcomePill(compact: isCompact),
                                  SizedBox(height: isCompact ? 13 : 20),
                                  const _Heading(),
                                  SizedBox(height: isCompact ? 12 : 17),
                                  Text(
                                    context.l10n.onboarding1Description,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          height: 1.42,
                                        ),
                                  ),
                                  SizedBox(height: isCompact ? 18 : 25),
                                  const _FeatureStrip(),
                                  SizedBox(height: isCompact ? 14 : 22),
                                  _FarmerVisual(
                                    height: math.max(
                                      isCompact ? 150 : 190,
                                      math.min(
                                        constraints.maxHeight * 0.25,
                                        245,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const _BottomCard(),
                        ],
                      ),
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

class _WelcomePill extends StatelessWidget {
  const _WelcomePill({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 16,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 7),
          Text(
            context.l10n.onboardingWelcome,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      height: 1.05,
      letterSpacing: -0.8,
    );

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.l10n.onboarding1HeadingLine1,
            style: style?.copyWith(color: AppColors.primaryDark),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.l10n.onboarding1HeadingLine2,
            style: style?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 13),
        Container(
          width: 46,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      _FeatureData(Icons.event_note_outlined, context.l10n.planBetter),
      _FeatureData(Icons.spa_outlined, context.l10n.growBetter),
      _FeatureData(Icons.storefront_outlined, context.l10n.sellBetter),
      _FeatureData(Icons.trending_up_rounded, context.l10n.earnBetter),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _FeatureItem(data: items[index])),
          if (index != items.length - 1)
            Container(
              width: 1,
              height: 54,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.data});

  final _FeatureData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.lightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 7),
        Text(
          data.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _FarmerVisual extends StatelessWidget {
  const _FarmerVisual({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
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
                    Colors.white.withValues(alpha: 0.08),
                    AppColors.primaryDark.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: height * 0.49,
                height: height * 0.72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2).withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(80),
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: height * 0.55,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.allInOneApp,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.allInOneSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _PageIndicators(activeIndex: 0),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                key: const Key('onboarding_next'),
                tooltip: context.l10n.next,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.onboardingSecond);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(58),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 27),
              ),
            ],
          ),
        ),
      ),
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
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isActive ? 24 : 7,
          height: 7,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class _DecorativeLeaves extends StatelessWidget {
  const _DecorativeLeaves({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.32,
      child: Icon(
        Icons.eco_rounded,
        size: size,
        color: AppColors.primary,
        shadows: const [Shadow(color: AppColors.lightGreen, blurRadius: 18)],
      ),
    );
  }
}

class _FeatureData {
  const _FeatureData(this.icon, this.label);

  final IconData icon;
  final String label;
}
