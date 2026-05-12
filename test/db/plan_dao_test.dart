import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _planId = 'plan-1';

ReadingPlan _makePlan({String id = _planId}) => ReadingPlan(
      id: id,
      startDate: DateTime(2024, 1, 1),
      totalDays: 2,
      selectedBookIds: const ['gen'],
      createdAt: DateTime(2024, 1, 1),
    );

List<PlanDay> _makeDays(String planId) => [
      PlanDay(
        planId: planId,
        dayNumber: 1,
        scheduledDate: DateTime(2024, 1, 1),
        chapters: const [ChapterRef('gen', 1), ChapterRef('gen', 2)],
      ),
      PlanDay(
        planId: planId,
        dayNumber: 2,
        scheduledDate: DateTime(2024, 1, 2),
        chapters: const [ChapterRef('gen', 3), ChapterRef('gen', 4)],
      ),
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── watchActivePlan initial state ────────────────────────────────────────

  test('watchActivePlan is null before any plan is inserted', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(await db.planDao.watchActivePlan().first, isNull);
  });

  // ── insertPlanWithDays ───────────────────────────────────────────────────

  test('insertPlanWithDays stores plan; watchActivePlan returns it', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));

    final active = await db.planDao.watchActivePlan().first;
    expect(active, isNotNull);
    expect(active!.id, plan.id);
    expect(active.totalDays, plan.totalDays);
    expect(active.selectedBookIds, plan.selectedBookIds);
  });

  test('startDate is stored and retrieved correctly', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));

    final active = await db.planDao.watchActivePlan().first;
    expect(active!.startDate, DateTime(2024, 1, 1));
  });

  test('insertPlanWithDays replaces the existing plan', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final first = _makePlan(id: 'plan-1');
    await db.planDao.insertPlanWithDays(first, _makeDays(first.id));

    final second = _makePlan(id: 'plan-2');
    await db.planDao.insertPlanWithDays(second, _makeDays(second.id));

    final active = await db.planDao.watchActivePlan().first;
    expect(active!.id, 'plan-2'); // old plan replaced
  });

  test('inserting a new plan also replaces the old plan days', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final first = _makePlan(id: 'plan-1');
    await db.planDao.insertPlanWithDays(first, _makeDays(first.id));

    final second = _makePlan(id: 'plan-2');
    await db.planDao.insertPlanWithDays(second, _makeDays(second.id));

    // Days for plan-1 must be gone; plan-2's days are present.
    final days = await db.planDao.watchPlanDays('plan-1').first;
    expect(days, isEmpty);
  });

  // ── deleteActivePlan ─────────────────────────────────────────────────────

  test('deleteActivePlan removes the plan; watchActivePlan returns null',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));
    await db.planDao.deleteActivePlan();

    expect(await db.planDao.watchActivePlan().first, isNull);
  });

  test('deleteActivePlan also removes plan days', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));
    await db.planDao.deleteActivePlan();

    final days = await db.planDao.watchPlanDays(plan.id).first;
    expect(days, isEmpty);
  });

  test('deleteActivePlan does not delete read progress', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    // Mark some chapters as read.
    await db.progressDao.markRead(const ChapterRef('gen', 1), DateTime.now());
    await db.progressDao.markRead(const ChapterRef('gen', 2), DateTime.now());

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));
    await db.planDao.deleteActivePlan();

    // Read progress must still be intact.
    expect(await db.progressDao.isRead(const ChapterRef('gen', 1)), isTrue);
    expect(await db.progressDao.isRead(const ChapterRef('gen', 2)), isTrue);
  });

  // ── watchPlanDays ────────────────────────────────────────────────────────

  test('watchPlanDays returns days ordered by dayNumber', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    // Insert days in reverse order to stress the ORDER BY.
    final reversedDays = _makeDays(plan.id).reversed.toList();
    await db.planDao.insertPlanWithDays(plan, reversedDays);

    final days = await db.planDao.watchPlanDays(plan.id).first;
    expect(days.map((d) => d.dayNumber).toList(), [1, 2]);
  });

  test('watchPlanDays returns empty list for unknown planId', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(await db.planDao.watchPlanDays('no-such-plan').first, isEmpty);
  });

  // ── ChapterRef JSON roundtrip ─────────────────────────────────────────────

  test('PlanDay chapters survive JSON serialisation roundtrip', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    final originalDays = _makeDays(plan.id);
    await db.planDao.insertPlanWithDays(plan, originalDays);

    final retrieved = await db.planDao.watchPlanDays(plan.id).first;
    expect(retrieved.length, originalDays.length);

    for (var i = 0; i < originalDays.length; i++) {
      expect(retrieved[i].chapters, originalDays[i].chapters);
    }
  });

  test('scheduledDate survives millisecond roundtrip', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));

    final days = await db.planDao.watchPlanDays(plan.id).first;
    expect(days[0].scheduledDate, DateTime(2024, 1, 1));
    expect(days[1].scheduledDate, DateTime(2024, 1, 2));
  });

  // ── selectedBookIds roundtrip ─────────────────────────────────────────────

  test('selectedBookIds JSON roundtrip preserves list order', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = ReadingPlan(
      id: 'multi',
      startDate: DateTime(2024, 1, 1),
      totalDays: 3,
      selectedBookIds: const ['gen', 'ex', 'lev'],
      createdAt: DateTime(2024, 1, 1),
    );
    await db.planDao.insertPlanWithDays(plan, [
      PlanDay(
        planId: plan.id,
        dayNumber: 1,
        scheduledDate: DateTime(2024, 1, 1),
        chapters: const [ChapterRef('gen', 1)],
      ),
    ]);

    final active = await db.planDao.watchActivePlan().first;
    expect(active!.selectedBookIds, ['gen', 'ex', 'lev']);
  });

  // ── stream reactivity ─────────────────────────────────────────────────────

  test('watchActivePlan is reactive: emits plan after insert', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    final futureEmission =
        db.planDao.watchActivePlan().firstWhere((p) => p != null);

    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));

    final emitted = await futureEmission;
    expect(emitted?.id, plan.id);
  });

  test('watchActivePlan is reactive: emits null after delete', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));

    // Subscribe while plan exists; wait for first null emission.
    final futureEmission =
        db.planDao.watchActivePlan().firstWhere((p) => p == null);
    await db.planDao.deleteActivePlan();

    expect(await futureEmission, isNull);
  });

  test('watchPlanDays is reactive: emits updated days after insert', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final plan = _makePlan();
    final futureEmission =
        db.planDao.watchPlanDays(plan.id).firstWhere((l) => l.isNotEmpty);

    await db.planDao.insertPlanWithDays(plan, _makeDays(plan.id));

    final days = await futureEmission;
    expect(days.length, 2);
  });
}
