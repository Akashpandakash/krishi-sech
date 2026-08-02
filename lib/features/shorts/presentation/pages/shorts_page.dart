import 'package:flutter/material.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/pages/feature_placeholder_page.dart';

class ShortsPage extends StatelessWidget {
  const ShortsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholderPage(title: context.l10n.shorts);
  }
}
