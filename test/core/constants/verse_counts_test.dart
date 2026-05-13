import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/verse_counts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Coverage of kBibleBooks ───────────────────────────────────────────────

  group('kVerseCountsByBook covers all kBibleBooks', () {
    test('every book has an entry', () {
      for (final book in kBibleBooks) {
        expect(
          kVerseCountsByBook.containsKey(book.id),
          isTrue,
          reason: 'Book "${book.id}" (${book.name}) missing from kVerseCountsByBook',
        );
      }
    });

    test('every book has exactly chapterCount verse entries', () {
      for (final book in kBibleBooks) {
        final counts = kVerseCountsByBook[book.id]!;
        expect(
          counts.length,
          book.chapterCount,
          reason: '${book.id}: expected ${book.chapterCount} entries, '
              'got ${counts.length}',
        );
      }
    });

    test('every verse count is > 0', () {
      for (final entry in kVerseCountsByBook.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          expect(
            entry.value[i],
            greaterThan(0),
            reason: '${entry.key} chapter ${i + 1}: '
                'verse count must be > 0, got ${entry.value[i]}',
          );
        }
      }
    });

    test('total verse count across all books is > 0', () {
      final total = kVerseCountsByBook.values.fold<int>(
        0,
        (sum, counts) => sum + counts.reduce((a, b) => a + b),
      );
      expect(total, greaterThan(0));
    });

    test('no extra entries beyond the 73 Catholic books', () {
      final bookIds = {for (final b in kBibleBooks) b.id};
      for (final key in kVerseCountsByBook.keys) {
        expect(
          bookIds.contains(key),
          isTrue,
          reason: 'Key "$key" in kVerseCountsByBook has no matching BibleBook',
        );
      }
    });
  });

  // ── verseCountForChapter ──────────────────────────────────────────────────

  group('verseCountForChapter', () {
    test('returns correct count for Genesis 1 (31 verses)', () {
      expect(verseCountForChapter('gen', 1), 31);
    });

    test('returns correct count for Genesis 50 (last chapter)', () {
      expect(verseCountForChapter('gen', 50), 26);
    });

    test('returns correct count for Psalm 119 (176 verses)', () {
      expect(verseCountForChapter('ps', 119), 176);
    });

    test('returns correct count for Psalm 117 (shortest psalm, 2 verses)', () {
      expect(verseCountForChapter('ps', 117), 2);
    });

    test('returns correct count for Obadiah 1 (21 verses, only chapter)', () {
      expect(verseCountForChapter('obad', 1), 21);
    });

    test('returns correct count for Philemon 1 (25 verses, only chapter)', () {
      expect(verseCountForChapter('phlm', 1), 25);
    });

    test('throws StateError for unknown book', () {
      expect(
        () => verseCountForChapter('xyz', 1),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('xyz'),
          ),
        ),
      );
    });

    test('throws RangeError for chapter 0', () {
      expect(
        () => verseCountForChapter('gen', 0),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for chapter beyond chapterCount', () {
      // Genesis has 50 chapters; asking for 51 must throw.
      expect(
        () => verseCountForChapter('gen', 51),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for negative chapter', () {
      expect(
        () => verseCountForChapter('gen', -1),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
