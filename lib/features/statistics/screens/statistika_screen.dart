import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class StatistikaScreen extends StatelessWidget {
  const StatistikaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenStatistika)),
      body: Center(child: Text(l10n.screenStatistika)),
    );
  }
}
