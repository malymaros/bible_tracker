import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/verse_counts.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/services/plan_generator.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BibleBook _book(String id) => kBibleBooks.firstWhere((b) => b.id == id);

int _totalVerses(Iterable<ChapterRef> chapters) => chapters.fold(
      0,
      (sum, c) => sum + verseCountForChapter(c.bookId, c.chapterNumber),
    );

int _bookVerseTotal(String bookId) =>
    kVerseCountsByBook[bookId]!.reduce((a, b) => a + b);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final genesis = _book('gen');   // 50 chapters
  final exodus = _book('exod');   // 40 chapters
  final matthew = _book('matt');  // 28 chapters
  final obadiah = _book('obad');  //  1 chapter
  final psalms = _book('ps');     // 150 chapters (highly uneven verse lengths)

  const planId = 'test-plan';
  final anyDate = DateTime(2024, 1, 1);

  // ── 1-day plan ────────────────────────────────────────────────────────────

  group('1-day plan', () {
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 1,
      selectedBooks: kBibleBooks,
    );

    test('contains exactly one day', () {
      expect(days.length, 1);
    });

    test('that day contains all 1334 chapters', () {
      expect(days.first.chapters.length, 1334);
    });

    test('first chapter is Genesis 1', () {
      expect(days.first.chapters.first, const ChapterRef('gen', 1));
    });

    test('last chapter is Revelation 22', () {
      expect(days.first.chapters.last, const ChapterRef('rev', 22));
    });
  });

  // ── 365-day full Bible plan ───────────────────────────────────────────────

  group('365-day full Bible plan', () {
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 365,
      selectedBooks: kBibleBooks,
    );

    test('has exactly 365 days', () {
      expect(days.length, 365);
    });

    test('no day is empty', () {
      for (final d in days) {
        expect(d.chapters, isNotEmpty, reason: 'Day ${d.dayNumber} is empty');
      }
    });

    test('total assigned chapters equals 1334', () {
      final total = days.fold<int>(0, (sum, d) => sum + d.chapters.length);
      expect(total, 1334);
    });

    test('total assigned verses equals full-Bible verse total', () {
      final assigned = days.fold<int>(0, (s, d) => s + _totalVerses(d.chapters));
      final expected = kVerseCountsByBook.values
          .fold<int>(0, (s, c) => s + c.reduce((a, b) => a + b));
      expect(assigned, expected);
    });

    test('chapters are in canonical SSV order across all days', () {
      final flat = [for (final d in days) ...d.chapters];
      expect(flat, ChapterCursor.full.toList());
    });

    test('no duplicate chapters', () {
      final flat = [for (final d in days) ...d.chapters];
      expect(flat.toSet().length, flat.length);
    });
  });

  // ── Chapter accounting ────────────────────────────────────────────────────

  group('chapter accounting (full Bible, 90 days)', () {
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 90,
      selectedBooks: kBibleBooks,
    );

    test('total assigned chapters equals 1334', () {
      final total = days.fold<int>(0, (sum, d) => sum + d.chapters.length);
      expect(total, 1334);
    });

    test('no duplicate chapters', () {
      final flat = [for (final d in days) ...d.chapters];
      expect(
        flat.toSet().length,
        flat.length,
        reason: 'Every chapter must appear exactly once',
      );
    });

    test('chapters are in canonical SSV order across all days', () {
      final flat = [for (final d in days) ...d.chapters];
      final expected = ChapterCursor.full.toList();
      expect(flat, expected);
    });
  });

  // ── Verse-based distribution ──────────────────────────────────────────────

  group('verse-based distribution', () {
    test('total assigned verses equals selected verses (Genesis, 10 days)', () {
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 10,
        selectedBooks: [genesis],
      );
      final assigned = days.fold<int>(0, (s, d) => s + _totalVerses(d.chapters));
      expect(assigned, _bookVerseTotal('gen'));
    });

    test('no day is empty (Genesis, 10 days)', () {
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 10,
        selectedBooks: [genesis],
      );
      for (final d in days) {
        expect(d.chapters, isNotEmpty, reason: 'Day ${d.dayNumber} is empty');
      }
    });

    test(
        'verse mode reduces imbalance vs pure chapter-count split '
        '(Psalms, 2 days)', () {
      // Psalms has highly uneven chapter lengths: Ps 117 = 2 verses,
      // Ps 119 = 176 verses.  A naive 75/75 chapter split puts Ps 119 in
      // day 2 and creates a large verse imbalance (~138 verses).
      // Verse mode should produce an imbalance well below that.
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 2,
        selectedBooks: [psalms],
      );

      final d1 = _totalVerses(days[0].chapters);
      final d2 = _totalVerses(days[1].chapters);
      final imbalance = (d1 - d2).abs();

      // Chapter-count split (75/75) yields ≈ 138-verse imbalance.
      // Verse mode must do better.
      expect(imbalance, lessThan(100));
    });

    test('output is deterministic', () {
      final days1 = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 90,
        selectedBooks: kBibleBooks,
      );
      final days2 = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 90,
        selectedBooks: kBibleBooks,
      );
      for (var i = 0; i < days1.length; i++) {
        expect(
          days1[i].chapters,
          days2[i].chapters,
          reason: 'Day ${i + 1} differs between two identical calls',
        );
      }
    });
  });

  // ── Cross-book boundary ───────────────────────────────────────────────────

  group('cross-book boundary (Genesis + Exodus, 3 days)', () {
    // Gen (50 ch) + Ex (40 ch) = 90 chapters.
    // The verse-based algorithm will still place some chapters from Genesis and
    // some from Exodus in day 2 because the first day cannot fit both books.
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 3,
      selectedBooks: [genesis, exodus],
    );

    test('day 1 contains only Genesis chapters', () {
      expect(days[0].chapters.every((c) => c.bookId == 'gen'), isTrue);
    });

    test('day 3 contains only Exodus chapters', () {
      expect(days[2].chapters.every((c) => c.bookId == 'exod'), isTrue);
    });

    test('day 2 spans the Genesis–Exodus boundary', () {
      final bookIds = {for (final c in days[1].chapters) c.bookId};
      expect(bookIds, containsAll(['gen', 'exod']));
    });

    test('total chapters is 90', () {
      final total = days.fold<int>(0, (s, d) => s + d.chapters.length);
      expect(total, 90);
    });

    test('no chapter skipped — all Genesis and Exodus chapters present', () {
      final flat = [for (final d in days) ...d.chapters];
      final genChapters = List.generate(50, (i) => ChapterRef('gen', i + 1));
      final exChapters = List.generate(40, (i) => ChapterRef('exod', i + 1));
      expect(flat, [...genChapters, ...exChapters]);
    });
  });

  // ── Selected subset ───────────────────────────────────────────────────────

  group('selected subset (Genesis + Matthew)', () {
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 2,
      selectedBooks: [genesis, matthew],
    );

    test('total chapters is 78', () {
      final total = days.fold<int>(0, (sum, d) => sum + d.chapters.length);
      expect(total, 78);
    });

    test('only selected book IDs appear', () {
      final bookIds = {
        for (final d in days) ...d.chapters.map((c) => c.bookId),
      };
      expect(bookIds, {'gen', 'matt'});
    });

    test('Genesis precedes Matthew (canonical order maintained)', () {
      final flat = [for (final d in days) ...d.chapters];
      final lastGen = flat.lastIndexWhere((c) => c.bookId == 'gen');
      final firstMatt = flat.indexWhere((c) => c.bookId == 'matt');
      expect(lastGen, lessThan(firstMatt));
    });

    test('books passed out of canonical order are reordered', () {
      final reversed = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 2,
        selectedBooks: [matthew, genesis],
      );
      expect(reversed.first.chapters.first, const ChapterRef('gen', 1));
    });
  });

  // ── totalDays == totalChapters boundary ───────────────────────────────────

  group('totalDays == totalChapters boundary', () {
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 1,
      selectedBooks: [obadiah],
    );

    test('produces exactly 1 day', () {
      expect(days.length, 1);
    });

    test('that day has exactly 1 chapter', () {
      expect(days.first.chapters.length, 1);
      expect(days.first.chapters.first, const ChapterRef('obad', 1));
    });
  });

  group('one chapter per day boundary (Genesis, 50 days)', () {
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 50,
      selectedBooks: [genesis],
    );

    test('each day has exactly 1 chapter', () {
      for (final d in days) {
        expect(
          d.chapters.length,
          1,
          reason: 'Day ${d.dayNumber} should have exactly 1 chapter',
        );
      }
    });

    test('chapters are assigned in order', () {
      for (var i = 0; i < 50; i++) {
        expect(days[i].chapters.single, ChapterRef('gen', i + 1));
      }
    });
  });

  // ── Error cases ───────────────────────────────────────────────────────────

  group('error cases', () {
    test('throws ArgumentError when totalDays > totalChapters', () {
      expect(
        () => PlanGenerator.generatePlan(
          planId: planId,
          startDate: anyDate,
          totalDays: 51,
          selectedBooks: [genesis],
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when selectedBooks is empty', () {
      expect(
        () => PlanGenerator.generatePlan(
          planId: planId,
          startDate: anyDate,
          totalDays: 30,
          selectedBooks: [],
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when totalDays is 0', () {
      expect(
        () => PlanGenerator.generatePlan(
          planId: planId,
          startDate: anyDate,
          totalDays: 0,
          selectedBooks: kBibleBooks,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when totalDays is negative', () {
      expect(
        () => PlanGenerator.generatePlan(
          planId: planId,
          startDate: anyDate,
          totalDays: -5,
          selectedBooks: kBibleBooks,
        ),
        throwsArgumentError,
      );
    });
  });

  // ── Scheduling (dates, planId, dayNumber) ─────────────────────────────────

  group('scheduling', () {
    test('scheduled dates are consecutive from startDate', () {
      final start = DateTime(2024, 3, 1);
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: start,
        totalDays: 5,
        selectedBooks: [genesis],
      );
      for (var i = 0; i < 5; i++) {
        expect(
          days[i].scheduledDate,
          start.add(Duration(days: i)),
          reason: 'Day ${i + 1} should be on ${start.add(Duration(days: i))}',
        );
      }
    });

    test('dayNumber is 1-based and sequential', () {
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 5,
        selectedBooks: [genesis],
      );
      for (var i = 0; i < 5; i++) {
        expect(days[i].dayNumber, i + 1);
      }
    });

    test('all days carry the provided planId', () {
      const id = 'my-unique-plan-id';
      final days = PlanGenerator.generatePlan(
        planId: id,
        startDate: anyDate,
        totalDays: 3,
        selectedBooks: [genesis],
      );
      expect(days.every((d) => d.planId == id), isTrue);
    });

    test('time component in startDate is stripped', () {
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: DateTime(2024, 6, 15, 23, 59, 59),
        totalDays: 1,
        selectedBooks: [genesis],
      );
      expect(days.first.scheduledDate, DateTime(2024, 6, 15));
    });

    test('start date in the past works', () {
      final past = DateTime(2015, 12, 25);
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: past,
        totalDays: 3,
        selectedBooks: [genesis],
      );
      expect(days.first.scheduledDate, DateTime(2015, 12, 25));
      expect(days.last.scheduledDate, DateTime(2015, 12, 27));
    });

    test('start date in the future works', () {
      final future = DateTime(2030, 12, 30);
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: future,
        totalDays: 3,
        selectedBooks: [genesis],
      );
      expect(days.first.scheduledDate, DateTime(2030, 12, 30));
      expect(days[1].scheduledDate, DateTime(2030, 12, 31));
      expect(days.last.scheduledDate, DateTime(2031, 1, 1));
    });

    test('dates cross month and year boundaries correctly', () {
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: DateTime(2024, 1, 30),
        totalDays: 4,
        selectedBooks: [genesis],
      );
      expect(days[0].scheduledDate, DateTime(2024, 1, 30));
      expect(days[1].scheduledDate, DateTime(2024, 1, 31));
      expect(days[2].scheduledDate, DateTime(2024, 2, 1));
      expect(days[3].scheduledDate, DateTime(2024, 2, 2));
    });
  });

  // ── PlanDay immutability ──────────────────────────────────────────────────

  group('PlanDay immutability', () {
    test('chapters list cannot be mutated after generation', () {
      final days = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 1,
        selectedBooks: [genesis],
      );
      expect(
        () => days.first.chapters.add(const ChapterRef('gen', 1)),
        throwsUnsupportedError,
      );
    });
  });
}
