import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChapterRef', () {
    group('equality', () {
      test('equal when bookId and chapterNumber match', () {
        expect(const ChapterRef('gen', 1), const ChapterRef('gen', 1));
      });

      test('not equal when bookId differs', () {
        expect(const ChapterRef('gen', 1), isNot(const ChapterRef('exod', 1)));
      });

      test('not equal when chapterNumber differs', () {
        expect(const ChapterRef('gen', 1), isNot(const ChapterRef('gen', 2)));
      });

      test('hashCode matches for equal refs', () {
        expect(
          const ChapterRef('gen', 1).hashCode,
          const ChapterRef('gen', 1).hashCode,
        );
      });

      test('hashCode differs for different refs', () {
        expect(
          const ChapterRef('gen', 1).hashCode,
          isNot(const ChapterRef('gen', 2).hashCode),
        );
      });

      test('usable as Map key', () {
        final map = {const ChapterRef('gen', 1): 'read'};
        expect(map[const ChapterRef('gen', 1)], 'read');
        expect(map[const ChapterRef('gen', 2)], isNull);
      });

      test('usable in Set', () {
        final set = <ChapterRef>{};
        set.add(const ChapterRef('gen', 1));
        set.add(const ChapterRef('gen', 1));
        expect(set.length, 1);
      });
    });

    group('toString', () {
      test('includes bookId and chapterNumber', () {
        expect(const ChapterRef('gen', 1).toString(), 'ChapterRef(gen, 1)');
      });
    });

    group('validation', () {
      test('chapterNumber of 0 throws AssertionError', () {
        expect(() => ChapterRef('gen', 0), throwsA(isA<AssertionError>()));
      });

      test('negative chapterNumber throws AssertionError', () {
        expect(() => ChapterRef('gen', -1), throwsA(isA<AssertionError>()));
      });

      test('empty bookId throws AssertionError', () {
        expect(() => ChapterRef('', 1), throwsA(isA<AssertionError>()));
      });

      test('chapterNumber of 1 is valid', () {
        expect(() => const ChapterRef('gen', 1), returnsNormally);
      });
    });
  });
}
