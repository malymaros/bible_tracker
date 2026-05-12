import 'package:bible_tracker/core/constants/ssv_constants.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_text.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class SsvHttpException implements Exception {
  final String message;
  SsvHttpException(this.message);
  @override
  String toString() => 'SsvHttpException: $message';
}

class SsvParseException implements Exception {
  final String message;
  SsvParseException(this.message);
  @override
  String toString() => 'SsvParseException: $message';
}

// ---------------------------------------------------------------------------
// Scraper
// ---------------------------------------------------------------------------

class SsvScraper {
  final http.Client _client;

  SsvScraper(this._client);

  static String buildSsvUrl(BibleBook book, int chapter) =>
      '${SsvConstants.baseUrl}/${book.ssvSlug}/kapitola/$chapter.xhtml';

  String buildUrl(BibleBook book, int chapter) => buildSsvUrl(book, chapter);

  Future<ChapterText> fetchChapter(BibleBook book, int chapter) async {
    final url = buildUrl(book, chapter);
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw SsvHttpException('HTTP ${response.statusCode} for $url');
    }
    return _parseHtml(response.bodyBytes, url);
  }

  ChapterText _parseHtml(List<int> bytes, String sourceUrl) {
    final body = _decodeWindows1250(bytes);
    final doc = html_parser.parse(body);
    final inbox = doc.querySelector(SsvConstants.chapterContentSelector);
    if (inbox == null) {
      throw SsvParseException(
        'Selector "${SsvConstants.chapterContentSelector}" not found in: $sourceUrl',
      );
    }
    final htmlContent = inbox.innerHtml;
    final plainText = inbox.text.trim().replaceAll(RegExp(r'[ \t\r\n]+'), ' ');
    return ChapterText(
      htmlContent: htmlContent,
      plainText: plainText.isEmpty ? null : plainText,
      sourceUrl: sourceUrl,
      parserVersion: SsvConstants.parserVersion,
    );
  }
}

// ---------------------------------------------------------------------------
// Windows-1250 → Unicode lookup table
//
// biblia.ssv.sk always serves text/html; charset=windows-1250.
// Dart's dart:convert only supports utf-8, ascii, and latin-1, so we
// decode manually using the official code-page mapping from:
// https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit1250.txt
//
// Index 0 = byte 0x80, index 127 = byte 0xFF.
// Value 0 marks undefined code points (rendered as U+FFFD).
// ---------------------------------------------------------------------------

const _kWin1250 = <int>[
  // 0x80–0x8F
  0x20AC, 0x0000, 0x201A, 0x0000, 0x201E, 0x2026, 0x2020, 0x2021,
  0x0000, 0x2030, 0x0160, 0x2039, 0x015A, 0x0164, 0x017D, 0x0179,
  // 0x90–0x9F
  0x0000, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x0000, 0x2122, 0x0161, 0x203A, 0x015B, 0x0165, 0x017E, 0x017A,
  // 0xA0–0xAF
  0x00A0, 0x02C7, 0x02D8, 0x0141, 0x00A4, 0x0104, 0x00A6, 0x00A7,
  0x00A8, 0x00A9, 0x015E, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x017B,
  // 0xB0–0xBF
  0x00B0, 0x00B1, 0x02DB, 0x0142, 0x00B4, 0x00B5, 0x00B6, 0x00B7,
  0x00B8, 0x0105, 0x015F, 0x00BB, 0x013D, 0x02DD, 0x013E, 0x017C,
  // 0xC0–0xCF
  0x0154, 0x00C1, 0x00C2, 0x0102, 0x00C4, 0x0139, 0x0106, 0x00C7,
  0x010C, 0x00C9, 0x0118, 0x00CB, 0x011A, 0x00CD, 0x00CE, 0x010E,
  // 0xD0–0xDF
  0x0110, 0x0143, 0x0147, 0x00D3, 0x00D4, 0x0150, 0x00D6, 0x00D7,
  0x0158, 0x016E, 0x00DA, 0x0170, 0x00DC, 0x00DD, 0x0162, 0x00DF,
  // 0xE0–0xEF
  0x0155, 0x00E1, 0x00E2, 0x0103, 0x00E4, 0x013A, 0x0107, 0x00E7,
  0x010D, 0x00E9, 0x0119, 0x00EB, 0x011B, 0x00ED, 0x00EE, 0x010F,
  // 0xF0–0xFF
  0x0111, 0x0144, 0x0148, 0x00F3, 0x00F4, 0x0151, 0x00F6, 0x00F7,
  0x0159, 0x016F, 0x00FA, 0x0171, 0x00FC, 0x00FD, 0x0163, 0x02D9,
];

String _decodeWindows1250(List<int> bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    if (b < 0x80) {
      buf.writeCharCode(b);
    } else {
      final cp = _kWin1250[b - 0x80];
      buf.writeCharCode(cp != 0 ? cp : 0xFFFD);
    }
  }
  return buf.toString();
}
