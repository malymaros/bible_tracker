import 'dart:async';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/plan/screens/plan_screen.dart';
import 'package:bible_tracker/features/statistics/screens/statistika_screen.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Widget _testWidget(
  Widget child,
  AppDatabase db, {
  ReadingPlan? activePlan,
  List<PlanDay> days = const [],
  Set<ChapterRef> readChapters = const {},
  Stream<Set<ChapterRef>>? readChaptersStream,
  DateTime? today,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
      if (activePlan != null)
        activePlanProvider.overrideWith((_) => Stream.value(activePlan)),
      if (activePlan == null && child is PlanScreen)
        activePlanProvider.overrideWith((_) => Stream.value(null)),
      planDaysProvider.overrideWith((ref, planId) => Stream.value(days)),
      readChaptersProvider.overrideWith(
        (_) => readChaptersStream ?? Stream.value(readChapters),
      ),
      downloadedChapterCountsProvider.overrideWith(
        (_) => Stream.value(const {}),
      ),
      todayProvider.overrideWithValue(today ?? DateTime(2026, 5, 12)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

ReadingPlan _plan() => ReadingPlan(
  id: 'plan-1',
  startDate: DateTime(2026, 5, 12),
  totalDays: 3,
  selectedBookIds: const ['gen', 'ps'],
  createdAt: DateTime(2026, 5, 1),
);

List<PlanDay> _days(String planId) => [
  PlanDay(
    planId: planId,
    dayNumber: 1,
    scheduledDate: DateTime(2026, 5, 12),
    chapters: const [
      ChapterRef('gen', 1),
      ChapterRef('gen', 2),
      ChapterRef('gen', 3),
      ChapterRef('ps', 1),
    ],
  ),
  PlanDay(
    planId: planId,
    dayNumber: 2,
    scheduledDate: DateTime(2026, 5, 13),
    chapters: const [ChapterRef('gen', 4), ChapterRef('ps', 2)],
  ),
  PlanDay(
    planId: planId,
    dayNumber: 3,
    scheduledDate: DateTime(2026, 5, 14),
    chapters: const [ChapterRef('ps', 3)],
  ),
];

Future<void> _enterDays(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(const Key('plan-total-days-field')), value);
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('no plan shows create flow', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testWidget(const PlanScreen(), db));
    await tester.pumpAndSettle();

    expect(find.text('Vytvoriť plán čítania'), findsOneWidget);
    expect(find.byKey(const Key('plan-create-button')), findsOneWidget);
  });

  testWidgets('all books selected by default', (tester) async {
    final db = _openTestDb();
    final totalBooks = kBibleBooks.length;

    await tester.pumpWidget(_testWidget(const CreatePlanScreen(), db));
    await tester.pumpAndSettle();

    // Expand Pentateuch to make Genesis visible
    await tester.tap(find.byKey(const Key('plan-book-group-pentateuch')));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(
      find.descendant(
        of: find.byKey(const Key('plan-book-gen')),
        matching: find.byType(Checkbox),
      ),
    );
    expect(checkbox.value, isTrue);
    expect(find.text('$totalBooks'), findsOneWidget);
  });

  testWidgets('validation for invalid day count', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testWidget(const CreatePlanScreen(), db));
    await tester.pumpAndSettle();
    await _enterDays(tester, '0');

    expect(find.text('Zadajte platný počet dní'), findsOneWidget);
  });

  testWidgets('totalDays greater than selected chapters is invalid', (
    tester,
  ) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testWidget(const CreatePlanScreen(), db));
    await tester.pumpAndSettle();
    await _enterDays(tester, '9999');

    expect(
      find.text('Počet dní nemôže byť väčší ako počet vybraných kapitol'),
      findsOneWidget,
    );
  });

  testWidgets('create plan saves plan and days', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testWidget(const CreatePlanScreen(), db));
    await tester.pumpAndSettle();
    await _enterDays(tester, '10');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('plan-create-button')))
          .onPressed,
      isNotNull,
    );
    await tester.runAsync(() async {
      tester
          .widget<FilledButton>(find.byKey(const Key('plan-create-button')))
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final plan = await db.planDao.watchActivePlan().first.timeout(
        const Duration(seconds: 2),
      );
      expect(plan, isNotNull);
      expect(plan!.totalDays, 10);
      expect(plan.selectedBookIds.length, 73);

      final days = await db.planDao.watchPlanDays(plan.id).first;
      expect(days.length, 10);
    });
  });

  testWidgets('Plan screen renders with Knjiy button and progress widget', (
    tester,
  ) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-books-nav-button')), findsOneWidget);
    expect(find.text('Dnešné čítanie'), findsOneWidget);
    expect(find.byKey(const Key('plan-current-day-1')), findsOneWidget);
    expect(find.byKey(const Key('plan-current-day-2')), findsNothing);
    expect(find.text('Genezis 1–3'), findsOneWidget);
    expect(find.text('Žalmy 1'), findsWidgets);
  });

  testWidgets('previous and next day navigation changes selected day', (
    tester,
  ) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
        today: DateTime(2026, 5, 12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-current-day-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan-next-day-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-current-day-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan-previous-day-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-current-day-1')), findsOneWidget);
  });

  testWidgets('total progress widget shows plan completion', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
        readChapters: {const ChapterRef('gen', 1)},
      ),
    );
    await tester.pumpAndSettle();

    // Total: 4+2+1 = 7 chapters, 1 completed → 14%
    expect(find.byKey(const Key('plan-total-progress-bar')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('plan-total-progress-percent')))
          .data,
      '14 %',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('plan-total-progress-chapters')))
          .data,
      startsWith('1 / 7'),
    );
  });

  testWidgets('total progress widget shows completed books / selected books', (
    tester,
  ) async {
    final db = _openTestDb();
    final plan = _plan(); // selectedBookIds: ['gen', 'ps']

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
        readChapters: const {},
      ),
    );
    await tester.pumpAndSettle();

    final booksText = tester
        .widget<Text>(find.byKey(const Key('plan-total-progress-books')))
        .data!;
    // 0 completed, 2 selected books
    expect(booksText, startsWith('0 / 2'));
    expect(booksText, contains('knihy'));
  });

  testWidgets('progress updates when checkbox changes', (tester) async {
    final db = _openTestDb();
    final plan = _plan();
    final reads = StreamController<Set<ChapterRef>>();
    addTearDown(reads.close);

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
        readChaptersStream: reads.stream,
      ),
    );
    reads.add(const <ChapterRef>{});
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('plan-total-progress-chapters')))
          .data,
      startsWith('0 / 7'),
    );

    await tester.tap(find.byKey(const Key('plan-chapter-gen-1')));
    await tester.pump();
    reads.add({const ChapterRef('gen', 1)});
    await tester.pumpAndSettle();

    expect(await db.progressDao.isRead(const ChapterRef('gen', 1)), isTrue);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('plan-total-progress-chapters')))
          .data,
      startsWith('1 / 7'),
    );
  });

  testWidgets('chapter tap opens ReaderScreen', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plan-open-chapter-gen-1')));
    await tester.pumpAndSettle();

    expect(find.text('Genezis 1'), findsWidgets);
  });

  testWidgets('tapping progress widget opens Statistics screen', (
    tester,
  ) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the total progress card
    await tester.tap(find.byKey(const Key('plan-total-progress-bar')));
    await tester.pumpAndSettle();

    expect(find.byType(StatistikaScreen), findsOneWidget);
  });

  testWidgets('Knjiy button opens Books screen', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plan-books-nav-button')));
    await tester.pumpAndSettle();

    // BibliaScreen shows book groups
    expect(find.text('Biblia'), findsWidgets);
    expect(find.text('Pentateuch'), findsOneWidget);
  });

  testWidgets('Knjiy button is present on create plan screen', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testWidget(const PlanScreen(), db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-books-nav-button')), findsOneWidget);
  });

  testWidgets('book progress is calculated correctly', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        BooksInPlanScreen(plan: plan),
        db,
        activePlan: plan,
        days: _days(plan.id),
        readChapters: {const ChapterRef('gen', 1), const ChapterRef('ps', 1)},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('plan-book-count-gen'))).data,
      '1/4',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('plan-book-count-ps'))).data,
      '1/3',
    );
  });

  testWidgets('completed book shows completion mark', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        BooksInPlanScreen(plan: plan),
        db,
        activePlan: plan,
        days: _days(plan.id),
        readChapters: {
          const ChapterRef('gen', 1),
          const ChapterRef('gen', 2),
          const ChapterRef('gen', 3),
          const ChapterRef('gen', 4),
        },
      ),
    );
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(
      find.byKey(const Key('plan-book-complete-gen')),
    );
    expect(checkbox.value, isTrue);
  });

  testWidgets('delete plan confirmation removes plan', (tester) async {
    final db = _openTestDb();
    final plan = _plan();
    final days = _days(plan.id);
    await tester.runAsync(() => db.planDao.insertPlanWithDays(plan, days));

    await tester.pumpWidget(
      _testWidget(const PlanScreen(), db, activePlan: plan, days: days),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Vymazať plán'));
    await tester.pumpAndSettle();
    expect(find.text('Vymazať plán?'), findsOneWidget);

    await tester.tap(find.text('Vymazať plán').last);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(await db.planDao.watchActivePlan().first, isNull);
    });
  });

  testWidgets('app bar center shows Biblia text', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biblia'), findsOneWidget);
  });

  testWidgets('books nav button has no visible text label', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Knihy'), findsNothing);
    expect(find.byKey(const Key('plan-books-nav-button')), findsOneWidget);
  });

  testWidgets('day header shows N / X format', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    // Plan has 3 days; today is day 1 — header should show 'Deň 1 / 3'
    expect(find.text('Deň 1 / 3'), findsOneWidget);
  });

  testWidgets('BooksInPlanScreen does not show summary card', (tester) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        BooksInPlanScreen(plan: plan),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktuálny plán'), findsNothing);
    expect(find.byKey(const Key('plan-books-summary')), findsNothing);
  });

  testWidgets('BooksInPlanScreen shows testament header', (tester) async {
    final db = _openTestDb();
    final plan = _plan(); // gen and ps are both Old Testament

    await tester.pumpWidget(
      _testWidget(
        BooksInPlanScreen(plan: plan),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Starý zákon'), findsOneWidget);
  });

  testWidgets('BooksInPlanScreen uses BookIconBadge not menu_book icon', (
    tester,
  ) async {
    final db = _openTestDb();
    final plan = _plan();

    await tester.pumpWidget(
      _testWidget(
        BooksInPlanScreen(plan: plan),
        db,
        activePlan: plan,
        days: _days(plan.id),
      ),
    );
    await tester.pumpAndSettle();

    // BookIconBadge shows the book abbreviation text, not a CircleAvatar icon
    expect(find.byType(BookIconBadge), findsWidgets);
  });

  testWidgets('plan deletion keeps read progress', (tester) async {
    final db = _openTestDb();
    final plan = _plan();
    final days = _days(plan.id);
    const readRef = ChapterRef('gen', 1);
    await tester.runAsync(() async {
      await db.progressDao.markRead(readRef, DateTime(2026, 5, 12));
      await db.planDao.insertPlanWithDays(plan, days);
    });

    await tester.pumpWidget(
      _testWidget(
        const PlanScreen(),
        db,
        activePlan: plan,
        days: days,
        readChapters: {readRef},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Vymazať plán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vymazať plán').last);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(await db.progressDao.isRead(readRef), isTrue);
    });
  });
}
