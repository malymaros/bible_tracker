/// Domain models for the Rosary (Ruženec) feature.
///
/// All instances are static content defined in
/// `core/constants/rosary.dart`; nothing here is persisted.
library;

enum RosaryKind { joyful, luminous, sorrowful, glorious }

/// A Bible passage reference: one chapter with an optional verse range.
class ScriptureRef {
  final String bookId;
  final int chapter;
  final int verseStart;

  /// Last verse of the range, or `null` for a single verse.
  final int? verseEnd;

  const ScriptureRef({
    required this.bookId,
    required this.chapter,
    required this.verseStart,
    this.verseEnd,
  });
}

class RosaryMystery {
  /// 1–5 within its rosary.
  final int number;

  /// Full name, e.g. "Zvestovanie Pána".
  final String name;

  /// Short name used in the rosary list, e.g. "Zvestovanie".
  final String shortName;

  /// Text inserted into the Hail Mary after "Ježiš, ".
  final String insert;

  final ScriptureRef ref;

  const RosaryMystery({
    required this.number,
    required this.name,
    required this.shortName,
    required this.insert,
    required this.ref,
  });
}

class Rosary {
  final RosaryKind kind;

  /// Name of the rosary as a whole, e.g. "Radostný ruženec".
  final String name;

  /// Days on which it is prayed, e.g. "pondelok, sobota".
  final String daysLabel;

  /// Label for a single mystery after its ordinal, e.g. "radostné tajomstvo"
  /// ("1. radostné tajomstvo") or "tajomstvo svetla".
  final String mysteryLabel;

  /// `DateTime.weekday` values (1 = Monday … 7 = Sunday).
  final List<int> weekdays;

  final List<RosaryMystery> mysteries;

  const Rosary({
    required this.kind,
    required this.name,
    required this.daysLabel,
    required this.mysteryLabel,
    required this.weekdays,
    required this.mysteries,
  });
}

/// A prayer text, optionally with an insert highlighted in the middle
/// (`before` + `insert` + `after`).
class PrayerText {
  final String before;
  final String insert;
  final String after;

  const PrayerText(this.before, {this.insert = '', this.after = ''});

  bool get hasInsert => insert.isNotEmpty;

  String get full => '$before$insert$after';
}

enum RosaryStage { intro, decade, closing }

/// One screen of the step-by-step guide.
class RosaryStep {
  final RosaryStage stage;

  /// Subtitle shown in the guide app bar, e.g. "Desiatok 2 z 5".
  final String stageLabel;

  /// 1–5 during decades, 0 otherwise.
  final int decade;

  final String title;
  final PrayerText text;

  /// Current bead (1-based); 0 when no bead row is shown. A value greater
  /// than [beadCount] means all beads are done.
  final int bead;
  final int beadCount;

  const RosaryStep({
    required this.stage,
    required this.stageLabel,
    required this.title,
    required this.text,
    this.decade = 0,
    this.bead = 0,
    this.beadCount = 0,
  });
}

/// One row in the "Postup modlitby" overview of the detail screen.
class RosaryOrderItem {
  final String id;
  final String name;
  final String? sub;

  /// Repetition badge such as "3×"; `null` for a single prayer.
  final String? count;

  /// Emphasized row (filled marker, bold name).
  final bool strong;

  final PrayerText text;
  final String? note;

  const RosaryOrderItem({
    required this.id,
    required this.name,
    required this.text,
    this.sub,
    this.count,
    this.strong = false,
    this.note,
  });
}

class RosaryOrderGroup {
  final String name;

  /// Badge next to the group name such as "5×"; `null` for none.
  final String? badge;

  final List<RosaryOrderItem> items;

  const RosaryOrderGroup({required this.name, required this.items, this.badge});
}
