import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChapterCursor.full', () {
    final cursor = ChapterCursor.full;

    test('total chapter count is 1334', () {
      expect(cursor.totalChapters, 1334);
    });

    test('first chapter is Genesis 1', () {
      expect(cursor.first, const ChapterRef('gen', 1));
    });

    test('last chapter is Revelation 22', () {
      expect(cursor.last, const ChapterRef('rev', 22));
    });

    test('Genesis 1 has no previous chapter', () {
      expect(cursor.previousOf(const ChapterRef('gen', 1)), isNull);
    });

    test('Revelation 22 has no next chapter', () {
      expect(cursor.nextOf(const ChapterRef('rev', 22)), isNull);
    });

    test('Genesis 50 next is Exodus 1 (OT book boundary)', () {
      expect(
        cursor.nextOf(const ChapterRef('gen', 50)),
        const ChapterRef('exod', 1),
      );
    });

    test('Exodus 1 previous is Genesis 50', () {
      expect(
        cursor.previousOf(const ChapterRef('exod', 1)),
        const ChapterRef('gen', 50),
      );
    });

    test('Matthew 1 previous is 2 Maccabees 15 (OT/NT boundary, SSV order)', () {
      // In SSV canonical order: 2 Maccabees (order 46) is the last OT book.
      expect(
        cursor.previousOf(const ChapterRef('matt', 1)),
        const ChapterRef('2macc', 15),
      );
    });

    test('2 Maccabees 15 next is Matthew 1 (OT/NT boundary, SSV order)', () {
      expect(
        cursor.nextOf(const ChapterRef('2macc', 15)),
        const ChapterRef('matt', 1),
      );
    });

    test('Malachi 3 next is 1 Maccabees 1 (Malachi is order 44)', () {
      expect(
        cursor.nextOf(const ChapterRef('mal', 3)),
        const ChapterRef('1macc', 1),
      );
    });

    group('indexOf', () {
      test('Genesis 1 is at index 0', () {
        expect(cursor.indexOf(const ChapterRef('gen', 1)), 0);
      });

      test('Revelation 22 is at last index', () {
        expect(cursor.indexOf(const ChapterRef('rev', 22)), 1333);
      });

      test('unknown bookId returns null', () {
        expect(cursor.indexOf(const ChapterRef('unknown', 1)), isNull);
      });

      test('chapter beyond book limit returns null', () {
        // Genesis has 50 chapters; chapter 51 does not exist.
        expect(cursor.indexOf(const ChapterRef('gen', 51)), isNull);
      });
    });

    group('contains', () {
      test('valid chapter returns true', () {
        expect(cursor.contains(const ChapterRef('gen', 1)), isTrue);
        expect(cursor.contains(const ChapterRef('rev', 22)), isTrue);
        expect(cursor.contains(const ChapterRef('ps', 150)), isTrue);
      });

      test('unknown bookId returns false', () {
        expect(cursor.contains(const ChapterRef('unknown', 1)), isFalse);
      });

      test('chapter number beyond book limit returns false', () {
        expect(cursor.contains(const ChapterRef('gen', 51)), isFalse);
      });

      test('chapter number beyond limit returns false for short book', () {
        // Obadiah has 1 chapter.
        expect(cursor.contains(const ChapterRef('obad', 2)), isFalse);
      });
    });

    group('operator []', () {
      test('index 0 returns Genesis 1', () {
        expect(cursor[0], const ChapterRef('gen', 1));
      });

      test('index 1333 returns Revelation 22', () {
        expect(cursor[1333], const ChapterRef('rev', 22));
      });
    });

    test('toList returns unmodifiable list of length 1334', () {
      final list = cursor.toList();
      expect(list.length, 1334);
      expect(() => (list as dynamic).add(const ChapterRef('gen', 1)),
          throwsUnsupportedError);
    });
  });

  group('ChapterCursor with selected books', () {
    // Genesis (50 ch) + Exodus (40 ch) only.
    final genesis = kBibleBooks.firstWhere((b) => b.id == 'gen');
    final exodus = kBibleBooks.firstWhere((b) => b.id == 'exod');
    final cursor = ChapterCursor([genesis, exodus]);

    test('total chapter count equals sum of selected books', () {
      expect(cursor.totalChapters, 90); // 50 + 40
    });

    test('first chapter is Genesis 1', () {
      expect(cursor.first, const ChapterRef('gen', 1));
    });

    test('last chapter is Exodus 40', () {
      expect(cursor.last, const ChapterRef('exod', 40));
    });

    test('Genesis 50 next is Exodus 1', () {
      expect(
        cursor.nextOf(const ChapterRef('gen', 50)),
        const ChapterRef('exod', 1),
      );
    });

    test('Exodus 1 previous is Genesis 50', () {
      expect(
        cursor.previousOf(const ChapterRef('exod', 1)),
        const ChapterRef('gen', 50),
      );
    });

    test('books outside selection are not contained', () {
      expect(cursor.contains(const ChapterRef('lev', 1)), isFalse);
      expect(cursor.contains(const ChapterRef('matt', 1)), isFalse);
    });

    test('books passed out of order are sorted by BibleBook.order', () {
      // Pass Exodus before Genesis — cursor must still start with Genesis.
      final reversed = ChapterCursor([exodus, genesis]);
      expect(reversed.first, const ChapterRef('gen', 1));
      expect(reversed.last, const ChapterRef('exod', 40));
    });
  });

  group('ChapterCursor with a single-chapter book', () {
    // Obadiah (id: obad) has exactly 1 chapter.
    final obad = kBibleBooks.firstWhere((b) => b.id == 'obad');
    final cursor = ChapterCursor([obad]);

    test('totalChapters is 1', () {
      expect(cursor.totalChapters, 1);
    });

    test('first and last are the same chapter', () {
      expect(cursor.first, cursor.last);
      expect(cursor.first, const ChapterRef('obad', 1));
    });

    test('nextOf the only chapter returns null', () {
      expect(cursor.nextOf(const ChapterRef('obad', 1)), isNull);
    });

    test('previousOf the only chapter returns null', () {
      expect(cursor.previousOf(const ChapterRef('obad', 1)), isNull);
    });
  });
}
