import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/rosary.dart';
import 'package:bible_tracker/core/models/rosary.dart';

/// Pure business logic for the Rosary feature (no Flutter imports).
abstract final class RosaryService {
  /// Number of steps of the guided prayer: 7 intro + 5 × 14 decade + 2 closing.
  static const int stepCount = 79;

  /// The rosary prayed on [weekday] (`DateTime.weekday`, 1 = Monday).
  static Rosary forWeekday(int weekday) {
    return kRosaries.firstWhere(
      (r) => r.weekdays.contains(weekday),
      orElse: () => throw ArgumentError.value(weekday, 'weekday'),
    );
  }

  /// "Zvestovanie · Navštívenie Alžbety · …" for the rosary list.
  static String mysteryShortList(Rosary rosary) =>
      rosary.mysteries.map((m) => m.shortName).join(' · ');

  /// Formats [ref] like "Lk 1,26-38" or "Jn 19,1".
  static String formatRef(ScriptureRef ref) {
    final book = kBibleBooks.firstWhere((b) => b.id == ref.bookId);
    final verses = ref.verseEnd == null
        ? '${ref.verseStart}'
        : '${ref.verseStart}-${ref.verseEnd}';
    return '${book.shortName} ${ref.chapter},$verses';
  }

  static PrayerText _hailMary(String insert) => PrayerText(
    kPrayerHailMaryBefore,
    insert: insert,
    after: kPrayerHailMaryAfter,
  );

  /// The full step-by-step sequence of the guided prayer for [rosary].
  static List<RosaryStep> buildSteps(Rosary rosary) {
    final steps = <RosaryStep>[
      const RosaryStep(
        stage: RosaryStage.intro,
        stageLabel: kRosaryStageIntro,
        title: kRosaryNameSignOfCross,
        text: PrayerText(kPrayerSignOfCross),
      ),
      const RosaryStep(
        stage: RosaryStage.intro,
        stageLabel: '$kRosaryStageIntro · $kRosarySubCrucifix',
        title: kRosaryNameCreed,
        text: PrayerText(kPrayerCreed),
      ),
      const RosaryStep(
        stage: RosaryStage.intro,
        stageLabel: '$kRosaryStageIntro · $kRosarySubLargeBead',
        title: kRosaryNameOurFather,
        text: PrayerText(kPrayerOurFather),
      ),
      for (var k = 0; k < kRosaryIntroInserts.length; k++)
        RosaryStep(
          stage: RosaryStage.intro,
          stageLabel: kRosaryStageIntro,
          title: '$kRosaryNameHailMary · ${k + 1}/3',
          text: _hailMary(kRosaryIntroInserts[k]),
          bead: k + 1,
          beadCount: 3,
        ),
      const RosaryStep(
        stage: RosaryStage.intro,
        stageLabel: kRosaryStageIntro,
        title: kRosaryNameGloryBe,
        text: PrayerText(kPrayerGloryBe),
        bead: 4,
        beadCount: 3,
      ),
    ];

    for (final m in rosary.mysteries) {
      final d = m.number;
      final stage = '$kRosaryStageDecade $d z 5';
      RosaryStep step(String title, PrayerText text, {int bead = 0}) =>
          RosaryStep(
            stage: RosaryStage.decade,
            stageLabel: stage,
            decade: d,
            title: title,
            text: text,
            bead: bead,
            beadCount: bead == 0 ? 0 : 10,
          );
      steps
        ..add(
          step(
            '$d. ${rosary.mysteryLabel}',
            PrayerText('${m.name}. $kRosaryMeditationHint'),
          ),
        )
        ..add(step(kRosaryNameOurFather, const PrayerText(kPrayerOurFather)))
        ..addAll([
          for (var k = 1; k <= 10; k++)
            step('$kRosaryNameHailMary · $k/10', _hailMary(m.insert), bead: k),
        ])
        ..add(
          step(kRosaryNameGloryBe, const PrayerText(kPrayerGloryBe), bead: 11),
        )
        ..add(
          step(kRosaryNameFatima, const PrayerText(kPrayerFatima), bead: 11),
        );
    }

    steps.addAll(const [
      RosaryStep(
        stage: RosaryStage.closing,
        stageLabel: kRosaryStageClosing,
        title: kRosaryNameHailHolyQueen,
        text: PrayerText(kPrayerHailHolyQueen),
      ),
      RosaryStep(
        stage: RosaryStage.closing,
        stageLabel: kRosaryStageClosing,
        title: kRosaryNameSignOfCross,
        text: PrayerText(kPrayerSignOfCross),
      ),
    ]);
    return steps;
  }

  /// The "Postup modlitby" overview for the detail screen of [rosary].
  static List<RosaryOrderGroup> buildPrayerOrder(Rosary rosary) {
    final first = rosary.mysteries.first;
    return [
      RosaryOrderGroup(
        name: kRosaryStageIntro,
        items: [
          const RosaryOrderItem(
            id: 'kriz1',
            name: kRosaryNameSignOfCross,
            text: PrayerText(kPrayerSignOfCross),
          ),
          const RosaryOrderItem(
            id: 'verim',
            name: kRosaryNameCreed,
            sub: kRosarySubCrucifix,
            text: PrayerText(kPrayerCreed),
          ),
          const RosaryOrderItem(
            id: 'otce1',
            name: kRosaryNameOurFather,
            sub: kRosarySubLargeBead,
            text: PrayerText(kPrayerOurFather),
          ),
          RosaryOrderItem(
            id: 'zd3',
            count: '3×',
            name: kRosaryNameHailMary,
            sub: kRosarySubIntroHailMary,
            text: _hailMary(kRosaryIntroInserts[0]),
            note:
                '2. … ${kRosaryIntroInserts[1]}\n'
                '3. … ${kRosaryIntroInserts[2]}',
          ),
          const RosaryOrderItem(
            id: 'slava1',
            name: kRosaryNameGloryBe,
            text: PrayerText(kPrayerGloryBe),
          ),
        ],
      ),
      RosaryOrderGroup(
        name: kRosaryStageDecade,
        badge: '5×',
        items: [
          RosaryOrderItem(
            id: 'ohlas',
            name: kRosaryNameAnnouncement,
            sub: 'napr. „1. ${rosary.mysteryLabel}: ${first.name}“',
            strong: true,
            text: PrayerText(
              'Pred každým desiatkom sa ohlási tajomstvo, napríklad '
              '„Prvé ${rosary.mysteryLabel}: ${first.name}“. Je dobré krátko '
              'sa nad ním zamyslieť alebo si prečítať úryvok z Písma.',
            ),
          ),
          const RosaryOrderItem(
            id: 'otce2',
            name: kRosaryNameOurFather,
            text: PrayerText(kPrayerOurFather),
          ),
          RosaryOrderItem(
            id: 'zd10',
            count: '10×',
            name: kRosaryNameHailMary,
            sub: kRosarySubDecadeHailMary,
            text: _hailMary(first.insert),
            note: kRosaryDecadeInsertNote,
          ),
          const RosaryOrderItem(
            id: 'slava2',
            name: kRosaryNameGloryBe,
            text: PrayerText(kPrayerGloryBe),
          ),
          const RosaryOrderItem(
            id: 'oj',
            name: kRosaryNameFatima,
            text: PrayerText(kPrayerFatima),
          ),
        ],
      ),
      const RosaryOrderGroup(
        name: kRosaryStageClosing,
        items: [
          RosaryOrderItem(
            id: 'kralovna',
            name: kRosaryNameHailHolyQueen,
            text: PrayerText(kPrayerHailHolyQueen),
          ),
          RosaryOrderItem(
            id: 'kriz2',
            name: kRosaryNameSignOfCross,
            text: PrayerText(kPrayerSignOfCross),
          ),
        ],
      ),
    ];
  }
}
