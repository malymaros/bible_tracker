import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_note.dart';
import 'package:bible_tracker/core/services/note_parser.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<List<ChapterNote>> _fixtureNotes(
  String file,
  String bookId,
  int ch,
) async {
  final bytes = File('test/fixtures/$file').readAsBytesSync();
  final scraper = SsvScraper(
    MockClient((_) async => http.Response.bytes(bytes, 200)),
  );
  final book = kBibleBooks.firstWhere((b) => b.id == bookId);
  final text = await scraper.fetchChapter(book, ch);
  return NoteParser.parse(text.notesHtml);
}

void main() {
  group('Genesis 1 fixture', () {
    late List<ChapterNote> notes;

    setUpAll(
      () async => notes = await _fixtureNotes('ssv_gen_1.html', 'gen', 1),
    );

    test('finds every note in verse order', () {
      expect(notes.map((n) => n.verse), [1, 2, 4, 6, 9, 20, 26, 28]);
    });

    test('reads verse ranges from the "4 – 5." prefix', () {
      final ranges = {for (final n in notes) n.verse: n.verseEnd};
      expect(ranges[4], 5);
      expect(ranges[6], 8);
      expect(ranges[20], 24);
      expect(ranges[26], 26);
    });

    test('strips the verse number from the note text', () {
      final n26 = notes.firstWhere((n) => n.verse == 26);
      expect(n26.text, startsWith('Pri stvorení predchádzajúcich tvorov'));
      expect(n26.text, endsWith('človek je osoba.'));
    });

    test('forVerse returns the range note for a verse inside it', () {
      final hits = NoteParser.forVerse(notes, 22);
      expect(hits.single.verse, 20);
      expect(NoteParser.forVerse(notes, 25), isEmpty);
    });
  });

  test('Ephesians 5 fixture has a 13 – 14 range note', () async {
    final notes = await _fixtureNotes('ssv_eph_5.html', 'eph', 5);
    final n13 = notes.firstWhere((n) => n.verse == 13);
    expect(n13.verseEnd, 14);
    expect(n13.text, startsWith('Zmysel týchto veršov'));
  });

  test('empty or missing notes give an empty list', () {
    expect(NoteParser.parse(null), isEmpty);
    expect(NoteParser.parse('  '), isEmpty);
  });

  test('a note that starts at the verse comes before a covering range', () {
    const html =
        '<div id="v3"><div class="faq">3 – 6. Rozsah.</div></div>'
        '<div id="v5"><div class="faq">5. Vlastná.</div></div>';
    final hits = NoteParser.forVerse(NoteParser.parse(html), 5);
    expect(hits.map((n) => n.text), ['Vlastná.', 'Rozsah.']);
  });

  test('<br> inside a note becomes a line break', () {
    const html =
        '<div id="v2"><div class="faq">2. Prvý.<br />Druhý.</div></div>';
    expect(NoteParser.parse(html).single.text, 'Prvý.\nDruhý.');
  });
}
