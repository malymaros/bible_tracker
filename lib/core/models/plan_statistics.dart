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
  int get remainingBooksCount => bookProgress.length - completedBooksCount;
  bool get hasDeuterocanonicalBooks => deuterocanonicalTotal > 0;
}
