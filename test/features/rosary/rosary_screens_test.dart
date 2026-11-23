import 'package:bible_tracker/core/constants/rosary.dart';
import 'package:bible_tracker/core/models/rosary.dart';
import 'package:bible_tracker/features/rosary/screens/rosary_detail_screen.dart';
import 'package:bible_tracker/features/rosary/screens/rosary_guide_screen.dart';
import 'package:bible_tracker/features/rosary/screens/rosary_list_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testWidget(Widget child, {DateTime? today}) {
  return ProviderScope(
    overrides: [
      // 2026-11-23 is a Monday.
      todayProvider.overrideWithValue(today ?? DateTime(2026, 11, 23)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
}

Rosary _rosary(RosaryKind kind) => kRosaries.firstWhere((r) => r.kind == kind);

void main() {
  testWidgets('list shows four rosaries with today badge on Monday', (
    tester,
  ) async {
    await tester.pumpWidget(_testWidget(const RosaryListScreen()));

    for (final r in kRosaries) {
      expect(find.text(r.name), findsOneWidget);
    }
    expect(find.text('DNES'), findsOneWidget);
    final badgeCard = find.ancestor(
      of: find.text('DNES'),
      matching: find.byKey(const Key('rosary-card-joyful')),
    );
    expect(badgeCard, findsOneWidget);
  });

  testWidgets('today badge follows the weekday (Thursday -> svetla)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testWidget(const RosaryListScreen(), today: DateTime(2026, 11, 26)),
    );
    expect(
      find.ancestor(
        of: find.text('DNES'),
        matching: find.byKey(const Key('rosary-card-luminous')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a card opens the detail', (tester) async {
    await tester.pumpWidget(_testWidget(const RosaryListScreen()));
    await tester.tap(find.byKey(const Key('rosary-day-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rosary-card-sorrowful')));
    await tester.pumpAndSettle();
    expect(find.byType(RosaryDetailScreen), findsOneWidget);
    expect(find.text('Krvavý pot v Getsemanskej záhrade'), findsOneWidget);
  });

  testWidgets('tapping a prayer in detail expands its text', (tester) async {
    await tester.pumpWidget(
      _testWidget(RosaryDetailScreen(rosary: _rosary(RosaryKind.joyful))),
    );

    expect(find.textContaining('Stvoriteľa neba i zeme'), findsNothing);
    await _scrollTo(tester, const Key('rosary-order-verim'));
    await tester.tap(find.byKey(const Key('rosary-order-verim')));
    await tester.pump();
    expect(
      find.textContaining('Stvoriteľa neba i zeme', findRichText: true),
      findsOneWidget,
    );

    // Opening another row closes the first one.
    await _scrollTo(tester, const Key('rosary-order-oj'));
    await tester.tap(find.byKey(const Key('rosary-order-oj')));
    await tester.pump();
    expect(
      find.textContaining('Stvoriteľa neba i zeme', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('pekelného ohňa', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('guide advances and restarts', (tester) async {
    await tester.pumpWidget(
      _testWidget(RosaryGuideScreen(rosary: _rosary(RosaryKind.glorious))),
    );

    expect(find.text('ZNAMENIE KRÍŽA'), findsOneWidget);
    expect(find.text('Úvod'), findsOneWidget);

    final next = find.byKey(const Key('rosary-guide-next'));
    for (var i = 0; i < 7; i++) {
      await tester.tap(next);
      await tester.pump();
    }
    expect(find.text('1. SLÁVNOSTNÉ TAJOMSTVO'), findsOneWidget);
    expect(find.text('Desiatok 1 z 5'), findsOneWidget);
    expect(find.text('Zmŕtvychvstanie'), findsOneWidget);
    expect(find.text('Mt 28,1-10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rosary-guide-back')));
    await tester.pump();
    expect(find.text('SLÁVA OTCU'), findsOneWidget);

    for (var i = 0; i < 72; i++) {
      await tester.tap(next);
      await tester.pump();
    }
    expect(find.text('Začať odznova'), findsOneWidget);
    await tester.tap(next);
    await tester.pump();
    expect(find.text('ZNAMENIE KRÍŽA'), findsOneWidget);
    expect(find.text('Ďalej'), findsOneWidget);
  });
}
