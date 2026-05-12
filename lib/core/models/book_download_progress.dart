enum BookDownloadStatus { downloading, completed, failed }

class BookDownloadProgress {
  final String bookId;
  final int downloadedChapters;
  final int totalChapters;
  final BookDownloadStatus status;
  final String? errorMessage;

  const BookDownloadProgress({
    required this.bookId,
    required this.downloadedChapters,
    required this.totalChapters,
    required this.status,
    this.errorMessage,
  });

  double get progress =>
      totalChapters == 0 ? 0.0 : downloadedChapters / totalChapters;

  @override
  String toString() =>
      'BookDownloadProgress($bookId, $downloadedChapters/$totalChapters, $status)';
}
