class ChapterRef {
  final String bookId;
  final int chapterNumber;

  const ChapterRef(this.bookId, this.chapterNumber)
      : assert(bookId != '', 'bookId must not be empty'),
        assert(chapterNumber >= 1, 'chapterNumber must be >= 1');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterRef &&
          other.bookId == bookId &&
          other.chapterNumber == chapterNumber;

  @override
  int get hashCode => Object.hash(bookId, chapterNumber);

  @override
  String toString() => 'ChapterRef($bookId, $chapterNumber)';
}
