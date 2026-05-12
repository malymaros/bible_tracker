import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_text.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BibleBook _book(String id) => kBibleBooks.firstWhere((b) => b.id == id);

SsvScraper _scraperWith(MockClient client) => SsvScraper(client);

MockClient _respondWith(String body, int statusCode) =>
    MockClient((_) async => http.Response(body, statusCode));

MockClient _respondWithBytes(List<int> bytes, int statusCode) =>
    MockClient((_) async => http.Response.bytes(bytes, statusCode));

List<int> _fixture(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final genesis = _book('gen');
  final ephesians = _book('eph');

  // ── URL generation ─────────────────────────────────────────────────────────

  group('URL generation', () {
    late SsvScraper scraper;

    setUp(() => scraper = _scraperWith(_respondWith('', 200)));

    test('builds correct URL for Genesis 1 (OT long slug)', () {
      expect(
        scraper.buildUrl(genesis, 1),
        'https://biblia.ssv.sk/biblia/kniha'
        '/genezis-prva-kniha-mojzisova/kapitola/1.xhtml',
      );
    });

    test('builds correct URL for Ephesians 5 (NT short slug)', () {
      expect(
        scraper.buildUrl(ephesians, 5),
        'https://biblia.ssv.sk/biblia/kniha'
        '/list-efezanom/kapitola/5.xhtml',
      );
    });

    test('chapter number is embedded verbatim (no zero-padding)', () {
      expect(scraper.buildUrl(genesis, 50), endsWith('/50.xhtml'));
      expect(scraper.buildUrl(ephesians, 1), endsWith('/1.xhtml'));
    });

    test('URL does not include the #ct fragment', () {
      expect(scraper.buildUrl(genesis, 1), isNot(contains('#ct')));
    });
  });

  // ── HTML parsing with real fixture (Windows-1250) ─────────────────────────

  group('HTML parsing – Genesis 1 fixture', () {
    late ChapterText result;

    setUpAll(() async {
      final bytes = _fixture('ssv_gen_1.html');
      final scraper = _scraperWith(_respondWithBytes(bytes, 200));
      result = await scraper.fetchChapter(genesis, 1);
    });

    test('htmlContent is non-empty', () {
      expect(result.htmlContent, isNotEmpty);
    });

    test('htmlContent contains expected Slovak phrase', () {
      expect(result.htmlContent, contains('Na počiatku'));
    });

    test('plainText is non-null and non-empty', () {
      expect(result.plainText, isNotNull);
      expect(result.plainText, isNotEmpty);
    });

    test('plainText contains expected text', () {
      expect(result.plainText, contains('Na počiatku'));
    });

    test('parserVersion is 1', () {
      expect(result.parserVersion, 1);
    });

    test('sourceUrl ends with kapitola/1.xhtml', () {
      expect(result.sourceUrl, endsWith('kapitola/1.xhtml'));
    });

    test('htmlContent does not include the footnotes (div.faqs)', () {
      // Footnotes section starts a separate sibling div; innerHtml of div.inbox
      // must not bleed into footnote text.
      expect(result.htmlContent, isNot(contains('class="faq"')));
    });

    test('Windows-1250 Slovak characters are decoded correctly', () {
      // These characters live in the 0x80-0xFF Windows-1250 range and would be
      // garbled if decoded with the wrong codec.
      expect(result.htmlContent, contains('č')); // U+010D, byte 0xE8
      expect(result.htmlContent, contains('š')); // U+0161, byte 0x9A
      expect(result.htmlContent, contains('ž')); // U+017E, byte 0x9E
    });
  });

  group('HTML parsing – Ephesians 5 fixture (NT, different slug)', () {
    late ChapterText result;

    setUpAll(() async {
      final bytes = _fixture('ssv_eph_5.html');
      final scraper = _scraperWith(_respondWithBytes(bytes, 200));
      result = await scraper.fetchChapter(ephesians, 5);
    });

    test('htmlContent is non-empty', () {
      expect(result.htmlContent, isNotEmpty);
    });

    test('htmlContent contains expected NT content', () {
      expect(result.htmlContent, contains('milujte'));
    });

    test('Slovak characters decoded correctly in NT fixture', () {
      expect(result.htmlContent, contains('č')); // e.g. "nech"
    });
  });

  // ── HTTP error handling ────────────────────────────────────────────────────

  group('HTTP error handling', () {
    test('throws SsvHttpException on 404', () {
      final scraper = _scraperWith(_respondWith('Not Found', 404));
      expect(
        () => scraper.fetchChapter(genesis, 1),
        throwsA(isA<SsvHttpException>()),
      );
    });

    test('throws SsvHttpException on 500', () {
      final scraper = _scraperWith(_respondWith('Server Error', 500));
      expect(
        () => scraper.fetchChapter(genesis, 1),
        throwsA(isA<SsvHttpException>()),
      );
    });

    test('SsvHttpException message contains the HTTP status code', () async {
      final scraper = _scraperWith(_respondWith('Not Found', 404));
      try {
        await scraper.fetchChapter(genesis, 1);
        fail('Expected SsvHttpException');
      } on SsvHttpException catch (e) {
        expect(e.message, contains('404'));
      }
    });

    test('SsvHttpException message contains the URL', () async {
      final scraper = _scraperWith(_respondWith('Not Found', 404));
      try {
        await scraper.fetchChapter(genesis, 1);
        fail('Expected SsvHttpException');
      } on SsvHttpException catch (e) {
        expect(e.message, contains('genezis'));
      }
    });
  });

  // ── Parsing error handling ─────────────────────────────────────────────────

  group('Parsing error handling', () {
    test('throws SsvParseException when chapter inbox is absent', () {
      const html =
          '<html><body>'
          '<div class="ssv-bb-module">'
          '<div class="wrapper">'
          '<div class="other">no inbox here</div>'
          '</div></div></body></html>';
      final scraper = _scraperWith(_respondWith(html, 200));
      expect(
        () => scraper.fetchChapter(genesis, 1),
        throwsA(isA<SsvParseException>()),
      );
    });

    test('SsvParseException message mentions the CSS selector', () async {
      const html = '<html><body></body></html>';
      final scraper = _scraperWith(_respondWith(html, 200));
      try {
        await scraper.fetchChapter(genesis, 1);
        fail('Expected SsvParseException');
      } on SsvParseException catch (e) {
        expect(e.message, contains('.ssv-bb-module .wrapper > .inbox'));
      }
    });

    test('succeeds with minimal valid inbox structure', () async {
      const html =
          '<html><body>'
          '<div class="ssv-bb-module"><div class="wrapper">'
          '<div class="inbox"><p>Verse text.</p></div>'
          '</div></div>'
          '</body></html>';
      final scraper = _scraperWith(_respondWith(html, 200));
      final text = await scraper.fetchChapter(genesis, 1);
      expect(text.htmlContent, contains('Verse text'));
      expect(text.plainText, contains('Verse text'));
    });
  });

  // ── plainText normalization ────────────────────────────────────────────────

  group('plainText normalization', () {
    test('collapses multiple spaces and newlines', () async {
      const html =
          '<html><body>'
          '<div class="ssv-bb-module"><div class="wrapper">'
          '<div class="inbox"><p>Verse  one.</p>'
          '<p>Verse  two.</p></div>'
          '</div></div>'
          '</body></html>';
      final scraper = _scraperWith(_respondWith(html, 200));
      final text = await scraper.fetchChapter(genesis, 1);
      expect(text.plainText, isNot(contains('  ')));
    });

    test('plainText is null for an inbox with only whitespace', () async {
      const html =
          '<html><body>'
          '<div class="ssv-bb-module"><div class="wrapper">'
          '<div class="inbox">   </div>'
          '</div></div>'
          '</body></html>';
      final scraper = _scraperWith(_respondWith(html, 200));
      final text = await scraper.fetchChapter(genesis, 1);
      expect(text.plainText, isNull);
    });
  });
}
