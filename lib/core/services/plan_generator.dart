import 'package:bible_tracker/core/constants/verse_counts.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';

/// Pure stateless service. Converts a book selection and duration into an
/// immutable day-by-day reading schedule.
abstract final class PlanGenerator {
  /// Generates a flat list of [PlanDay]s for a reading plan.
  ///
  /// - Books are sorted by canonical [BibleBook.order].
  /// - Chapters are distributed to days by verse count (not chapter count),
  ///   so that each day receives approximately equal reading load.
  /// - Whole chapters are always kept together — no chapter is split across days.
  /// - No day is ever empty.
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
    final n = chapters.length;
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Build prefix-sum array over verse counts.
    // prefixSums[i] = total verses in chapters[0..i-1].
    final prefixSums = List<int>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      final ref = chapters[i];
      prefixSums[i + 1] =
          prefixSums[i] + verseCountForChapter(ref.bookId, ref.chapterNumber);
    }
    final totalVerses = prefixSums[n];

    final days = <PlanDay>[];
    var prevEnd = -1; // 0-based index of last chapter assigned to previous day

    for (var d = 0; d < totalDays; d++) {
      final int splitEnd;

      if (d == totalDays - 1) {
        // Last day always takes everything that remains.
        splitEnd = n - 1;
      } else {
        // Ideal cumulative verse count at the end of day d.
        final idealCumulative = (d + 1) * totalVerses / totalDays;

        // Valid range: include at least 1 chapter in this day (minK),
        // and leave at least 1 chapter per remaining day (maxK).
        final minK = prevEnd + 1;
        final maxK = n - (totalDays - d - 1) - 1;

        // Find the split index k where prefixSums[k+1] is closest to ideal.
        // Tie-break: prefer the smaller k (fewer chapters today → smoother
        // future days). Implemented by strict-less-than replacement.
        var bestK = minK;
        var bestDist = (prefixSums[minK + 1] - idealCumulative).abs();
        for (var k = minK + 1; k <= maxK; k++) {
          final dist = (prefixSums[k + 1] - idealCumulative).abs();
          if (dist < bestDist) {
            bestDist = dist;
            bestK = k;
          }
        }
        splitEnd = bestK;
      }

      days.add(PlanDay(
        planId: planId,
        dayNumber: d + 1,
        scheduledDate: start.add(Duration(days: d)),
        chapters: chapters.sublist(prevEnd + 1, splitEnd + 1),
      ));
      prevEnd = splitEnd;
    }

    return days;
  }
}
