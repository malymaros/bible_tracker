import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/plan/screens/plan_screen.dart';
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

Widget _testWidget(
  Widget child,
  AppDatabase db, {
  ReadingPlan? activePlan,
  List<PlanDay> days = const [],
  Set<ChapterRef> readChapters = const {},
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
      readChaptersProvider.overrideWith((_) => Stream.value(readChapters)),
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
  totalDays: 2,
  selectedBookIds: const ['gen'],
  createdAt: DateTime(2026, 5, 1),
);

List<PlanDay> _days(String planId) => [
  PlanDay(
    planId: planId,
    dayNumber: 1,
    scheduledDate: DateTime(2026, 5, 12),
    chapters: const [ChapterRef('gen', 1), ChapterRef('gen', 2)],
  ),
  PlanDay(
    planId: planId,
    dayNumber: 2,
    scheduledDate: DateTime(2026, 5, 13),
    chapters: const [ChapterRef('gen', 3), ChapterRef('gen', 4)],
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
    final totalChapters = kBibleBooks.fold<int>(
      0,
      (sum, book) => sum + book.chapterCount,
    );

    await tester.pumpWidget(_testWidget(const CreatePlanScreen(), db));
    await tester.pumpAndSettle();

    final firstVisibleCheckbox = tester.widget<CheckboxListTile>(
      find.byKey(const Key('plan-book-gen')),
    );
    expect(firstVisibleCheckbox.value, isTrue);
    expect(find.text('$totalChapters'), findsOneWidget);
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

  testWidgets('existing plan shows schedule', (tester) async {
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

    expect(find.text('Dnešné čítanie'), findsOneWidget);
    expect(find.text('Rozpis'), findsOneWidget);
    expect(find.byKey(const Key('plan-day-1')), findsWidgets);
    expect(find.text('Gn 1'), findsWidgets);
  });

  testWidgets('today is highlighted', (tester) async {
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

    expect(find.textContaining('(dnes)'), findsWidgets);
  });

  testWidgets('read chapters are shown as completed', (tester) async {
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

    expect(find.text('prečítané'), findsWidgets);
    expect(find.text('neprečítané'), findsWidgets);
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
