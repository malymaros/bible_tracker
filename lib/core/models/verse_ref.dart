import 'package:bible_tracker/core/models/chapter_ref.dart';

/// One verse: book, chapter and verse number.
class VerseRef {
  final String bookId;
  final int chapterNumber;
  final int verseNumber;

  const VerseRef(this.bookId, this.chapterNumber, this.verseNumber)
    : assert(bookId != '', 'bookId must not be empty'),
      assert(chapterNumber >= 1, 'chapterNumber must be >= 1'),
      assert(verseNumber >= 1, 'verseNumber must be >= 1');

  VerseRef.inChapter(ChapterRef chapter, int verseNumber)
    : this(chapter.bookId, chapter.chapterNumber, verseNumber);

  ChapterRef get chapter => ChapterRef(bookId, chapterNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseRef &&
          other.bookId == bookId &&
          other.chapterNumber == chapterNumber &&
          other.verseNumber == verseNumber;

  @override
  int get hashCode => Object.hash(bookId, chapterNumber, verseNumber);

  @override
  String toString() => 'VerseRef($bookId, $chapterNumber, $verseNumber)';
}

/// A bookmarked verse and when it was bookmarked.
class VerseBookmark {
  final VerseRef verse;
  final DateTime bookmarkedAt;

  const VerseBookmark(this.verse, this.bookmarkedAt);
}
