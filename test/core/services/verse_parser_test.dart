import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/parsed_chapter.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/core/services/verse_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<String> _fixtureChapterHtml(String file, String bookId, int ch) async {
  final bytes = File('test/fixtures/$file').readAsBytesSync();
  final scraper = SsvScraper(
    MockClient((_) async => http.Response.bytes(bytes, 200)),
  );
  final book = kBibleBooks.firstWhere((b) => b.id == bookId);
  return (await scraper.fetchChapter(book, ch)).htmlContent;
}

void main() {
  group('Genesis 1 fixture', () {
    late ParsedChapter chapter;

    setUpAll(() async {
      chapter = VerseParser.parse(
        await _fixtureChapterHtml('ssv_gen_1.html', 'gen', 1),
      );
    });

    test('finds verses 1..31 in order', () {
      expect(chapter.verseNumbers, List.generate(31, (i) => i + 1));
      expect(chapter.isComplete, isTrue);
      expect(chapter.lastVerse, 31);
    });

    test('centred bold paragraphs become section headings', () {
      final headings = chapter.blocks.whereType<SectionHeading>().toList();
      expect(headings.map((h) => h.text), [
        'Prahistória, 1, 1 – 11, 26',
        'Stvorenie sveta, 1, 1 – 2, 4',
      ]);
    });

    test('drops the chapter number and keeps verse 1 text', () {
      expect(chapter.verseText(1), 'Na počiatku stvoril Boh nebo a zem.');
    });

    test('inline "… –" text before a verse becomes the paragraph heading', () {
      final paragraphs = chapter.blocks.whereType<VerseParagraph>();
      expect(
        paragraphs.map((p) => p.heading).whereType<String>(),
        contains('Dielo prvého dňa.'),
      );
      expect(
        chapter.verseText(3),
        'Tu povedal Boh: „Buď svetlo!“ a bolo svetlo.',
      );
    });

    test('a verse continued in indented poetry lines is joined', () {
      expect(
        chapter.verseText(27),
        'A stvoril Boh človeka na svoj obraz, na Boží obraz ho stvoril, '
        'muža a ženu ich stvoril.',
      );
      final v27 = chapter.blocks.whereType<VerseParagraph>().where(
        (p) => p.segments.any((s) => s.verse == 27),
      );
      expect(v27.every((p) => p.indented), isTrue);
    });
  });

  group('Ephesians 5 fixture', () {
    late ParsedChapter chapter;

    setUpAll(() async {
      chapter = VerseParser.parse(
        await _fixtureChapterHtml('ssv_eph_5.html', 'eph', 5),
      );
    });

    test('finds verses 1..33 in order', () {
      expect(chapter.isComplete, isTrue);
      expect(chapter.lastVerse, 33);
    });

    test('the <li value> chapter number is not verse text', () {
      expect(chapter.verseText(1), 'Napodobňujte Boha ako milované deti');
    });
  });

  group('markup variants', () {
    test('punctuation inside the sup stays with the previous verse', () {
      final c = VerseParser.parse(
        '<p><sup>1</sup> široký<sup>. 2&nbsp;</sup>Aj dvoch cherubov</p>',
      );
      expect(c.verseNumbers, [1, 2]);
      expect(c.verseText(1), 'široký.');
      expect(c.verseText(2), 'Aj dvoch cherubov');
    });

    test('a link wrapped around the sup is a verse mark', () {
      final c = VerseParser.parse(
        '<p><sup>1</sup> A. <a href="#v2"><sup>2</sup></a>&nbsp;B.</p>',
      );
      expect(c.verseNumbers, [1, 2]);
      expect(c.verseText(2), 'B.');
    });

    test('a combined mark "2-3" covers both verses', () {
      final c = VerseParser.parse('<p><sup>1</sup> A <sup>2-3</sup> B</p>');
      expect(c.isComplete, isTrue);
      expect(c.lastVerse, 3);
    });

    test('a gap in the numbering is not complete', () {
      final c = VerseParser.parse('<p><sup>1</sup> A <sup>3</sup> B</p>');
      expect(c.isComplete, isFalse);
      expect(c.isUsable, isTrue, reason: 'omitted verses are allowed');
    });

    test('text outside any paragraph is still read', () {
      final c = VerseParser.parse(
        '<p><sup>1</sup> A</p>\nB pokračuje. <sup>2</sup>&nbsp;C',
      );
      expect(c.verseNumbers, [1, 2]);
      expect(c.verseText(1), 'A B pokračuje.');
      expect(c.verseText(2), 'C');
    });

    test('a number split into two sups is joined (Prísl 1,10)', () {
      final c = VerseParser.parse(
        '<p><sup>9 </sup>A</p><p><sup>1</sup><sup>0 </sup>B</p>',
      );
      expect(c.verseNumbers, [9, 10]);
      expect(c.verseText(10), 'B');
    });

    test('the alternative number in brackets is ignored (Múd 6)', () {
      final c = VerseParser.parse(
        '<p><sup><a href="#v1">1</a>(2) </sup>A <sup>2(3) </sup>B</p>',
      );
      expect(c.verseNumbers, [1, 2]);
    });

    test('a number going back is not usable', () {
      final c = VerseParser.parse(
        '<p><sup>1</sup> A <sup>2</sup> B <sup>1</sup> C</p>',
      );
      expect(c.isUsable, isFalse);
    });
  });
}
