// Regenerates lib/core/constants/verse_counts.dart from chapters saved by
// tool/ssv_download.dart, so the verse counts match the SSV text the app
// shows: each chapter's count is its highest verse number in SSV.
//
// Usage: dart run tool/verse_counts_from_ssv.dart <cache-dir>
//
// Chapters the parser cannot read reliably keep their current count.

import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/verse_counts.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/services/verse_parser.dart';

const _target = 'lib/core/constants/verse_counts.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/verse_counts_from_ssv.dart <cache-dir>');
    exit(64);
  }
  final kept = <String>[];
  final out = StringBuffer()
    ..writeln('const Map<String, List<int>> kVerseCountsByBook = {');
  Testament? testament;
  for (final book in kBibleBooks) {
    if (book.testament != testament) {
      testament = book.testament;
      out.writeln(
        testament == Testament.oldTestament
            ? '  // ── OLD TESTAMENT ──'
            : '\n  // ── NEW TESTAMENT ──',
      );
    }
    final counts = <int>[];
    for (var ch = 1; ch <= book.chapterCount; ch++) {
      final file = File('${args.single}/${book.id}_$ch.html');
      final parsed = file.existsSync()
          ? VerseParser.parse(file.readAsStringSync())
          : null;
      if (parsed != null && parsed.isUsable) {
        counts.add(parsed.lastVerse);
      } else {
        counts.add(verseCountForChapter(book.id, ch));
        kept.add('${book.id} $ch');
      }
    }
    out.writeln("  '${book.id}': [ // ${book.name}");
    for (var i = 0; i < counts.length; i += 10) {
      final row = counts.skip(i).take(10).map((c) => '$c'.padLeft(3));
      final last = i + 10 < counts.length ? i + 10 : counts.length;
      out.writeln('   ${row.join(',')}, // ${i + 1}–$last');
    }
    out.writeln('  ],');
  }
  out.writeln('};');

  final source = File(_target).readAsStringSync();
  final start = source.indexOf('const Map<String, List<int>> kVerseCountsByBook');
  final end = source.indexOf('\n};', start) + 3;
  File(_target).writeAsStringSync(
    source.replaceRange(start, end, out.toString().trimRight()),
  );
  stdout.writeln('written; kept old count for: ${kept.join(', ')}');
}
