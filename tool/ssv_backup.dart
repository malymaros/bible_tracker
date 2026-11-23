// Backs up everything the app needs from biblia.ssv.sk, in case the site
// becomes unreachable: for every chapter of all 73 books
//
//   <out>/raw/<bookId>_<chapter>.html       the whole page exactly as served
//                                           (windows-1250 bytes) – any future
//                                           parser can extract from it again
//   <out>/chapters/<bookId>_<chapter>.json  what the app stores: htmlContent,
//                                           notesHtml, plainText, sourceUrl,
//                                           parserVersion (UTF-8)
//
// and finally <out>/manifest.json with the list of chapters and counts.
//
// Usage: dart run tool/ssv_backup.dart <output-dir> [delay-ms]
//
// Chapters already saved are skipped, so an interrupted run can be restarted.
// On HTTP 429 or a dropped connection the tool waits a minute and retries,
// and gives up after five refusals in a row.

import 'dart:convert';
import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln('Usage: dart run tool/ssv_backup.dart <output-dir> [delay-ms]');
    exit(64);
  }
  final raw = Directory('${args.first}/raw')..createSync(recursive: true);
  final json = Directory('${args.first}/chapters')..createSync(recursive: true);
  final delay = Duration(
    milliseconds: args.length == 2 ? int.parse(args[1]) : 1500,
  );
  final client = http.Client();
  var fetched = 0;
  try {
    for (final book in kBibleBooks) {
      for (var ch = 1; ch <= book.chapterCount; ch++) {
        final rawFile = File('${raw.path}/${book.id}_$ch.html');
        final jsonFile = File('${json.path}/${book.id}_$ch.json');
        if (rawFile.existsSync() && jsonFile.existsSync()) continue;
        final url = SsvScraper.buildSsvUrl(book, ch);
        var refusals = 0;
        while (true) {
          try {
            final response = await client.get(Uri.parse(url));
            if (response.statusCode != 200) {
              throw SsvHttpException('HTTP ${response.statusCode} for $url');
            }
            final text = SsvScraper.parsePage(response.bodyBytes, url);
            rawFile.writeAsBytesSync(response.bodyBytes);
            jsonFile.writeAsStringSync(
              const JsonEncoder.withIndent('  ').convert({
                'bookId': book.id,
                'chapter': ch,
                'sourceUrl': text.sourceUrl,
                'parserVersion': text.parserVersion,
                'htmlContent': text.htmlContent,
                'notesHtml': text.notesHtml,
                'plainText': text.plainText,
              }),
            );
            fetched++;
            break;
          } on SsvParseException catch (e) {
            stderr.writeln('STOP at ${book.id} $ch: $e (fetched=$fetched)');
            exit(1);
          } catch (e) {
            final retryable =
                e is http.ClientException ||
                e is SocketException ||
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

  // Manifest: every chapter must be present; counts of chapters with notes.
  final missing = <String>[];
  var withNotes = 0;
  final books = <Map<String, Object>>[];
  for (final book in kBibleBooks) {
    for (var ch = 1; ch <= book.chapterCount; ch++) {
      final f = File('${json.path}/${book.id}_$ch.json');
      if (!f.existsSync()) {
        missing.add('${book.id} $ch');
        continue;
      }
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      if (m['notesHtml'] != null) withNotes++;
    }
    books.add({
      'id': book.id,
      'name': book.name,
      'ssvSlug': book.ssvSlug,
      'chapters': book.chapterCount,
    });
  }
  File('${args.first}/manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'source': 'https://biblia.ssv.sk (Spolok svätého Vojtecha, used with permission)',
      'createdAt': DateTime.now().toIso8601String(),
      'chapters': books.fold<int>(0, (s, b) => s + (b['chapters'] as int)),
      'chaptersWithNotes': withNotes,
      'missing': missing,
      'books': books,
    }),
  );
  stdout.writeln(
    'all done, fetched=$fetched, with notes=$withNotes, missing=${missing.length}',
  );
}
