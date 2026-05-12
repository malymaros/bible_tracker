import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_statistics.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';

abstract final class PlanStatisticsCalculator {
  static PlanStatistics calculate({
    required ReadingPlan plan,
    required List<PlanDay> days,
    required Set<ChapterRef> readChapters,
  }) {
    final selectedBooks = _selectedBooks(plan);
    final selectedBookIds = selectedBooks.map((book) => book.id).toSet();
    final planChapters = <ChapterRef>{for (final day in days) ...day.chapters};
    final completedPlanChaptersSet = readChapters.intersection(planChapters);

    final completedByBook = <String, int>{};
    final totalByBook = <String, int>{};
    for (final ref in planChapters) {
      if (!selectedBookIds.contains(ref.bookId)) continue;
      totalByBook[ref.bookId] = (totalByBook[ref.bookId] ?? 0) + 1;
    }
    for (final ref in completedPlanChaptersSet) {
      completedByBook[ref.bookId] = (completedByBook[ref.bookId] ?? 0) + 1;
    }

    var oldTotal = 0;
    var oldCompleted = 0;
    var newTotal = 0;
    var newCompleted = 0;
    var deuteroTotal = 0;
    var deuteroCompleted = 0;
    final bookProgress = <BookPlanProgress>[];
    final completedBooks = <BibleBook>[];
    final notStartedBooks = <BibleBook>[];

    for (final book in selectedBooks) {
      final total = totalByBook[book.id] ?? 0;
      final completed = completedByBook[book.id] ?? 0;
      final progress = BookPlanProgress(
        book: book,
        completedChapters: completed,
        totalChapters: total,
      );
      bookProgress.add(progress);

      if (book.testament == Testament.oldTestament) {
        oldTotal += total;
        oldCompleted += completed;
      } else {
        newTotal += total;
        newCompleted += completed;
      }
      if (book.isDeuterocanonical) {
        deuteroTotal += total;
        deuteroCompleted += completed;
      }
      if (progress.isCompleted) {
        completedBooks.add(book);
      } else if (progress.isNotStarted) {
        notStartedBooks.add(book);
      }
    }

    final totalPlanChapters = planChapters.length;
    final completedPlanChapters = completedPlanChaptersSet.length;

    return PlanStatistics(
      totalPlanChapters: totalPlanChapters,
      completedPlanChapters: completedPlanChapters,
      remainingPlanChapters: totalPlanChapters - completedPlanChapters,
      completionPercent: totalPlanChapters == 0
          ? 0
          : completedPlanChapters / totalPlanChapters * 100,
      oldTestamentTotal: oldTotal,
      oldTestamentCompleted: oldCompleted,
      newTestamentTotal: newTotal,
      newTestamentCompleted: newCompleted,
      deuterocanonicalTotal: deuteroTotal,
      deuterocanonicalCompleted: deuteroCompleted,
      bookProgress: bookProgress,
      fullyCompletedSelectedBooks: completedBooks,
      notStartedSelectedBooks: notStartedBooks,
    );
  }

  static List<BibleBook> _selectedBooks(ReadingPlan plan) {
    final selected = plan.selectedBookIds.toSet();
    return kBibleBooks.where((book) => selected.contains(book.id)).toList();
  }
}
