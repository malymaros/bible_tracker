import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';

/// Ordered flat sequence of chapters, built from a list of [BibleBook]s.
///
/// Supports full-Bible navigation and plan-scoped navigation (selected books).
/// All lookups are O(1) via an internal reverse index.
class ChapterCursor {
  final List<ChapterRef> _chapters;
  final Map<ChapterRef, int> _index;

  ChapterCursor._(this._chapters, this._index);

  /// Builds a cursor from [books], sorted by [BibleBook.order].
  factory ChapterCursor(List<BibleBook> books) {
    final sorted = [...books]..sort((a, b) => a.order.compareTo(b.order));

    final chapters = <ChapterRef>[];
    for (final book in sorted) {
      for (var ch = 1; ch <= book.chapterCount; ch++) {
        chapters.add(ChapterRef(book.id, ch));
      }
    }

    final index = <ChapterRef, int>{
      for (var i = 0; i < chapters.length; i++) chapters[i]: i,
    };

    return ChapterCursor._(chapters, index);
  }

  /// Cursor over all 73 Catholic Bible books in SSV canonical order.
  static final ChapterCursor full = ChapterCursor(kBibleBooks);

  /// Total number of chapters in this cursor.
  int get totalChapters => _chapters.length;

  /// First chapter in this cursor.
  ChapterRef get first => _chapters.first;

  /// Last chapter in this cursor.
  ChapterRef get last => _chapters.last;

  /// Whether [ref] exists in this cursor.
  bool contains(ChapterRef ref) => _index.containsKey(ref);

  /// Zero-based position of [ref], or `null` if not in this cursor.
  int? indexOf(ChapterRef ref) => _index[ref];

  /// Chapter after [ref], or `null` if [ref] is the last chapter or not found.
  ChapterRef? nextOf(ChapterRef ref) {
    final idx = _index[ref];
    if (idx == null || idx == _chapters.length - 1) return null;
    return _chapters[idx + 1];
  }

  /// Chapter before [ref], or `null` if [ref] is the first chapter or not found.
  ChapterRef? previousOf(ChapterRef ref) {
    final idx = _index[ref];
    if (idx == null || idx == 0) return null;
    return _chapters[idx - 1];
  }

  /// Chapter at zero-based [index].
  ChapterRef operator [](int index) => _chapters[index];

  /// Unmodifiable view of the full chapter sequence.
  List<ChapterRef> toList() => List.unmodifiable(_chapters);
}
