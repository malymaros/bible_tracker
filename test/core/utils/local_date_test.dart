import 'package:bible_tracker/core/utils/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeToLocalMidnight', () {
    test('leaves a date already at midnight untouched', () {
      final d = DateTime(2026, 9, 25);
      expect(normalizeToLocalMidnight(d), d);
    });

    test('rounds an early-morning time down to the same day', () {
      expect(
        normalizeToLocalMidnight(DateTime(2026, 3, 30, 1)),
        DateTime(2026, 3, 30),
      );
    });

    test('rounds a late-evening time up to the next day', () {
      expect(
        normalizeToLocalMidnight(DateTime(2026, 10, 25, 23)),
        DateTime(2026, 10, 26),
      );
    });

    test('is idempotent', () {
      final once = normalizeToLocalMidnight(DateTime(2026, 10, 25, 23));
      expect(normalizeToLocalMidnight(once), once);
    });
  });
}
