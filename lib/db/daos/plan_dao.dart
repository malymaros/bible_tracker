import 'dart:convert';

import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/plan_days_table.dart';
import 'package:bible_tracker/db/tables/reading_plans_table.dart';
import 'package:drift/drift.dart';

part 'plan_dao.g.dart';

@DriftAccessor(tables: [ReadingPlans, PlanDays])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  Stream<ReadingPlan?> watchActivePlan() {
    return select(readingPlans)
        .watchSingleOrNull()
        .map((row) => row == null ? null : _rowToPlan(row));
  }

  /// Replaces any existing plan and its days in a single transaction.
  Future<void> insertPlanWithDays(ReadingPlan plan, List<PlanDay> days) {
    return transaction(() async {
      await delete(planDays).go();
      await delete(readingPlans).go();
      await into(readingPlans).insert(_planToCompanion(plan));
      await batch((b) {
        b.insertAll(planDays, days.map(_dayToCompanion).toList());
      });
    });
  }

  /// Deletes the active plan and its days. Does not touch read progress.
  Future<void> deleteActivePlan() {
    return transaction(() async {
      await delete(planDays).go();
      await delete(readingPlans).go();
    });
  }

  Stream<List<PlanDay>> watchPlanDays(String planId) {
    return (select(planDays)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.dayNumber)]))
        .watch()
        .map((rows) => rows.map(_rowToDay).toList());
  }
}

// ---------------------------------------------------------------------------
// Mapping helpers
// ---------------------------------------------------------------------------

ReadingPlan _rowToPlan(ReadingPlanRow row) => ReadingPlan(
      id: row.id,
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
      totalDays: row.totalDays,
      selectedBookIds: (jsonDecode(row.selectedBookIds) as List).cast<String>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );

ReadingPlansCompanion _planToCompanion(ReadingPlan plan) =>
    ReadingPlansCompanion(
      id: Value(plan.id),
      startDate: Value(plan.startDate.millisecondsSinceEpoch),
      totalDays: Value(plan.totalDays),
      selectedBookIds: Value(jsonEncode(plan.selectedBookIds)),
      createdAt: Value(plan.createdAt.millisecondsSinceEpoch),
    );

PlanDay _rowToDay(PlanDayRow row) => PlanDay(
      planId: row.planId,
      dayNumber: row.dayNumber,
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(row.scheduledDate),
      chapters: (jsonDecode(row.chaptersJson) as List)
          .map((m) => ChapterRef(m['b'] as String, m['c'] as int))
          .toList(),
    );

PlanDaysCompanion _dayToCompanion(PlanDay day) => PlanDaysCompanion(
      planId: Value(day.planId),
      dayNumber: Value(day.dayNumber),
      scheduledDate: Value(day.scheduledDate.millisecondsSinceEpoch),
      chaptersJson: Value(jsonEncode(
        day.chapters
            .map((c) => {'b': c.bookId, 'c': c.chapterNumber})
            .toList(),
      )),
    );
