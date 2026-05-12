import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/reading_stats.dart';

/// Pure stateless service. Computes [ReadingStats] from a set of read chapters
/// against the full 73-book Catholic Bible.
///
/// Any [ChapterRef] whose bookId does not exist in [kBibleBooks], or whose
/// chapterNumber exceeds the book's chapter count, is silently ignored.
abstract final class StatisticsCalculator {
  static ReadingStats calculate(Set<ChapterRef> readChapters) {
    // Build bookId → BibleBook lookup once.
    final bookMap = <String, BibleBook>{
      for (final b in kBibleBooks) b.id: b,
    };

    // Count valid read chapters per book.
    final completedPerBook = <String, int>{};
    for (final ref in readChapters) {
      final book = bookMap[ref.bookId];
      if (book == null) continue;
      if (ref.chapterNumber > book.chapterCount) continue;
      completedPerBook[ref.bookId] = (completedPerBook[ref.bookId] ?? 0) + 1;
    }

    // Accumulate stats by iterating kBibleBooks in canonical order.
    var totalChapters = 0;
    var completedChapters = 0;
    var otTotal = 0, otCompleted = 0;
    var ntTotal = 0, ntCompleted = 0;
    var deuteroTotal = 0, deuteroCompleted = 0;
    final fullyCompletedBooks = <BibleBook>[];
    final notStartedBooks = <BibleBook>[];

    for (final book in kBibleBooks) {
      totalChapters += book.chapterCount;
      final done = completedPerBook[book.id] ?? 0;
      completedChapters += done;

      if (book.testament == Testament.oldTestament) {
        otTotal += book.chapterCount;
        otCompleted += done;
      } else {
        ntTotal += book.chapterCount;
        ntCompleted += done;
      }

      if (book.isDeuterocanonical) {
        deuteroTotal += book.chapterCount;
        deuteroCompleted += done;
      }

      if (done == book.chapterCount) {
        fullyCompletedBooks.add(book);
      } else if (done == 0) {
        notStartedBooks.add(book);
      }
    }

    final completedBooksCount = fullyCompletedBooks.length;

    return ReadingStats(
      totalChapters: totalChapters,
      completedChapters: completedChapters,
      remainingChapters: totalChapters - completedChapters,
      completionPercent:
          totalChapters > 0 ? completedChapters / totalChapters * 100 : 0.0,
      oldTestamentTotal: otTotal,
      oldTestamentCompleted: otCompleted,
      newTestamentTotal: ntTotal,
      newTestamentCompleted: ntCompleted,
      deuterocanonicalTotal: deuteroTotal,
      deuterocanonicalCompleted: deuteroCompleted,
      completedBooksCount: completedBooksCount,
      remainingBooksCount: kBibleBooks.length - completedBooksCount,
      fullyCompletedBooks: fullyCompletedBooks,
      notStartedBooks: notStartedBooks,
    );
  }
}
