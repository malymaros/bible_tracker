import 'package:bible_tracker/core/models/bible_book.dart';

class BookPlanProgress {
  final BibleBook book;
  final int completedChapters;
  final int totalChapters;

  const BookPlanProgress({
    required this.book,
    required this.completedChapters,
    required this.totalChapters,
  });

  bool get isCompleted =>
      totalChapters > 0 && completedChapters == totalChapters;
  bool get isNotStarted => completedChapters == 0;
}

class PlanStatistics {
  final int totalPlanChapters;
  final int completedPlanChapters;
  final int remainingPlanChapters;
  final double completionPercent;

  final int oldTestamentTotal;
  final int oldTestamentCompleted;
  final int newTestamentTotal;
  final int newTestamentCompleted;

  final int deuterocanonicalTotal;
  final int deuterocanonicalCompleted;

  final List<BookPlanProgress> bookProgress;
  final List<BibleBook> fullyCompletedSelectedBooks;
  final List<BibleBook> notStartedSelectedBooks;

  const PlanStatistics({
    required this.totalPlanChapters,
    required this.completedPlanChapters,
    required this.remainingPlanChapters,
    required this.completionPercent,
    required this.oldTestamentTotal,
    required this.oldTestamentCompleted,
    required this.newTestamentTotal,
    required this.newTestamentCompleted,
    required this.deuterocanonicalTotal,
    required this.deuterocanonicalCompleted,
    required this.bookProgress,
    required this.fullyCompletedSelectedBooks,
    required this.notStartedSelectedBooks,
  });

  int get completedBooksCount => fullyCompletedSelectedBooks.length;
  int get totalBooksCount => bookProgress.length;
  int get remainingBooksCount => totalBooksCount - completedBooksCount;
  bool get hasDeuterocanonicalBooks => deuterocanonicalTotal > 0;

  int get otTotalBooksCount => bookProgress
      .where((bp) => bp.book.testament == Testament.oldTestament)
      .length;
  int get otCompletedBooksCount => bookProgress
      .where((bp) =>
          bp.book.testament == Testament.oldTestament && bp.isCompleted)
      .length;

  int get ntTotalBooksCount => bookProgress
      .where((bp) => bp.book.testament == Testament.newTestament)
      .length;
  int get ntCompletedBooksCount => bookProgress
      .where((bp) =>
          bp.book.testament == Testament.newTestament && bp.isCompleted)
      .length;
}
