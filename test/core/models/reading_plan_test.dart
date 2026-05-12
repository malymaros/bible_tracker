import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingPlan', () {
    test('startDate time component is stripped', () {
      final plan = ReadingPlan(
        id: 'p1',
        startDate: DateTime(2024, 6, 15, 14, 30, 59),
        totalDays: 30,
        selectedBookIds: const ['gen'],
        createdAt: DateTime(2024, 6, 15),
      );
      expect(plan.startDate, DateTime(2024, 6, 15));
      expect(plan.startDate.hour, 0);
      expect(plan.startDate.minute, 0);
      expect(plan.startDate.second, 0);
    });

    test('selectedBookIds is immutable after construction', () {
      final mutable = ['gen', 'exod'];
      final plan = ReadingPlan(
        id: 'p1',
        startDate: DateTime(2024, 1, 1),
        totalDays: 30,
        selectedBookIds: mutable,
        createdAt: DateTime(2024, 1, 1),
      );

      mutable.add('lev');
      expect(plan.selectedBookIds.length, 2,
          reason: 'Mutating the original list must not affect the plan');

      expect(() => plan.selectedBookIds.add('lev'), throwsUnsupportedError,
          reason: 'Direct mutation of plan.selectedBookIds must be rejected');
    });

    test('fields are stored as provided', () {
      final created = DateTime(2024, 3, 10);
      final plan = ReadingPlan(
        id: 'abc-123',
        startDate: DateTime(2024, 3, 10),
        totalDays: 365,
        selectedBookIds: const ['gen', 'matt'],
        createdAt: created,
      );
      expect(plan.id, 'abc-123');
      expect(plan.totalDays, 365);
      expect(plan.selectedBookIds, ['gen', 'matt']);
      expect(plan.createdAt, created);
    });
  });
}
