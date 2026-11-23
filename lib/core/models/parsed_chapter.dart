/// A chapter's text split into verses, built from the stored SSV HTML by
/// [VerseParser]. Pure data: the reader decides how to draw it.
class ParsedChapter {
  final List<ChapterBlock> blocks;

  const ParsedChapter(this.blocks);

  /// The segments that open a verse, in text order.
  Iterable<VerseSegment> get verseStarts => [
    for (final block in blocks)
      if (block is VerseParagraph)
        for (final segment in block.segments)
          if (segment.startsVerse) segment,
  ];

  /// Verse numbers in text order (a combined "2-3" mark gives 2).
  List<int> get verseNumbers => [for (final s in verseStarts) s.verse!];

  /// Highest verse number in the chapter, counting combined marks.
  int get lastVerse =>
      verseStarts.fold(0, (m, s) => s.verseEnd > m ? s.verseEnd : m);

  /// True when the verses run 1, 2, 3 … without gaps or repeats. Only such
  /// chapters are shown in the new view; others fall back to the raw HTML.
  bool get isComplete {
    var expected = 1;
    for (final s in verseStarts) {
      if (s.verse != expected) return false;
      expected = s.verseEnd + 1;
    }
    return expected > 1;
  }

  /// Plain text of [verse], joined across paragraphs; null when absent.
  String? verseText(int verse) {
    final parts = <String>[
      for (final block in blocks)
        if (block is VerseParagraph)
          for (final segment in block.segments)
            if (segment.verse == verse && segment.text.trim().isNotEmpty)
              segment.text.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }
}

sealed class ChapterBlock {
  const ChapterBlock();
}

/// A section title on its own line ("Stvorenie sveta, 1, 1 – 2, 4").
class SectionHeading extends ChapterBlock {
  final String text;

  const SectionHeading(this.text);
}

/// A paragraph of verse text, optionally opened by a short inline heading
/// ("Dielo prvého dňa") that SSV writes in front of the first verse.
class VerseParagraph extends ChapterBlock {
  final String? heading;
  final List<VerseSegment> segments;

  /// Indented line, as SSV prints poetry.
  final bool indented;

  const VerseParagraph({
    this.heading,
    required this.segments,
    this.indented = false,
  });
}

/// A run of text that belongs to one verse. A verse that continues into the
/// next paragraph has a segment there too, with [startsVerse] false.
/// [verse] is null for text before the first verse of the chapter.
class VerseSegment {
  final int? verse;

  /// Last verse covered by a combined mark such as "2-3"; else [verse].
  final int verseEnd;
  final String text;
  final bool startsVerse;

  const VerseSegment({
    required this.verse,
    required this.text,
    required this.startsVerse,
    int? verseEnd,
  }) : verseEnd = verseEnd ?? verse ?? 0;
}
