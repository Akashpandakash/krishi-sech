import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class OnboardingThirdPage extends StatelessWidget {
  const OnboardingThirdPage({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _openLanguageSelection(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.languageSelection);
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
                  top: 105,
                  right: -22,
                  child: _BlurredLeaves(size: 76),
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
                              key: const Key('onboarding_third_skip'),
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
                                _BrandLogo(compact: compact),
                                SizedBox(height: compact ? 10 : 16),
                                const _Heading(),
                                SizedBox(height: compact ? 10 : 14),
                                Text(
                                  context.l10n.onboarding3Description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                ),
                                SizedBox(height: compact ? 14 : 20),
                                const _AgricultureWorkflow(),
                                SizedBox(height: compact ? 14 : 20),
                                const _FeatureCard(),
                                const SizedBox(height: 14),
                                const _InformationBanner(),
                                const SizedBox(height: 16),
                                _BottomNavigation(
                                  onGetStarted: () =>
                                      _openLanguageSelection(context),
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 54.0 : 64.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 34),
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
            context.l10n.onboarding3HeadingLine1,
            style: style?.copyWith(color: AppColors.primaryDark),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.l10n.onboarding3HeadingLine2,
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

class _AgricultureWorkflow extends StatelessWidget {
  const _AgricultureWorkflow();

  @override
  Widget build(BuildContext context) {
    final nodes = [
      _WorkflowData(Icons.verified_user_outlined, context.l10n.securePayment),
      _WorkflowData(Icons.location_on_outlined, context.l10n.localCollection),
      _WorkflowData(Icons.warehouse_outlined, context.l10n.warehouse),
      _WorkflowData(Icons.local_shipping_outlined, context.l10n.logistics),
      _WorkflowData(Icons.handshake_outlined, context.l10n.wholesaler),
      _WorkflowData(Icons.public, context.l10n.export),
    ];

    return AspectRatio(
      aspectRatio: 1.18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final nodeSize = math.min(constraints.maxWidth * 0.19, 76.0);
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final radiusX = constraints.maxWidth * 0.37;
          final radiusY = constraints.maxHeight * 0.34;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: const _WorkflowPathPainter()),
              ),
              for (var index = 0; index < nodes.length; index++)
                _positionedNode(
                  index: index,
                  data: nodes[index],
                  center: center,
                  radiusX: radiusX,
                  radiusY: radiusY,
                  size: nodeSize,
                ),
              Align(
                alignment: Alignment.center,
                child: _FarmerPlaceholder(
                  size: math.min(constraints.maxWidth * 0.28, 116),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _positionedNode({
    required int index,
    required _WorkflowData data,
    required Offset center,
    required double radiusX,
    required double radiusY,
    required double size,
  }) {
    final angle = (-math.pi / 2) + (index * math.pi / 3);
    final x = center.dx + math.cos(angle) * radiusX - size / 2;
    final y = center.dy + math.sin(angle) * radiusY - size / 2;

    return Positioned(
      left: x,
      top: y,
      width: size,
      child: _WorkflowNode(data: data),
    );
  }
}

class _WorkflowPathPainter extends CustomPainter {
  const _WorkflowPathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.68,
      height: size.height * 0.62,
    );
    final path = Path()..addOval(rect);
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 9) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 3, metric.length)),
          paint,
        );
      }
    }

    for (var index = 0; index < 6; index++) {
      final angle = (-math.pi / 2) + (index * math.pi / 3) + 0.34;
      final point = Offset(
        rect.center.dx + math.cos(angle) * rect.width / 2,
        rect.center.dy + math.sin(angle) * rect.height / 2,
      );
      final tangent = angle + math.pi / 2;
      final arrow = Path()
        ..moveTo(point.dx, point.dy)
        ..lineTo(
          point.dx - math.cos(tangent - 0.55) * 7,
          point.dy - math.sin(tangent - 0.55) * 7,
        )
        ..lineTo(
          point.dx - math.cos(tangent + 0.55) * 7,
          point.dy - math.sin(tangent + 0.55) * 7,
        )
        ..close();
      canvas.drawPath(arrow, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WorkflowNode extends StatelessWidget {
  const _WorkflowNode({required this.data});

  final _WorkflowData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(data.icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          data.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _FarmerPlaceholder extends StatelessWidget {
  const _FarmerPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primaryDark,
        size: size * 0.68,
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
        Icons.verified_user_outlined,
        context.l10n.securePayment,
        context.l10n.safeAndFast,
      ),
      _FeatureData(
        Icons.local_shipping_outlined,
        context.l10n.smartLogistics,
        context.l10n.doorstepHelp,
      ),
      _FeatureData(
        Icons.handshake_outlined,
        context.l10n.verifiedBuyers,
        context.l10n.tradeSafely,
      ),
      _FeatureData(
        Icons.public,
        context.l10n.exportOpportunity,
        context.l10n.reachGlobally,
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
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.lightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, color: AppColors.primary, size: 20),
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

class _InformationBanner extends StatelessWidget {
  const _InformationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.public, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.fieldToWorld,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.fieldToWorldSubtitle,
                  style: TextStyle(color: Colors.white70, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppPressable(
          haptic: AppPressableHaptic.selection,
          child: TextButton.icon(
            key: const Key('onboarding_third_back'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 19),
            label: Text(context.l10n.back),
          ),
        ),
        const Spacer(),
        const _PageIndicators(activeIndex: 2),
        const Spacer(),
        AppPressable(
          haptic: AppPressableHaptic.medium,
          child: FilledButton.icon(
            key: const Key('onboarding_third_get_started'),
            onPressed: onGetStarted,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            label: Text(context.l10n.getStarted),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 19),
          ),
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

class _WorkflowData {
  const _WorkflowData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
