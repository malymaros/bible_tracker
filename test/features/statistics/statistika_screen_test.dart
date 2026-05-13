import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/statistics/screens/statistika_screen.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

ReadingPlan _plan({
  List<String> selectedBookIds = const ['gen', 'matt'],
  int totalDays = 2,
}) {
  return ReadingPlan(
    id: 'plan-1',
    startDate: DateTime(2026, 5, 12),
    totalDays: totalDays,
    selectedBookIds: selectedBookIds,
    createdAt: DateTime(2026, 5, 1),
  );
}

PlanDay _day(int dayNumber, List<ChapterRef> chapters) {
  return PlanDay(
    planId: 'plan-1',
    dayNumber: dayNumber,
    scheduledDate: DateTime(2026, 5, 11 + dayNumber),
    chapters: chapters,
  );
}

Widget _testWidget({
  required AppDatabase db,
  ReadingPlan? plan,
  List<PlanDay> days = const [],
  Set<ChapterRef> readChapters = const {},
  DateTime? today,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
      activePlanProvider.overrideWith((_) => Stream.value(plan)),
      planDaysProvider.overrideWith((ref, planId) => Stream.value(days)),
      readChaptersProvider.overrideWith((_) => Stream.value(readChapters)),
      todayProvider.overrideWithValue(today ?? DateTime(2026, 5, 12)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StatistikaScreen(),
    ),
  );
}

Future<void> _pumpStats(
  WidgetTester tester, {
  AppDatabase? db,
  ReadingPlan? plan,
  List<PlanDay> days = const [],
  Set<ChapterRef> readChapters = const {},
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final database = db ?? _openTestDb();
  await tester.pumpWidget(
    _testWidget(
      db: database,
      plan: plan,
      days: days,
      readChapters: readChapters,
    ),
  );
  await tester.pumpAndSettle();
}

String _metricText(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

void main() {
  testWidgets('no plan shows empty state', (tester) async {
    await _pumpStats(tester);

    expect(find.text('Najprv si vytvorte plán čítania.'), findsOneWidget);
  });

  testWidgets('statistics count only active plan chapters', (tester) async {
    final plan = _plan();

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('gen', 2)]),
        _day(2, const [ChapterRef('matt', 1)]),
      ],
      readChapters: {const ChapterRef('gen', 1), const ChapterRef('matt', 1)},
    );

    expect(_metricText(tester, 'stats-completed-plan-chapters'), '2/3');
    expect(_metricText(tester, 'stats-plan-percent'), '66.7 %');
  });

  testWidgets('read chapters outside the plan are ignored', (tester) async {
    final plan = _plan(selectedBookIds: const ['gen']);

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('gen', 2)]),
      ],
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('exod', 1),
        const ChapterRef('matt', 1),
      },
    );

    expect(_metricText(tester, 'stats-completed-plan-chapters'), '1/2');
    expect(_metricText(tester, 'stats-plan-percent'), '50.0 %');
  });

  testWidgets('OT and NT progress is based only on selected plan books', (
    tester,
  ) async {
    final plan = _plan();

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('gen', 2)]),
        _day(2, const [ChapterRef('matt', 1), ChapterRef('matt', 2)]),
      ],
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('matt', 1),
        const ChapterRef('exod', 1),
      },
    );

    expect(_metricText(tester, 'stats-old-testament'), '1/2');
    expect(_metricText(tester, 'stats-new-testament'), '1/2');
  });

  testWidgets('overall completed books count is shown in main section', (
    tester,
  ) async {
    final plan = _plan(selectedBookIds: const ['obad', 'phlm']);

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('obad', 1), ChapterRef('phlm', 1)]),
      ],
      readChapters: {const ChapterRef('obad', 1), const ChapterRef('gen', 1)},
    );

    expect(_metricText(tester, 'stats-completed-books-overall'), '1/2');
  });

  testWidgets('OT completed books count is shown in OT section', (
    tester,
  ) async {
    final plan = _plan(selectedBookIds: const ['gen', 'matt']);

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('matt', 1)]),
      ],
      readChapters: {const ChapterRef('gen', 1)},
    );

    // gen (OT) is completed, matt (NT) is not
    expect(_metricText(tester, 'stats-ot-books'), '1/1');
  });

  testWidgets('NT completed books count is shown in NT section', (
    tester,
  ) async {
    final plan = _plan(selectedBookIds: const ['gen', 'matt']);

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('matt', 1)]),
      ],
      readChapters: {const ChapterRef('matt', 1)},
    );

    // matt (NT) is completed, gen (OT) is not
    expect(_metricText(tester, 'stats-nt-books'), '1/1');
  });

  testWidgets('OT and NT sections are separate widgets', (tester) async {
    final plan = _plan(selectedBookIds: const ['gen', 'matt']);

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('matt', 1)]),
      ],
    );

    expect(find.byKey(const Key('stats-ot-section')), findsOneWidget);
    expect(find.byKey(const Key('stats-nt-section')), findsOneWidget);
  });

  testWidgets('statistics no longer shows Dnešné čítanie v pláne', (
    tester,
  ) async {
    final plan = _plan();

    await _pumpStats(
      tester,
      plan: plan,
      days: [_day(1, const [ChapterRef('gen', 1)])],
    );

    expect(find.text('Dnešné čítanie v pláne'), findsNothing);
  });

  testWidgets('statistics no longer shows Deuterokánonické knihy v pláne', (
    tester,
  ) async {
    final plan = _plan(selectedBookIds: const ['tob']);

    await _pumpStats(
      tester,
      plan: plan,
      days: [_day(1, const [ChapterRef('tob', 1)])],
      readChapters: {const ChapterRef('tob', 1)},
    );

    expect(find.text('Deuterokánonické knihy v pláne'), findsNothing);
  });

  testWidgets('statistics screen has no read or unread controls', (
    tester,
  ) async {
    final plan = _plan();

    await _pumpStats(
      tester,
      plan: plan,
      days: [
        _day(1, const [ChapterRef('gen', 1)]),
      ],
      readChapters: {const ChapterRef('gen', 1)},
    );

    expect(find.text('Označiť ako prečítané'), findsNothing);
    expect(find.text('Označiť ako neprečítané'), findsNothing);
  });
}
