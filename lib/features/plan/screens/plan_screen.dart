import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenPlan)),
      body: Center(child: Text(l10n.screenPlan)),
    );
  }
}
