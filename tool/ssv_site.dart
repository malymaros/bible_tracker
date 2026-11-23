// Builds the online Bible reader of the website from the SSV backup made by
// tool/ssv_backup.dart: plain static pages, no server code.
//
//   biblia/index.html          books by testament
//   biblia/<bookId>/index.html chapter grid of a book
//   biblia/<bookId>/<n>.html   chapter text + footnotes, prev/next links
//   biblia/biblia.css          shared style (dark, like the app's page)
//
// Usage: dart run tool/ssv_site.dart <backup-dir> [output-dir]
// Default output: website/mobilne-aplikacie/bible-tracker/biblia
//
// The SSV markup is reduced to a short list of tags (paragraphs, bold,
// italics, verse numbers, footnote links); poetry indents become one class.
// Footnotes come from NoteParser, the same as in the app.

import 'dart:convert';
import 'dart:io';

import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_note.dart';
import 'package:bible_tracker/core/services/note_parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

const _defaultOut = 'website/mobilne-aplikacie/bible-tracker/biblia';
const _credit = 'Preklad SSV';

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln('Usage: dart run tool/ssv_site.dart <backup-dir> [output-dir]');
    exit(64);
  }
  final backup = args[0];
  final out = Directory(args.length == 2 ? args[1] : _defaultOut);
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);
  File('${out.path}/biblia.css').writeAsStringSync(_css);
  File('${out.path}/index.html').writeAsStringSync(_indexPage());

  // Prev/next chapter links follow the order shown on the index page.
  final books = [
    for (final (_, groups) in _bookGroups)
      for (final (category, _) in groups)
        ...kBibleBooks.where((x) => x.category == category),
  ];
  assert(books.length == kBibleBooks.length);
  var pages = 0;
  for (var bi = 0; bi < books.length; bi++) {
    final book = books[bi];
    final dir = Directory('${out.path}/${book.id}')..createSync();
    File('${dir.path}/index.html').writeAsStringSync(_bookPage(book));
    for (var ch = 1; ch <= book.chapterCount; ch++) {
      final file = File('$backup/chapters/${book.id}_$ch.json');
      final m = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final prev = ch > 1
          ? _Link('${ch - 1}.html', '${book.shortName} ${ch - 1}')
          : bi > 0
              ? _Link('../${books[bi - 1].id}/${books[bi - 1].chapterCount}.html',
                  '${books[bi - 1].shortName} ${books[bi - 1].chapterCount}')
              : null;
      final next = ch < book.chapterCount
          ? _Link('${ch + 1}.html', '${book.shortName} ${ch + 1}')
          : bi + 1 < books.length
              ? _Link('../${books[bi + 1].id}/1.html',
                  '${books[bi + 1].shortName} 1')
              : null;
      File('${dir.path}/$ch.html').writeAsStringSync(
        _chapterPage(
          book,
          ch,
          _cleanText(
            m['htmlContent'] as String,
            NoteParser.parse(m['notesHtml'] as String?),
          ),
          _notes(m['notesHtml'] as String?),
          prev,
          next,
        ),
      );
      pages++;
    }
  }
  stdout.writeln('written $pages chapters of ${books.length} books to ${out.path}');
}

class _Link {
  final String href;
  final String label;
  const _Link(this.href, this.label);
}

// ---------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------

String _head(String title, String css, {String? description}) => '''
<!doctype html>
<html lang="sk">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_esc(title)}</title>
${description == null ? '' : '<meta name="description" content="${_esc(description)}">\n'}<link rel="icon" type="image/png" href="${css.replaceFirst('biblia.css', '../img/icon.png')}">
<link rel="stylesheet" href="$css">
</head>
<body>
<div class="wrap">''';

String _foot() => '''
<footer>$_credit · <a href="${'/mobilne-aplikacie/bible-tracker/'}">Bible Tracker</a></footer>
</div>
</body>
</html>
''';

const _bookGroups = [
  ('Starý zákon', [
    (CatholicCategory.pentateuch, 'Pentateuch'),
    (CatholicCategory.historicalBooks, 'Historické knihy'),
    (CatholicCategory.wisdomBooks, 'Múdroslovné knihy'),
    (CatholicCategory.propheticBooks, 'Prorocké knihy'),
  ]),
  ('Nový zákon', [
    (CatholicCategory.gospels, 'Evanjeliá'),
    (CatholicCategory.acts, 'Skutky apoštolov'),
    (CatholicCategory.paulineLetters, 'Pavlove listy'),
    (CatholicCategory.catholicLetters, 'Katolícke listy'),
    (CatholicCategory.revelation, 'Zjavenie'),
  ]),
];

String _indexPage() {
  final b = StringBuffer(_head(
    'Sväté písmo - Bible Tracker',
    'biblia.css',
    description: 'Sväté písmo po slovensky na čítanie online, preklad SSV.',
  ));
  b.write('''
<nav><a href="../">Bible Tracker</a><span class="sep">/</span><span>Sväté písmo</span></nav>
<h1>Sväté písmo</h1>
<p class="sub">$_credit · 73 kníh · <span class="dc">✝</span> deuterokanonické knihy</p>
''');
  // Same grouping and order as the book browser in the app.
  // Old Testament left, New Testament right; one under the other on phones.
  b.writeln('<div class="testaments">');
  for (final (testament, groups) in _bookGroups) {
    b.writeln('<div class="col">');
    b.writeln('<h2>$testament</h2>');
    for (final (category, title) in groups) {
      b.writeln('<h3>$title</h3>');
      b.writeln('<ul class="books">');
      for (final book in kBibleBooks.where((x) => x.category == category)) {
        b.writeln(
          '<li><a href="${book.id}/"><span class="abbr">${_esc(book.shortName)}</span>'
          '<span class="name">${_esc(book.name)}'
          '${book.isDeuterocanonical ? ' <span class="dc">✝</span>' : ''}</span>'
          '<span class="count">${book.chapterCount}</span></a></li>',
        );
      }
      b.writeln('</ul>');
    }
    b.writeln('</div>');
  }
  b.writeln('</div>');
  b.write(_foot());
  return b.toString();
}

String _bookPage(BibleBook book) {
  final b = StringBuffer(_head('${book.name} - Sväté písmo', '../biblia.css'));
  b.write('''
<nav><a href="../../">Bible Tracker</a><span class="sep">/</span><a href="../">Sväté písmo</a><span class="sep">/</span><span>${_esc(book.name)}</span></nav>
<h1>${_esc(book.name)}</h1>
<p class="sub">${book.chapterCount == 1 ? '1 kapitola' : book.chapterCount < 5 ? '${book.chapterCount} kapitoly' : '${book.chapterCount} kapitol'}</p>
<ul class="chapters">
''');
  for (var ch = 1; ch <= book.chapterCount; ch++) {
    b.writeln('<li><a href="$ch.html">$ch</a></li>');
  }
  b.writeln('</ul>');
  b.write(_foot());
  return b.toString();
}

String _chapterPage(
  BibleBook book,
  int ch,
  String text,
  String notes,
  _Link? prev,
  _Link? next,
) {
  String pager() => '<div class="pager">'
      '${prev == null ? '<span></span>' : '<a href="${prev.href}">‹ ${_esc(prev.label)}</a>'}'
      '<a href="./" class="up">${_esc(book.shortName)} · kapitoly</a>'
      '${next == null ? '<span></span>' : '<a href="${next.href}">${_esc(next.label)} ›</a>'}'
      '</div>';
  final b = StringBuffer(_head('${book.name} $ch - Sväté písmo', '../biblia.css'));
  b.write('''
<nav><a href="../../">Bible Tracker</a><span class="sep">/</span><a href="../">Sväté písmo</a><span class="sep">/</span><a href="./">${_esc(book.name)}</a><span class="sep">/</span><span>$ch</span></nav>
${pager()}
<h1>${_esc(book.name)} $ch</h1>
<article class="text">
$text
</article>
''');
  if (notes.isNotEmpty) {
    b.write('<section class="notes"><h2>Poznámky</h2>\n$notes</section>\n');
  }
  b.writeln(pager());
  b.write(_foot());
  return b.toString();
}

// ---------------------------------------------------------------------------
// SSV markup → small, safe HTML
// ---------------------------------------------------------------------------

const _keep = {'p', 'strong', 'b', 'em', 'i', 'sup', 'sub', 'br', 'ol', 'ul', 'li'};
const _drop = {'script', 'style', 'hr', 'img', 'iframe', 'object'};
final _noteHref = RegExp(r'^#v(\d{1,3})$');

String _cleanText(String html, List<ChapterNote> notes) {
  final out = StringBuffer();
  for (final n in html_parser.parseFragment(html).nodes) {
    _clean(n, out, notes);
  }
  return out.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

void _clean(dom.Node node, StringBuffer out, List<ChapterNote> notes) {
  if (node is dom.Text) {
    out.write(_esc(node.text));
    return;
  }
  if (node is! dom.Element) return;
  final tag = node.localName!;
  if (_drop.contains(tag)) return;
  void children() {
    for (final c in node.nodes) {
      _clean(c, out, notes);
    }
  }

  // Section titles: <h1 align=center> → centred bold paragraph.
  if (tag == 'h1' || tag == 'h2' || tag == 'h3') {
    if (node.text.trim().replaceAll(' ', '').isEmpty) return;
    out.write('<p class="c"><strong>');
    children();
    out.write('</strong></p>\n');
    return;
  }
  if (tag == 'a') {
    final m = _noteHref.firstMatch(node.attributes['href'] ?? '');
    // SSV sometimes links a verse whose note is a range starting earlier,
    // or a note it does not have: link the covering note, or drop the link.
    final hits = m == null
        ? const <ChapterNote>[]
        : NoteParser.forVerse(notes, int.parse(m.group(1)!));
    if (hits.isEmpty) return children();
    out.write('<a href="#n${hits.first.verse}" class="fn">');
    children();
    out.write('</a>');
    return;
  }
  if (!_keep.contains(tag)) return children();
  // SSV spaces sections with empty "&nbsp;" paragraphs; CSS does that here.
  if (tag == 'p' && node.text.replaceAll(' ', '').trim().isEmpty) return;

  final cls = <String>[];
  if (node.attributes['align'] == 'center') cls.add('c');
  // SSV writes poetry one line per paragraph: short lines without a
  // heading sit close together instead of being spaced like prose.
  if (tag == 'p' &&
      cls.isEmpty &&
      node.text.trim().length < 90 &&
      node.querySelector('strong, b') == null) {
    cls.add('l');
  }
  if ((node.attributes['style'] ?? '').contains('margin-left')) cls.add('in');
  final attrs = StringBuffer();
  if (cls.isNotEmpty) attrs.write(' class="${cls.join(' ')}"');
  final value = int.tryParse(node.attributes['value'] ?? '');
  if (tag == 'li' && value != null) attrs.write(' value="$value"');
  if (tag == 'br') {
    out.write('<br>');
    return;
  }
  out.write('<$tag$attrs>');
  children();
  out.write('</$tag>');
  if (tag == 'p' || tag == 'ol' || tag == 'ul') out.write('\n');
}

String _notes(String? notesHtml) {
  final seen = <int>{};
  final b = StringBuffer();
  for (final n in NoteParser.parse(notesHtml)) {
    final id = seen.add(n.verse) ? ' id="n${n.verse}"' : '';
    final label = n.isRange ? '${n.verse} – ${n.verseEnd}' : '${n.verse}';
    final body = n.text.split('\n').map(_esc).join('<br>');
    b.writeln('<p class="note"$id><b>$label</b> $body</p>');
  }
  return b.toString();
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ---------------------------------------------------------------------------
// Style
// ---------------------------------------------------------------------------

const _css = r'''
:root{
  --bg:#0b0d13; --panel:#121620; --line:rgba(255,255,255,.10);
  --text:#fff; --muted:rgba(255,255,255,.62); --gold:#f2b632;
}
*{box-sizing:border-box;margin:0;padding:0}
html,body{overflow-x:clip}
body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  background:var(--bg);color:var(--text);line-height:1.55;-webkit-font-smoothing:antialiased}
a{color:var(--gold)}
.wrap{max-width:760px;margin:0 auto;padding:0 16px}
.wrap:has(.testaments){max-width:1080px}
.testaments{display:grid;grid-template-columns:1fr 1fr;gap:0 28px;align-items:start}
@media (max-width:760px){.testaments{grid-template-columns:1fr}}
nav{display:flex;flex-wrap:wrap;gap:4px 10px;padding:22px 0 10px;font-size:14px;letter-spacing:.03em}
nav a{color:var(--muted);text-decoration:none}
nav a:hover{color:#fff}
nav .sep{opacity:.35}
h1{font-size:clamp(28px,6vw,42px);font-weight:900;letter-spacing:-.01em;margin:18px 0 6px}
h2{font-size:20px;font-weight:800;margin:30px 0 12px}
.sub{color:var(--muted);font-size:14px}

h3{font-size:12px;letter-spacing:.18em;text-transform:uppercase;color:var(--muted);font-weight:700;margin:20px 0 10px}
ul.books{list-style:none;display:grid;gap:8px}
ul.books a{display:flex;align-items:baseline;gap:10px;padding:11px 14px;border-radius:10px;
  border:1px solid var(--line);background:var(--panel);color:var(--text);text-decoration:none}
ul.books a:hover{border-color:rgba(242,182,50,.5)}
.abbr{min-width:3.2em;color:var(--gold);font-weight:700;font-size:13px}
ul.books .name{flex:1;font-weight:600}
ul.books .count{color:var(--muted);font-size:13px}
.dc{color:#c9962a;font-size:.8em;font-weight:400}

ul.chapters{list-style:none;display:grid;grid-template-columns:repeat(auto-fill,minmax(52px,1fr));gap:8px;margin-top:22px}
ul.chapters a{display:grid;place-items:center;height:48px;border-radius:10px;border:1px solid var(--line);
  background:var(--panel);color:var(--text);text-decoration:none;font-weight:600}
ul.chapters a:hover{border-color:rgba(242,182,50,.5);color:var(--gold)}

.pager{display:flex;justify-content:space-between;align-items:center;gap:10px;margin:14px 0;font-size:14px}
.pager a{padding:8px 12px;border-radius:100px;border:1px solid var(--line);text-decoration:none;white-space:nowrap}
.pager .up{color:var(--muted)}

.text{font-family:Georgia,"Times New Roman",serif;font-size:19px;line-height:1.7;margin:18px 0 10px;
  overflow-wrap:break-word}
.text p{margin:0 0 .8em}
.text p.c{text-align:center;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  font-size:15px;color:var(--gold);margin:1.4em 0 .6em}
.text p.in{margin-left:1.6em;margin-bottom:.15em}
.text p.l{margin-bottom:.15em}
.text p.l + p:not(.l):not(.in){margin-top:.65em}
.text sup{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;font-size:.6em;
  color:var(--muted);font-weight:700;padding-right:2px}
.text a.fn{text-decoration:none}
.text a.fn sup,.text sup a.fn{color:var(--gold)}
.text ol,.text ul{padding-left:1.6em}

.notes{margin-top:26px;padding-top:6px;border-top:1px solid var(--line)}
.note{font-size:15px;color:rgba(255,255,255,.82);margin-bottom:10px;scroll-margin-top:16px}
.note b{color:var(--gold);margin-right:4px}
.note:target{background:rgba(242,182,50,.10);border-radius:8px;outline:6px solid rgba(242,182,50,.10)}

footer{margin-top:34px;padding:22px 0 40px;border-top:1px solid var(--line);font-size:12px;
  letter-spacing:.05em;color:var(--muted)}
''';
