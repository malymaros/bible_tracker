import 'package:bible_tracker/core/utils/chapter_count_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatChapterCount', () {
    test('1 → kapitola', () {
      expect(formatChapterCount(1), '1 kapitola');
    });

    test('2 → kapitoly', () {
      expect(formatChapterCount(2), '2 kapitoly');
    });

    test('3 → kapitoly', () {
      expect(formatChapterCount(3), '3 kapitoly');
    });

    test('4 → kapitoly', () {
      expect(formatChapterCount(4), '4 kapitoly');
    });

    test('5 → kapitol', () {
      expect(formatChapterCount(5), '5 kapitol');
    });

    test('11 → kapitol (teen override)', () {
      expect(formatChapterCount(11), '11 kapitol');
    });

    test('12 → kapitol (teen override)', () {
      expect(formatChapterCount(12), '12 kapitol');
    });

    test('14 → kapitol (teen override)', () {
      expect(formatChapterCount(14), '14 kapitol');
    });

    test('21 → kapitol (ends in 1, not exactly 1)', () {
      expect(formatChapterCount(21), '21 kapitol');
    });

    test('22 → kapitoly (ends in 2, not a teen)', () {
      expect(formatChapterCount(22), '22 kapitoly');
    });

    test('24 → kapitoly (ends in 4, not a teen)', () {
      expect(formatChapterCount(24), '24 kapitoly');
    });

    test('25 → kapitol', () {
      expect(formatChapterCount(25), '25 kapitol');
    });

    test('100 → kapitol', () {
      expect(formatChapterCount(100), '100 kapitol');
    });

    test('112 → kapitol (teen in hundreds)', () {
      expect(formatChapterCount(112), '112 kapitol');
    });

    test('122 → kapitoly (ends in 2, mod100=22, not teen)', () {
      expect(formatChapterCount(122), '122 kapitoly');
    });
  });
}
