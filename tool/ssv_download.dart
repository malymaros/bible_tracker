// Downloads the chapter HTML of every book from biblia.ssv.sk into a local
// folder, one file per chapter (`<bookId>_<chapter>.html`), so the verse
// parser and the verse counts can be checked against the real text offline.
//
// Usage: dart run tool/ssv_download.dart <output-dir>
//
// Chapters already in the folder are skipped, so an interrupted run can be
// restarted. Requests are spaced by SsvConstants.requestDelay, as in the app.

import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/ssv_constants.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/ssv_download.dart <output-dir>');
    exit(64);
  }
  final out = Directory(args.single)..createSync(recursive: true);
  final client = http.Client();
  final scraper = SsvScraper(client);
  var fetched = 0;
  var failed = 0;
  try {
    for (final book in kBibleBooks) {
      for (var ch = 1; ch <= book.chapterCount; ch++) {
        final file = File('${out.path}/${book.id}_$ch.html');
        if (file.existsSync()) continue;
        try {
          final text = await scraper.fetchChapter(book, ch);
          file.writeAsStringSync(text.htmlContent);
          fetched++;
        } catch (e) {
          failed++;
          stderr.writeln('FAIL ${book.id} $ch: $e');
        }
        await Future<void>.delayed(SsvConstants.requestDelay);
      }
      stdout.writeln('${book.id} done');
    }
  } finally {
    client.close();
  }
  stdout.writeln('fetched=$fetched failed=$failed');
}
