import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/services/statistics_calculator.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All chapters of [bookId] as a Set.
Set<ChapterRef> _allOf(String bookId) {
  final book = kBibleBooks.firstWhere((b) => b.id == bookId);
  return {for (var i = 1; i <= book.chapterCount; i++) ChapterRef(bookId, i)};
}

/// Every chapter of every Bible book.
Set<ChapterRef> get _allBibleChapters => {
      for (final b in kBibleBooks)
        for (var i = 1; i <= b.chapterCount; i++) ChapterRef(b.id, i),
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('StatisticsCalculator — empty progress', () {
    late final stats = StatisticsCalculator.calculate({});

    test('totalChapters is 1334', () => expect(stats.totalChapters, 1334));
    test('completedChapters is 0', () => expect(stats.completedChapters, 0));
    test('remainingChapters is 1334', () => expect(stats.remainingChapters, 1334));
    test('completionPercent is 0.0', () => expect(stats.completionPercent, 0.0));
    test('completedBooksCount is 0', () => expect(stats.completedBooksCount, 0));
    test('remainingBooksCount is 73', () => expect(stats.remainingBooksCount, 73));
    test('fullyCompletedBooks is empty', () => expect(stats.fullyCompletedBooks, isEmpty));
    test('all 73 books are notStarted', () => expect(stats.notStartedBooks.length, 73));
    test('OT completed is 0', () => expect(stats.oldTestamentCompleted, 0));
    test('NT completed is 0', () => expect(stats.newTestamentCompleted, 0));
    test('deuterocanonical completed is 0', () => expect(stats.deuterocanonicalCompleted, 0));
  });

  group('StatisticsCalculator — full Bible completed', () {
    late final stats = StatisticsCalculator.calculate(_allBibleChapters);

    test('completedChapters is 1334', () => expect(stats.completedChapters, 1334));
    test('remainingChapters is 0', () => expect(stats.remainingChapters, 0));
    test('completionPercent is 100.0', () => expect(stats.completionPercent, 100.0));
    test('completedBooksCount is 73', () => expect(stats.completedBooksCount, 73));
    test('remainingBooksCount is 0', () => expect(stats.remainingBooksCount, 0));
    test('fullyCompletedBooks contains all 73 books', () {
      expect(stats.fullyCompletedBooks.length, 73);
    });
    test('notStartedBooks is empty', () => expect(stats.notStartedBooks, isEmpty));
    test('OT completed equals OT total', () {
      expect(stats.oldTestamentCompleted, stats.oldTestamentTotal);
    });
    test('NT completed equals NT total', () {
      expect(stats.newTestamentCompleted, stats.newTestamentTotal);
    });
    test('deuterocanonical completed equals deuterocanonical total', () {
      expect(stats.deuterocanonicalCompleted, stats.deuterocanonicalTotal);
    });
  });

  group('StatisticsCalculator — invalid ChapterRef is ignored', () {
    test('unknown bookId is ignored, valid chapters still count', () {
      final stats = StatisticsCalculator.calculate({
        const ChapterRef('gen', 1),
        const ChapterRef('unknown-book', 1),
      });
      expect(stats.completedChapters, 1);
    });

    test('chapterNumber beyond book limit is ignored', () {
      // Genesis has 50 chapters; chapter 51 is invalid.
      final stats = StatisticsCalculator.calculate({
        const ChapterRef('gen', 1),
        const ChapterRef('gen', 51),
      });
      expect(stats.completedChapters, 1);
    });

    test('only invalid refs — completedChapters stays 0', () {
      final stats = StatisticsCalculator.calculate({
        const ChapterRef('fake-id', 1),
        const ChapterRef('gen', 999),
      });
      expect(stats.completedChapters, 0);
      expect(stats.notStartedBooks.length, 73);
    });
  });

  group('StatisticsCalculator — OT / NT split', () {
    // OT total: 1074 chapters (46 books), NT total: 260 chapters (27 books).
    late final stats = StatisticsCalculator.calculate({
      const ChapterRef('gen', 1), // OT
      const ChapterRef('gen', 2), // OT
      const ChapterRef('matt', 1), // NT
    });

    test('oldTestamentTotal is 1074', () => expect(stats.oldTestamentTotal, 1074));
    test('newTestamentTotal is 260', () => expect(stats.newTestamentTotal, 260));
    test('OT and NT totals sum to 1334', () {
      expect(stats.oldTestamentTotal + stats.newTestamentTotal, 1334);
    });
    test('oldTestamentCompleted is 2', () => expect(stats.oldTestamentCompleted, 2));
    test('newTestamentCompleted is 1', () => expect(stats.newTestamentCompleted, 1));
  });

  group('StatisticsCalculator — deuterocanonical stats', () {
    // Tobit(14) + Judith(16) + 1Macc(16) + 2Macc(15) +
    // Wisdom(19) + Sirach(51) + Baruch(6) = 137 chapters.
    test('deuterocanonicalTotal is 137', () {
      expect(StatisticsCalculator.calculate({}).deuterocanonicalTotal, 137);
    });

    test('reading a deuterocanonical chapter increments its counter', () {
      final stats = StatisticsCalculator.calculate({
        const ChapterRef('tob', 1), // Tobit — deuterocanonical
        const ChapterRef('gen', 1), // Genesis — not deuterocanonical
      });
      expect(stats.deuterocanonicalCompleted, 1);
    });

    test('reading all deuterocanonical chapters fills deuterocanonicalCompleted', () {
      final deuteroIds =
          kBibleBooks.where((b) => b.isDeuterocanonical).map((b) => b.id);
      final read = {for (final id in deuteroIds) ..._allOf(id)};
      final stats = StatisticsCalculator.calculate(read);
      expect(stats.deuterocanonicalCompleted, 137);
    });
  });

  group('StatisticsCalculator — completed books count', () {
    test('completing one book increments completedBooksCount', () {
      final stats = StatisticsCalculator.calculate(_allOf('gen'));
      expect(stats.completedBooksCount, 1);
      expect(stats.fullyCompletedBooks.first.id, 'gen');
      expect(stats.remainingBooksCount, 72);
    });

    test('partial completion does not mark book as fully completed', () {
      // Genesis has 50 chapters; read only 49.
      final partial = {for (var i = 1; i <= 49; i++) ChapterRef('gen', i)};
      final stats = StatisticsCalculator.calculate(partial);
      expect(stats.completedBooksCount, 0);
      expect(stats.fullyCompletedBooks, isEmpty);
    });

    test('completing several books counts them all', () {
      final read = {
        ..._allOf('gen'),  // 50 chapters
        ..._allOf('obad'), //  1 chapter (Obadiah)
        ..._allOf('phlm'), //  1 chapter (Philemon)
      };
      final stats = StatisticsCalculator.calculate(read);
      expect(stats.completedBooksCount, 3);
      expect(stats.fullyCompletedBooks.map((b) => b.id).toSet(),
          {'gen', 'obad', 'phlm'});
    });

    test('fullyCompletedBooks are in canonical SSV order', () {
      // Obadiah (order 36) must appear before Philemon (order 64).
      final read = {..._allOf('phlm'), ..._allOf('obad')};
      final stats = StatisticsCalculator.calculate(read);
      final ids = stats.fullyCompletedBooks.map((b) => b.id).toList();
      expect(ids.indexOf('obad'), lessThan(ids.indexOf('phlm')));
    });
  });

  group('StatisticsCalculator — not started books', () {
    test('reading one chapter removes that book from notStartedBooks', () {
      final stats = StatisticsCalculator.calculate({const ChapterRef('gen', 1)});
      expect(stats.notStartedBooks.length, 72);
      expect(stats.notStartedBooks.any((b) => b.id == 'gen'), isFalse);
    });

    test('partially read books are neither completed nor not-started', () {
      final stats = StatisticsCalculator.calculate({const ChapterRef('gen', 1)});
      // 72 not started, 0 fully completed → Genesis is "in progress"
      expect(stats.notStartedBooks.length, 72);
      expect(stats.fullyCompletedBooks, isEmpty);
    });
  });

  group('StatisticsCalculator — completionPercent', () {
    test('one chapter → ~0.0749%', () {
      final stats = StatisticsCalculator.calculate({const ChapterRef('gen', 1)});
      expect(stats.completionPercent, closeTo(1 / 1334 * 100, 0.001));
    });

    test('first 667 chapters → ~49.96%', () {
      final first667 =
          ChapterCursor.full.toList().take(667).toSet();
      final stats = StatisticsCalculator.calculate(first667);
      expect(stats.completionPercent, closeTo(667 / 1334 * 100, 0.001));
    });
  });
}
