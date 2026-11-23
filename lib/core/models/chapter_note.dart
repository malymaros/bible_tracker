/// One SSV footnote of a chapter, parsed by [NoteParser].
///
/// SSV writes a note to one verse ("26. …") or to a range ("20 – 24. …").
/// The verse text links to the note from its first verse, [verse].
class ChapterNote {
  final int verse;

  /// Last verse the note covers; equal to [verse] for a single verse.
  final int verseEnd;

  /// Note text without the leading verse number; paragraphs split by "\n".
  final String text;

  const ChapterNote({
    required this.verse,
    required this.verseEnd,
    required this.text,
  });

  bool get isRange => verseEnd > verse;

  bool covers(int v) => v >= verse && v <= verseEnd;
}
