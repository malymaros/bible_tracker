import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';

/// Pure stateless service. Converts a book selection and duration into an
/// immutable day-by-day reading schedule.
abstract final class PlanGenerator {
  /// Generates a flat list of [PlanDay]s for a reading plan.
  ///
  /// - Books are sorted by canonical [BibleBook.order].
  /// - All chapters are flattened and split into [totalDays] consecutive chunks.
  /// - Remainder chapters are distributed to the earliest days so that no day
  ///   is ever empty.
  /// - Scheduled dates start at [startDate] (time component stripped) and
  ///   advance by one calendar day per day.
  ///
  /// Throws [ArgumentError] if:
  /// - [totalDays] < 1
  /// - [selectedBooks] is empty
  /// - [totalDays] > total chapter count of [selectedBooks]
  static List<PlanDay> generatePlan({
    required String planId,
    required DateTime startDate,
    required int totalDays,
    required List<BibleBook> selectedBooks,
  }) {
    if (totalDays < 1) {
      throw ArgumentError.value(totalDays, 'totalDays', 'must be >= 1');
    }
    if (selectedBooks.isEmpty) {
      throw ArgumentError.value(
          selectedBooks, 'selectedBooks', 'must not be empty');
    }

    final cursor = ChapterCursor(selectedBooks);
    final totalChapters = cursor.totalChapters;

    if (totalDays > totalChapters) {
      throw ArgumentError(
        'totalDays ($totalDays) exceeds total chapters ($totalChapters) '
        'in the selected books',
      );
    }

    final chapters = cursor.toList();
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final basePerDay = totalChapters ~/ totalDays;
    final remainder = totalChapters % totalDays;

    final days = <PlanDay>[];
    var offset = 0;

    for (var i = 0; i < totalDays; i++) {
      final count = basePerDay + (i < remainder ? 1 : 0);
      days.add(PlanDay(
        planId: planId,
        dayNumber: i + 1,
        scheduledDate: start.add(Duration(days: i)),
        chapters: chapters.sublist(offset, offset + count),
      ));
      offset += count;
    }

    return days;
  }
}
