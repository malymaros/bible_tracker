import 'package:bible_tracker/core/models/chapter_note.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Parses the footnotes block stored from biblia.ssv.sk (`div.faqs` inner
/// HTML): a list of `<div id="vN"><div class="faq">N. text</div></div>`.
///
/// Pure Dart, no Flutter imports.
abstract final class NoteParser {
  static final _id = RegExp(r'^v(\d{1,3})$');

  // "26. ", "4 – 5. ", "13-14. " at the start of the note text.
  static final _prefix = RegExp(r'^(\d{1,3})(?:\s*[–—-]\s*(\d{1,3}))?\.\s*');
  static final _spaces = RegExp(r'[ \t\r\n ]+');

  static List<ChapterNote> parse(String? html) {
    if (html == null || html.trim().isEmpty) return const [];
    final notes = <ChapterNote>[];
    for (final entry
        in html_parser.parseFragment(html).querySelectorAll('[id]')) {
      final idMatch = _id.firstMatch(entry.id);
      if (idMatch == null) continue;
      final verse = int.parse(idMatch.group(1)!);
      final body = entry.querySelector('.faq') ?? entry;
      var text = _text(body);
      var verseEnd = verse;
      final m = _prefix.firstMatch(text);
      if (m != null) {
        text = text.substring(m.end);
        final end = m.group(2) == null ? null : int.parse(m.group(2)!);
        if (end != null && end > verse) verseEnd = end;
      }
      if (text.isEmpty) continue;
      notes.add(ChapterNote(verse: verse, verseEnd: verseEnd, text: text));
    }
    notes.sort((a, b) => a.verse.compareTo(b.verse));
    return notes;
  }

  /// Notes that cover [verse]: the note starting at it first, then ranges.
  static List<ChapterNote> forVerse(List<ChapterNote> notes, int verse) {
    final hits = notes.where((n) => n.covers(verse)).toList()
      ..sort((a, b) {
        final aStarts = a.verse == verse ? 0 : 1;
        final bStarts = b.verse == verse ? 0 : 1;
        return aStarts != bStarts ? aStarts - bStarts : a.verse - b.verse;
      });
    return hits;
  }

  /// Plain text with `<br>` and block breaks kept as single line breaks.
  static String _text(dom.Element e) {
    final buf = StringBuffer();
    void walk(dom.Node n) {
      if (n is dom.Text) {
        buf.write(n.text);
      } else if (n is dom.Element) {
        if (n.localName == 'br') {
          buf.write('\n');
          return;
        }
        final block = n.localName == 'p' || n.localName == 'div';
        if (block && buf.isNotEmpty) buf.write('\n');
        for (final c in n.nodes) {
          walk(c);
        }
        if (block) buf.write('\n');
      }
    }

    for (final c in e.nodes) {
      walk(c);
    }
    return buf
        .toString()
        .split('\n')
        .map((l) => l.replaceAll(_spaces, ' ').trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
  }
}
