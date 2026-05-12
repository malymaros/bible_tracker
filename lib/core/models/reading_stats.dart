import 'package:bible_tracker/core/models/bible_book.dart';

class ReadingStats {
  final int totalChapters;
  final int completedChapters;
  final int remainingChapters;
  final double completionPercent;

  final int oldTestamentTotal;
  final int oldTestamentCompleted;
  final int newTestamentTotal;
  final int newTestamentCompleted;

  final int deuterocanonicalTotal;
  final int deuterocanonicalCompleted;

  final int completedBooksCount;
  final int remainingBooksCount;

  /// Books where every chapter has been read. Canonical SSV order.
  final List<BibleBook> fullyCompletedBooks;

  /// Books where no chapter has been read. Canonical SSV order.
  final List<BibleBook> notStartedBooks;

  ReadingStats({
    required this.totalChapters,
    required this.completedChapters,
    required this.remainingChapters,
    required this.completionPercent,
    required this.oldTestamentTotal,
    required this.oldTestamentCompleted,
    required this.newTestamentTotal,
    required this.newTestamentCompleted,
    required this.deuterocanonicalTotal,
    required this.deuterocanonicalCompleted,
    required this.completedBooksCount,
    required this.remainingBooksCount,
    required List<BibleBook> fullyCompletedBooks,
    required List<BibleBook> notStartedBooks,
  })  : fullyCompletedBooks = List.unmodifiable(fullyCompletedBooks),
        notStartedBooks = List.unmodifiable(notStartedBooks);

  @override
  String toString() =>
      'ReadingStats($completedChapters/$totalChapters, '
      '${completionPercent.toStringAsFixed(1)}%)';
}
