enum Testament { oldTestament, newTestament }

enum CatholicCategory {
  // Old Testament
  pentateuch,
  historicalBooks,
  wisdomBooks,
  propheticBooks,
  // New Testament
  gospels,
  acts,
  paulineLetters,
  catholicLetters,
  revelation,
}

class BibleBook {
  final String id;
  final String name;
  final String shortName;
  final int order;
  final Testament testament;
  final CatholicCategory category;
  final int chapterCount;
  final bool isDeuterocanonical;
  final String ssvSlug;

  const BibleBook({
    required this.id,
    required this.name,
    required this.shortName,
    required this.order,
    required this.testament,
    required this.category,
    required this.chapterCount,
    required this.isDeuterocanonical,
    required this.ssvSlug,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BibleBook && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BibleBook($id, $name)';
}
