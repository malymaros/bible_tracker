// Downloads the chapter HTML of every book from biblia.ssv.sk into a local
// folder, one file per chapter (`<bookId>_<chapter>.html`), so the verse
// parser and the verse counts can be checked against the real text offline.
//
// Usage: dart run tool/ssv_download.dart <output-dir> [delay-ms]
//
// Chapters already in the folder are skipped, so an interrupted run can be
// restarted. The server answers HTTP 429 when asked too fast: the tool then
// waits a minute and retries, and gives up after five refusals in a row.

import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln('Usage: dart run tool/ssv_download.dart <output-dir> [delay-ms]');
    exit(64);
  }
  final out = Directory(args.first)..createSync(recursive: true);
  final delay = Duration(
    milliseconds: args.length == 2 ? int.parse(args[1]) : 1500,
  );
  final client = http.Client();
  final scraper = SsvScraper(client);
  var fetched = 0;
  try {
    for (final book in kBibleBooks) {
      for (var ch = 1; ch <= book.chapterCount; ch++) {
        final file = File('${out.path}/${book.id}_$ch.html');
        if (file.existsSync()) continue;
        var refusals = 0;
        while (true) {
          try {
            final text = await scraper.fetchChapter(book, ch);
            file.writeAsStringSync(text.htmlContent);
            fetched++;
            break;
          } on SsvParseException {
            rethrow;
          } catch (e) {
            // HTTP 429 (too fast) or a dropped connection: wait and retry.
            final retryable =
                e is http.ClientException ||
                (e is SsvHttpException && e.message.contains('HTTP 429'));
            if (!retryable || ++refusals > 5) {
              stderr.writeln('STOP at ${book.id} $ch: $e (fetched=$fetched)');
              exit(1);
            }
            stdout.writeln('$e at ${book.id} $ch, waiting 60 s');
            await Future<void>.delayed(const Duration(seconds: 60));
          }
        }
        await Future<void>.delayed(delay);
      }
      stdout.writeln('${book.id} done (fetched=$fetched)');
    }
  } finally {
    client.close();
  }
  stdout.writeln('all done, fetched=$fetched');
}
