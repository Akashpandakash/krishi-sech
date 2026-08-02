import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class MyCropPage extends StatelessWidget {
  const MyCropPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CropScope.of(context);
    final taskController = CropTaskScope.of(context);
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ResponsiveContent(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.myCrops,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        FilledButton.icon(
                          key: const Key('add_crop_button'),
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.addCrop),
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.addCrop),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      key: const Key('crop_calendar_button'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.cropCalendar),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(context.l10n.cropCalendar),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 600
                          ? 4
                          : 2,
                      childAspectRatio: 1.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _SummaryCard(
                          label: context.l10n.totalCrops,
                          value: controller.totalCount,
                          color: AppColors.primary,
                        ),
                        _SummaryCard(
                          label: context.l10n.healthyCrops,
                          value: controller.healthyCount,
                          color: AppColors.primary,
                        ),
                        _SummaryCard(
                          label: context.l10n.cropsNeedingAttention,
                          value: controller.attentionCount,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        _SummaryCard(
                          label: context.l10n.upcomingTasks,
                          value: taskController.upcomingCount,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (controller.crops.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(context.l10n.noCropsYet)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList.separated(
                  itemCount: controller.crops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _CropCard(
                    crop: controller.crops[index],
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.cropDetails,
                      arguments: controller.crops[index].id,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(label, maxLines: 2)),
        ],
      ),
    ),
  );
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop, required this.onTap});

  final Crop crop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (crop.health) {
      CropHealth.healthy => AppColors.primary,
      CropHealth.moderate => AppColors.warning,
      CropHealth.needsAttention => Theme.of(context).colorScheme.error,
    };
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('crop_card_${crop.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cropKindLabel(context, crop),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          crop.variety.isEmpty
                              ? growthStageLabel(context, crop.growthStage)
                              : '${crop.variety} • ${growthStageLabel(context, crop.growthStage)}',
                        ),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                          value: crop.progressPercent / 100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${crop.progressPercent}% • ${cropHealthLabel(context, crop.health)}',
                          style: TextStyle(color: statusColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${cropTaskLabel(context, crop.nextTask)} • '
                          '${context.l10n.inDays(crop.daysUntilNextTask)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${context.l10n.sownOn} '
                          '${MaterialLocalizations.of(context).formatMediumDate(crop.sowingDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
