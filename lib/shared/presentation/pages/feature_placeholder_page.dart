import 'package:flutter/material.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          context.l10n.readyForImplementation(title),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
