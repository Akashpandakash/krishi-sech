import 'dart:io';

import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class DiseaseResultPage extends StatelessWidget {
  const DiseaseResultPage({super.key, required this.arguments});

  final DiseaseResultArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.diseaseResult)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.file(
                      File(arguments.imagePath),
                      cacheWidth:
                          (MediaQuery.sizeOf(context).width *
                                  MediaQuery.devicePixelRatioOf(context))
                              .ceil(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.lightGreen,
                        child: Icon(Icons.eco_outlined, size: 64),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Only the debug sample carries this badge; a real
                        // diagnosis showed it too, which read as though the
                        // app had never actually analysed the photo.
                        if (arguments.result.isDemo)
                          Container(
                            key: const Key('disease_demo_badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.l10n.demoResult,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        if (arguments.isLowConfidence) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.help_outline),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(context.l10n.lowConfidenceResult),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          arguments.result.possibleDisease,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.scanConfidence(
                            (arguments.result.confidence * 100).round(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${arguments.result.cropName} • ${arguments.result.severity}',
                        ),
                        const Divider(height: 28),
                        Text(
                          context.l10n.visibleSymptoms,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        _ResultList(items: arguments.result.visibleSymptoms),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.recommendedActions,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        _ResultList(items: arguments.result.recommendedActions),
                        if (arguments.result.needsExpertReview) ...[
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.expertReviewRecommended,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                        if (arguments.result.followUpQuestions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.followUpQuestions,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          _ResultList(
                            items: arguments.result.followUpQuestions,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('consult_disease_expert'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(context.l10n.consultExpert),
                      content: Text(context.l10n.consultExpertGuidance),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            MaterialLocalizations.of(context).okButtonLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(context.l10n.consultExpert),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.notMedicalDiagnosis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DiseaseResultArguments {
  const DiseaseResultArguments({
    required this.imagePath,
    required this.result,
    required this.isLowConfidence,
    this.cropId,
  });

  final String imagePath;
  final DiseaseScanResult result;
  final bool isLowConfidence;
  final String? cropId;
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(context.l10n.notAvailable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• $item'),
            ),
          )
          .toList(growable: false),
    );
  }
}
