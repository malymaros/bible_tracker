// Checks the verse parser and the verse-count table against chapters saved
// by tool/ssv_download.dart.
//
// Usage: dart run tool/verse_check.dart <cache-dir>
//
// Prints one line per problem chapter: parser gaps (verses not 1..n in
// order) and differences between the parsed last verse and
// kVerseCountsByBook.

import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/verse_counts.dart';
import 'package:bible_tracker/core/services/verse_parser.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/verse_check.dart <cache-dir>');
    exit(64);
  }
  var total = 0, missing = 0, incomplete = 0, countDiff = 0;
  for (final book in kBibleBooks) {
    for (var ch = 1; ch <= book.chapterCount; ch++) {
      final file = File('${args.single}/${book.id}_$ch.html');
      if (!file.existsSync()) {
        missing++;
        continue;
      }
      total++;
      final parsed = VerseParser.parse(file.readAsStringSync());
      final expected = verseCountForChapter(book.id, ch);
      if (!parsed.isUsable) {
        incomplete++;
        final nums = parsed.verseNumbers;
        stdout.writeln(
          'BAD   ${book.id} $ch: ${nums.length} marks, '
          'first ${nums.take(5).toList()} … ${_firstProblem(nums)}',
        );
      }
      if (parsed.lastVerse != expected) {
        countDiff++;
        stdout.writeln(
          'COUNT ${book.id} $ch: parsed ${parsed.lastVerse}, table $expected',
        );
      }
    }
  }
  stdout.writeln(
    'checked=$total missing=$missing incomplete=$incomplete '
    'countDiff=$countDiff',
  );
}

String _firstProblem(List<int> nums) {
  var expected = 1;
  for (var i = 0; i < nums.length; i++) {
    if (nums[i] != expected) {
      return 'at #$i expected $expected got ${nums[i]} '
          '(context ${nums.skip(i > 2 ? i - 2 : 0).take(6).toList()})';
    }
    expected = nums[i] + 1;
  }
  return 'empty';
}
