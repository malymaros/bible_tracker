import 'package:bible_tracker/core/models/parsed_chapter.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Splits the chapter HTML stored from biblia.ssv.sk into verses.
///
/// What the SSV markup looks like (see test/fixtures):
/// - verse numbers are `<sup>N</sup>`, sometimes wrapped in or wrapping an
///   `<a href="#vN">` footnote link, with `&nbsp;` inside or outside;
/// - section titles are centred `<p>` paragraphs in `<strong>`;
/// - a paragraph may open with a short heading ending in a dash
///   ("Dielo prvého dňa. – ") before its first verse;
/// - the chapter number is printed as text ("1 ") or as `<li value="5">`;
/// - poetry lines are paragraphs indented with `margin-left`;
/// - a verse may continue into the next paragraph.
///
/// Pure Dart, no Flutter imports, so it runs in tools and unit tests.
abstract final class VerseParser {
  // Optional stray punctuation that SSV sometimes puts inside the <sup>
  // (`<sup>. 18</sup>`), then the number or a "2-3" range.
  static final _verseMark = RegExp(
    // A trailing "(2)" is the alternative (Vulgate) number SSV prints in
    // some books, e.g. Wisdom 6 "1(2)"; the first number is the verse.
    r'^([.,;:!?“”"„)]*)\s*(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?'
    r'(?:\s*\(\d{1,3}\))?$',
  );
  static final _leadingChapterNumber = RegExp(r'^\d{1,3}\s+');
  static final _headingDash = RegExp(r'\s*[–—-]\s*$');
  static final _spaces = RegExp(r'[ \t\r\n ]+');
  static const _blockTags = {
    'p', 'div', 'li', 'ol', 'ul', 'blockquote', 'h1', 'h2', 'h3', 'h4',
    'h5', 'h6', 'table', 'tbody', 'thead', 'tr', 'td', 'th', 'center',
  };

  static ParsedChapter parse(String html) {
    final builder = _Builder();
    for (final node in html_parser.parseFragment(html).nodes) {
      _visitBlock(node, builder);
    }
    builder.flushLoose();
    return ParsedChapter(builder.blocks);
  }

  static void _visitBlock(dom.Node node, _Builder builder) {
    if (node is dom.Text) {
      builder.addLoose(node.text);
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName;
    if (!_blockTags.contains(tag)) {
      // Inline content directly in the fragment: collect it as loose text.
      builder.addLooseElement(node);
      return;
    }
    final hasBlockChild = node.children.any(
      (c) => _blockTags.contains(c.localName),
    );
    if (hasBlockChild) {
      builder.flushLoose();
      for (final child in node.nodes) {
        _visitBlock(child, builder);
      }
      builder.flushLoose();
      return;
    }
    builder.flushLoose();
    builder.addParagraph(node);
  }

  /// Flattens an element into text runs and verse marks.
  static List<_Token> _tokens(dom.Node node) {
    final out = <_Token>[];
    void walk(dom.Node n) {
      if (n is dom.Text) {
        out.add(_Token.text(n.text));
        return;
      }
      if (n is! dom.Element) return;
      if (n.localName == 'br') {
        out.add(const _Token.text(' '));
        return;
      }
      if (n.localName == 'sup') {
        final text = n.text.replaceAll(_spaces, ' ').trim();
        final m = _verseMark.firstMatch(text);
        if (m != null) {
          if (m.group(1)!.isNotEmpty) out.add(_Token.text(m.group(1)!));
          var start = int.parse(m.group(2)!);
          final end = m.group(3) == null ? start : int.parse(m.group(3)!);
          // SSV sometimes splits a number into two sups ("<sup>1</sup>
          // <sup>0</sup>" for 10): join digits that follow a single-number
          // mark with nothing but spaces in between.
          var back = out.length - 1;
          while (back >= 0 &&
              !out[back].isMark &&
              out[back].text!.trim().isEmpty) {
            back--;
          }
          if (m.group(1)!.isEmpty &&
              m.group(3) == null &&
              back >= 0 &&
              out[back].isMark &&
              out[back].verse == out[back].verseEnd) {
            start = int.parse('${out[back].verse}$start');
            out.removeRange(back, out.length);
            out.add(_Token.mark(start, start));
            return;
          }
          out.add(_Token.mark(start, end < start ? start : end));
          return;
        }
        // A footnote sign or similar: not part of the reading text.
        return;
      }
      for (final child in n.nodes) {
        walk(child);
      }
    }

    walk(node);
    return out;
  }

  static String clean(String text) => text.replaceAll(_spaces, ' ');
}

class _Token {
  final String? text;
  final int? verse;
  final int? verseEnd;

  const _Token.text(this.text) : verse = null, verseEnd = null;
  const _Token.mark(int this.verse, int this.verseEnd) : text = null;

  bool get isMark => verse != null;
}

class _Builder {
  final blocks = <ChapterBlock>[];
  int? _currentVerse;
  final _loose = <dom.Node>[];

  void addLoose(String text) {
    if (text.trim().isEmpty && _loose.isEmpty) return;
    _loose.add(dom.Text(text));
  }

  void addLooseElement(dom.Element e) => _loose.add(e);

  void flushLoose() {
    if (_loose.isEmpty) return;
    final wrapper = dom.Element.tag('p');
    for (final n in _loose) {
      wrapper.append(n is dom.Text ? dom.Text(n.text) : n.clone(true));
    }
    _loose.clear();
    addParagraph(wrapper);
  }

  void addParagraph(dom.Element element) {
    final tokens = VerseParser._tokens(element);
    final plain = VerseParser.clean(
      tokens.where((t) => !t.isMark).map((t) => t.text).join(),
    ).trim();
    final hasMarks = tokens.any((t) => t.isMark);
    if (!hasMarks && plain.isEmpty) return;

    if (!hasMarks && _isHeading(element)) {
      blocks.add(SectionHeading(plain));
      return;
    }

    // Text before the first verse mark of this paragraph.
    final firstMark = tokens.indexWhere((t) => t.isMark);
    final preTokens = firstMark < 0 ? tokens : tokens.sublist(0, firstMark);
    var pre = VerseParser.clean(preTokens.map((t) => t.text).join()).trim();
    String? heading;
    final segments = <VerseSegment>[];

    if (_currentVerse == null) {
      pre = pre.replaceFirst(VerseParser._leadingChapterNumber, '');
    }
    if (pre.isNotEmpty) {
      if (hasMarks && VerseParser._headingDash.hasMatch(pre)) {
        heading = pre.replaceFirst(VerseParser._headingDash, '').trim();
      } else {
        segments.add(
          VerseSegment(verse: _currentVerse, text: pre, startsVerse: false),
        );
      }
    }

    if (firstMark >= 0) {
      var i = firstMark;
      while (i < tokens.length) {
        final mark = tokens[i];
        final buffer = StringBuffer();
        i++;
        while (i < tokens.length && !tokens[i].isMark) {
          buffer.write(tokens[i].text);
          i++;
        }
        _currentVerse = mark.verse;
        segments.add(
          VerseSegment(
            verse: mark.verse,
            verseEnd: mark.verseEnd,
            text: VerseParser.clean(buffer.toString()).trimLeft(),
            startsVerse: true,
          ),
        );
      }
    }

    if (segments.isEmpty && heading == null) return;
    if (segments.isEmpty) {
      // A heading line with nothing after it.
      blocks.add(SectionHeading(heading!));
      return;
    }
    blocks.add(
      VerseParagraph(
        heading: heading == null || heading.isEmpty ? null : heading,
        segments: segments,
        indented: _isIndented(element),
      ),
    );
  }

  bool _isHeading(dom.Element e) {
    if (RegExp(r'^h[1-6]$').hasMatch(e.localName ?? '')) return true;
    final style = (e.attributes['style'] ?? '').toLowerCase();
    final centred =
        e.attributes['align'] == 'center' || style.contains('text-align:center') ||
        style.contains('text-align: center');
    final strongText = e
        .querySelectorAll('strong, b')
        .map((s) => s.text)
        .join();
    final allStrong =
        VerseParser.clean(strongText).trim() ==
            VerseParser.clean(e.text).trim() &&
        strongText.trim().isNotEmpty;
    return centred || allStrong;
  }

  bool _isIndented(dom.Element e) {
    final style = (e.attributes['style'] ?? '').toLowerCase();
    return style.contains('margin-left') || style.contains('padding-left');
  }
}
