import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/services/download_service.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final ssvScraperProvider = Provider<SsvScraper>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return SsvScraper(client);
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(
    ref.watch(ssvScraperProvider),
    ref.watch(chapterTextDaoProvider),
  );
});

/// Starts downloading all chapters for [bookId] and exposes live progress.
///
/// The stream begins as soon as this provider is first watched. Use
/// [ref.invalidate] to restart a cancelled or failed download.
final downloadBookProvider =
    StreamProvider.family<BookDownloadProgress, String>((ref, bookId) {
  final book = kBibleBooks.firstWhere((b) => b.id == bookId);
  return ref.read(downloadServiceProvider).downloadBook(book);
});
