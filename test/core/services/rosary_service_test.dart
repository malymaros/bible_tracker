import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/rosary.dart';
import 'package:bible_tracker/core/models/rosary.dart';
import 'package:bible_tracker/core/services/rosary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RosaryService.forWeekday', () {
    const expected = {
      DateTime.monday: RosaryKind.joyful,
      DateTime.tuesday: RosaryKind.sorrowful,
      DateTime.wednesday: RosaryKind.glorious,
      DateTime.thursday: RosaryKind.luminous,
      DateTime.friday: RosaryKind.sorrowful,
      DateTime.saturday: RosaryKind.joyful,
      DateTime.sunday: RosaryKind.glorious,
    };

    for (final entry in expected.entries) {
      test('weekday ${entry.key} -> ${entry.value.name}', () {
        expect(RosaryService.forWeekday(entry.key).kind, entry.value);
      });
    }

    test('every weekday maps to exactly one rosary', () {
      for (var w = 1; w <= 7; w++) {
        expect(kRosaries.where((r) => r.weekdays.contains(w)), hasLength(1));
      }
    });
  });

  group('kRosaries content', () {
    test('four rosaries in display order, each with five mysteries', () {
      expect(kRosaries.map((r) => r.kind), [
        RosaryKind.joyful,
        RosaryKind.luminous,
        RosaryKind.sorrowful,
        RosaryKind.glorious,
      ]);
      for (final r in kRosaries) {
        expect(r.mysteries.map((m) => m.number), [1, 2, 3, 4, 5]);
      }
    });

    test('every mystery refers to an existing book and chapter', () {
      for (final r in kRosaries) {
        for (final m in r.mysteries) {
          final book = kBibleBooks.where((b) => b.id == m.ref.bookId);
          expect(book, hasLength(1), reason: '${m.name}: ${m.ref.bookId}');
          expect(m.ref.chapter, inInclusiveRange(1, book.single.chapterCount));
          expect(m.ref.verseStart, greaterThanOrEqualTo(1));
          if (m.ref.verseEnd != null) {
            expect(m.ref.verseEnd, greaterThan(m.ref.verseStart));
          }
        }
      }
    });

    test('formats references', () {
      final joyful = kRosaries.first;
      expect(RosaryService.formatRef(joyful.mysteries.first.ref), 'Lk 1,26-38');
      final scourging = kRosaries[2].mysteries[1];
      expect(RosaryService.formatRef(scourging.ref), 'Jn 19,1');
    });
  });

  group('RosaryService.buildSteps', () {
    final luminous = kRosaries.firstWhere((r) => r.kind == RosaryKind.luminous);
    final steps = RosaryService.buildSteps(luminous);

    test('has 79 steps', () {
      expect(steps, hasLength(RosaryService.stepCount));
      expect(RosaryService.stepCount, 79);
    });

    test('intro', () {
      expect(steps[0].title, 'Znamenie kríža');
      expect(steps[1].title, 'Verím v Boha');
      expect(steps[2].title, 'Otče náš');
      for (var k = 0; k < 3; k++) {
        expect(steps[3 + k].text.insert, kRosaryIntroInserts[k]);
        expect(steps[3 + k].bead, k + 1);
        expect(steps[3 + k].beadCount, 3);
      }
      expect(steps[6].title, 'Sláva Otcu');
      expect(steps.take(7).every((s) => s.stage == RosaryStage.intro), isTrue);
    });

    test('decades use the rosary mysteries', () {
      for (var d = 0; d < 5; d++) {
        final start = 7 + d * 14;
        final m = luminous.mysteries[d];
        expect(steps[start].title, '${d + 1}. tajomstvo svetla');
        expect(steps[start].text.before, startsWith(m.name));
        expect(steps[start].stageLabel, 'Desiatok ${d + 1} z 5');
        expect(steps[start + 1].title, 'Otče náš');
        for (var k = 0; k < 10; k++) {
          final s = steps[start + 2 + k];
          expect(s.text.insert, m.insert);
          expect(s.bead, k + 1);
          expect(s.beadCount, 10);
          expect(s.decade, d + 1);
        }
        expect(steps[start + 12].title, 'Sláva Otcu');
        expect(steps[start + 13].title, 'Ó, Ježišu');
      }
    });

    test('closing', () {
      expect(steps[77].title, 'Zdravas, Kráľovná');
      expect(steps[78].title, 'Znamenie kríža');
      expect(steps[78].stage, RosaryStage.closing);
    });
  });

  group('RosaryService.buildPrayerOrder', () {
    test('decade Hail Mary uses the first mystery of this rosary', () {
      final sorrowful = kRosaries[2];
      final groups = RosaryService.buildPrayerOrder(sorrowful);
      expect(groups.map((g) => g.name), ['Úvod', 'Desiatok', 'Záver']);
      expect(groups[1].badge, '5×');
      final zd10 = groups[1].items.firstWhere((i) => i.id == 'zd10');
      expect(zd10.text.insert, sorrowful.mysteries.first.insert);
      final zd3 = groups[0].items.firstWhere((i) => i.id == 'zd3');
      expect(zd3.text.insert, kRosaryIntroInserts.first);
      expect(zd3.note, contains(kRosaryIntroInserts[2]));
    });
  });
}
