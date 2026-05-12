import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/services/plan_generator.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BibleBook _book(String id) => kBibleBooks.firstWhere((b) => b.id == id);

List<ChapterRef> _allChapters(List<dynamic> days) => [
      for (final d in days as List) ...(d as dynamic).chapters as List<ChapterRef>,
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Common books used across multiple tests
  final genesis = _book('gen');   // 50 chapters
  final exodus = _book('exod');   // 40 chapters
  final matthew = _book('matt');  // 28 chapters
  final obadiah = _book('obad'); //  1 chapter

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
    // 1334 ~/ 365 = 3 (base), 1334 % 365 = 239 (remainder)
    // Days 1–239 get 4 chapters; days 240–365 get 3.
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 365,
      selectedBooks: kBibleBooks,
    );

    test('has exactly 365 days', () {
      expect(days.length, 365);
    });

    test('first 239 days have 4 chapters', () {
      for (var i = 0; i < 239; i++) {
        expect(days[i].chapters.length, 4,
            reason: 'Day ${i + 1} should have 4 chapters');
      }
    });

    test('remaining 126 days have 3 chapters', () {
      for (var i = 239; i < 365; i++) {
        expect(days[i].chapters.length, 3,
            reason: 'Day ${i + 1} should have 3 chapters');
      }
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
      expect(flat.toSet().length, flat.length,
          reason: 'Every chapter must appear exactly once');
    });

    test('chapters are in canonical SSV order across all days', () {
      final flat = [for (final d in days) ...d.chapters];
      final expected = ChapterCursor.full.toList();
      expect(flat, expected);
    });
  });

  // ── Remainder distribution ────────────────────────────────────────────────

  group('remainder distribution', () {
    // Genesis: 50 chapters, 7 days → base=7, remainder=1
    // Day 1 gets 8 chapters; days 2–7 get 7 each.
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 7,
      selectedBooks: [genesis],
    );

    test('first day has base + 1 chapters when remainder is 1', () {
      expect(days[0].chapters.length, 8);
    });

    test('subsequent days have base chapters', () {
      for (var i = 1; i < 7; i++) {
        expect(days[i].chapters.length, 7,
            reason: 'Day ${i + 1} should have 7 chapters');
      }
    });

    test('total is still 50 after distribution', () {
      final total = days.fold<int>(0, (sum, d) => sum + d.chapters.length);
      expect(total, 50);
    });
  });

  // ── Cross-book boundary ───────────────────────────────────────────────────

  group('cross-book boundary', () {
    // Genesis (50) + Exodus (40) = 90 chapters, 3 days = 30 per day.
    // Day 1: Gen 1–30.  Day 2: Gen 31–50 + Ex 1–10.  Day 3: Ex 11–40.
    late final days = PlanGenerator.generatePlan(
      planId: planId,
      startDate: anyDate,
      totalDays: 3,
      selectedBooks: [genesis, exodus],
    );

    test('day 2 contains last chapter of Genesis', () {
      expect(days[1].chapters.contains(const ChapterRef('gen', 50)), isTrue);
    });

    test('day 2 contains first chapter of Exodus', () {
      expect(days[1].chapters.contains(const ChapterRef('exod', 1)), isTrue);
    });

    test('day 1 stays within Genesis', () {
      expect(days[0].chapters.every((c) => c.bookId == 'gen'), isTrue);
    });

    test('day 3 stays within Exodus', () {
      expect(days[2].chapters.every((c) => c.bookId == 'exod'), isTrue);
    });
  });

  // ── Selected subset ───────────────────────────────────────────────────────

  group('selected subset (Genesis + Matthew)', () {
    // Genesis: 50 ch, Matthew: 28 ch → total 78 ch, 2 days = 39 each.
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
      // Pass Matthew before Genesis — plan must still start with Genesis.
      final reversed = PlanGenerator.generatePlan(
        planId: planId,
        startDate: anyDate,
        totalDays: 2,
        selectedBooks: [matthew, genesis],
      );
      expect(reversed.first.chapters.first, const ChapterRef('gen', 1));
    });
  });

  // ── totalDays equals totalChapters (boundary) ─────────────────────────────

  group('totalDays == totalChapters boundary', () {
    // Obadiah has exactly 1 chapter.
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

  // ── Error cases ───────────────────────────────────────────────────────────

  group('error cases', () {
    test('throws ArgumentError when totalDays > totalChapters', () {
      // Genesis has 50 chapters; 51 days is too many.
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
        expect(days[i].scheduledDate, start.add(Duration(days: i)),
            reason: 'Day ${i + 1} should be on ${start.add(Duration(days: i))}');
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
