import 'package:bible_tracker/core/models/chapter_ref.dart';

class PlanDay {
  final String planId;

  /// 1-based day number within the plan.
  final int dayNumber;

  /// Date-only; time component is always zero.
  final DateTime scheduledDate;

  /// Ordered list of chapters assigned to this day. Immutable.
  final List<ChapterRef> chapters;

  PlanDay({
    required this.planId,
    required this.dayNumber,
    required this.scheduledDate,
    required List<ChapterRef> chapters,
  }) : chapters = List.unmodifiable(chapters);

  @override
  String toString() =>
      'PlanDay($planId, day $dayNumber, $scheduledDate, '
      '${chapters.length} chapters)';
}
