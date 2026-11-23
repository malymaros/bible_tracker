import 'dart:async';

import 'package:bible_tracker/core/constants/ssv_constants.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/core/services/download_service.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/features/bible/widgets/verse_chapter_view.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/shared/providers/reader_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Widget _testReader(
  AppDatabase db,
  ChapterRef ref, {
  ReaderContext readerContext = ReaderContext.books,
  Stream<Set<ChapterRef>>? readChaptersStream,
  Stream<List<VerseBookmark>>? verseBookmarksStream,
  Stream<List<ColorBookmark>>? colorBookmarksStream,
  ReaderTextView textView = ReaderTextView.verses,
  int? initialVerse,
  _FakeDownloadService? downloads,
}) {
  // Drift streams left open at the end of a widget test leave a pending
  // timer, so the stream providers the reader watches are faked here and
  // the tests check the database through the DAOs.
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
      downloadServiceProvider.overrideWithValue(
        downloads ?? _FakeDownloadService(),
      ),
      verseBookmarksProvider.overrideWith(
        (_) => verseBookmarksStream ?? Stream.value(const []),
      ),
      colorBookmarksProvider.overrideWith(
        (_) => colorBookmarksStream ?? Stream.value(const []),
      ),
      readerTextViewProvider.overrideWith((_) => Stream.value(textView)),
      if (readerContext == ReaderContext.plan)
        readChaptersProvider.overrideWith(
          (_) => readChaptersStream ?? Stream.value(const {}),
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(
        bookId: ref.bookId,
        chapterNumber: ref.chapterNumber,
        readerContext: readerContext,
        initialVerse: initialVerse,
      ),
    ),
  );
}

Future<void> _insertChapter(AppDatabase db, ChapterRef ref, String text) {
  return db.chapterTextDao.upsertChapterText(
    ref: ref,
    htmlContent: '<p><strong>$text</strong></p>',
    plainText: text,
    sourceUrl: 'https://example.test/${ref.bookId}/${ref.chapterNumber}',
    parserVersion: 1,
    cachedAt: DateTime(2026, 1, 1),
  );
}

/// Records the chapters the reader fetches again; no network in tests.
class _FakeDownloadService implements DownloadService {
  final refreshed = <ChapterRef>[];

  @override
  Stream<BookDownloadProgress> downloadBook(BibleBook book) =>
      const Stream.empty();

  @override
  Future<void> refreshChapter(BibleBook book, int chapter) async {
    refreshed.add(ChapterRef(book.id, chapter));
  }
}

Finder _richText(String text) => find.text(text, findRichText: true);

void main() {
  testWidgets('downloaded chapter renders cached html', (tester) async {
    final db = _openTestDb();
    await _insertChapter(
      db,
      const ChapterRef('gen', 1),
      'Downloaded Genesis 1',
    );

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 1)));
    await tester.pumpAndSettle();

    expect(find.text('Genezis 1'), findsOneWidget);
    expect(_richText('Downloaded Genesis 1'), findsOneWidget);
  });

  testWidgets('missing chapter shows not-downloaded state', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 1)));
    await tester.pumpAndSettle();

    expect(find.text('Kapitola nie je stiahnutá'), findsOneWidget);
    expect(find.text('Stiahnuť knihu'), findsOneWidget);
    expect(find.text('Otvoriť na webe SSV'), findsOneWidget);
  });

  testWidgets('books reader has no chapter bookmark button', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Free reading chapter');

    await tester.pumpWidget(_testReader(db, ref));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-bookmark-button')), findsNothing);
    expect(find.byKey(const Key('reader-mark-read-fab')), findsNothing);
  });

  testWidgets('books reader has no read controls', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Free reading chapter');

    await tester.pumpWidget(_testReader(db, ref));
    await tester.pumpAndSettle();

    expect(await db.progressDao.isRead(ref), isFalse);
    expect(find.text('Označiť ako prečítané'), findsNothing);
    expect(find.text('Označiť ako neprečítané'), findsNothing);
    expect(find.byKey(const Key('reader-mark-read-fab')), findsNothing);
  });

  testWidgets('plan reader does not show bookmark icon', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Plan reading chapter');

    await tester.pumpWidget(
      _testReader(db, ref, readerContext: ReaderContext.plan),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-bookmark-button')), findsNothing);
    expect(find.byKey(const Key('reader-mark-read-fab')), findsOneWidget);
  });

  testWidgets('plan reader shows mark read controls', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Plan reading chapter');

    await tester.pumpWidget(
      _testReader(db, ref, readerContext: ReaderContext.plan),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-mark-read-fab')), findsOneWidget);
    expect(find.text('Označiť ako prečítané'), findsOneWidget);
    expect(find.text('Označiť ako neprečítané'), findsNothing);
  });

  testWidgets('read state shows different label on FAB', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Plan reading chapter');

    await tester.pumpWidget(
      _testReader(
        db,
        ref,
        readerContext: ReaderContext.plan,
        readChaptersStream: Stream.value({ref}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-mark-read-fab')), findsOneWidget);
    expect(find.text('Označiť ako neprečítané'), findsOneWidget);
    expect(find.text('Označiť ako prečítané'), findsNothing);
  });

  testWidgets('plan reader marks chapter read via FAB', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Plan reading chapter');
    final reads = StreamController<Set<ChapterRef>>();
    addTearDown(reads.close);

    await tester.pumpWidget(
      _testReader(
        db,
        ref,
        readerContext: ReaderContext.plan,
        readChaptersStream: reads.stream,
      ),
    );
    reads.add(const <ChapterRef>{});
    await tester.pumpAndSettle();

    expect(find.text('Označiť ako prečítané'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-mark-read-fab')));
    await tester.pump();
    reads.add({ref});
    await tester.pumpAndSettle();

    expect(await db.progressDao.isRead(ref), isTrue);
    expect(find.text('Označiť ako neprečítané'), findsOneWidget);
  });

  testWidgets('swipe boundary Genesis 50 navigates to Exodus 1', (
    tester,
  ) async {
    final db = _openTestDb();
    await _insertChapter(db, const ChapterRef('gen', 50), 'Genesis fifty');
    await _insertChapter(db, const ChapterRef('exod', 1), 'Exodus one');

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 50)));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('reader-swipe-area')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exodus 1'), findsOneWidget);
    expect(_richText('Exodus one'), findsOneWidget);
  });

  testWidgets('swipe right at first chapter stays on Genesis 1', (
    tester,
  ) async {
    final db = _openTestDb();
    await _insertChapter(db, const ChapterRef('gen', 1), 'Genesis one');

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 1)));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('reader-swipe-area')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Genezis 1'), findsOneWidget);
  });

  testWidgets('swipe navigation moves next and previous', (tester) async {
    final db = _openTestDb();
    await _insertChapter(db, const ChapterRef('gen', 1), 'Genesis one');
    await _insertChapter(db, const ChapterRef('gen', 2), 'Genesis two');

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 1)));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('reader-swipe-area')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Genezis 2'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('reader-swipe-area')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Genezis 1'), findsOneWidget);
  });

  group('verse view', () {
    const gen1 = ChapterRef('gen', 1);

    Future<void> insertVerses(AppDatabase db) {
      return db.chapterTextDao.upsertChapterText(
        ref: gen1,
        htmlContent:
            '<p align="center"><strong>Stvorenie sveta</strong></p>'
            '<p>1 <sup>1</sup> Prvý verš textu. <sup>2</sup> Druhý verš '
            'textu.</p>',
        sourceUrl: 'https://example.test/gen/1',
        parserVersion: 1,
        cachedAt: DateTime(2026, 1, 1),
      );
    }

    testWidgets('chapters with verses open in the verse view by default', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reader-verse-scroll')), findsOneWidget);
      expect(find.text('Stvorenie sveta'), findsOneWidget);
    });

    testWidgets('the original view setting shows the raw HTML', (tester) async {
      final db = _openTestDb();
      await insertVerses(db);

      await tester.pumpWidget(
        _testReader(db, gen1, textView: ReaderTextView.original),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reader-verse-scroll')), findsNothing);
      expect(find.byKey(const Key('reader-scroll')), findsOneWidget);
    });

    testWidgets('the toggle stores the other view for the whole app', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reader-text-view-toggle')));
      await tester.pumpAndSettle();

      final rows = await db.select(db.appSettings).get();
      expect(rows.single.key, 'reader_text_view');
      expect(rows.single.value, 'original');
    });

    testWidgets('tapping a verse opens actions and makes it a favourite', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();

      await tester.tapOnText(find.textRange.ofSubstring('Druhý verš'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verse-action-panel')), findsOneWidget);
      expect(find.text('Genezis 1,2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('verse-action-favourite')));
      await tester.pumpAndSettle();

      expect(
        await db.bookmarkDao.isBookmarked(const VerseRef('gen', 1, 2)),
        isTrue,
      );
    });

    Future<Map<String, VerseRef>> colorRows(AppDatabase db) async => {
      for (final r in await db.select(db.colorBookmarks).get())
        r.color: VerseRef(r.bookId, r.chapterNumber, r.verseNumber),
    };

    Future<void> openVerse2(WidgetTester tester) async {
      await tester.tapOnText(find.textRange.ofSubstring('Druhý verš'));
      await tester.pumpAndSettle();
    }

    testWidgets('a free colour goes on the verse at once', (tester) async {
      final db = _openTestDb();
      await insertVerses(db);

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();
      await openVerse2(tester);

      // Each free colour shows a dash.
      expect(find.text('–'), findsNWidgets(BookmarkColor.values.length));

      await tester.tap(find.byKey(const Key('verse-action-color-blue')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bookmark-move-dialog')), findsNothing);
      expect(await colorRows(db), {'blue': const VerseRef('gen', 1, 2)});
    });

    testWidgets('a colour on this verse is taken out by tapping it', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);
      const here = VerseRef('gen', 1, 2);
      await db.bookmarkDao.placeColor(BookmarkColor.green, here);

      await tester.pumpWidget(
        _testReader(
          db,
          gen1,
          colorBookmarksStream: Stream.value([
            ColorBookmark(BookmarkColor.green, here, DateTime(2026)),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // The verse starts with its bookmark.
      expect(find.byKey(const Key('verse-marks-2')), findsOneWidget);

      await openVerse2(tester);
      expect(find.text('Gn 1,2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('verse-action-color-green')));
      await tester.pumpAndSettle();

      expect(await colorRows(db), isEmpty);
    });

    testWidgets('moving a colour from another verse asks first', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);
      const elsewhere = VerseRef('ps', 46, 2);
      await db.bookmarkDao.placeColor(BookmarkColor.red, elsewhere);

      await tester.pumpWidget(
        _testReader(
          db,
          gen1,
          colorBookmarksStream: Stream.value([
            ColorBookmark(BookmarkColor.red, elsewhere, DateTime(2026)),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      await openVerse2(tester);

      // Cancel keeps it where it was.
      await tester.tap(find.byKey(const Key('verse-action-color-red')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bookmark-move-dialog')), findsOneWidget);
      expect(find.text('Ž 46,2'), findsWidgets);
      await tester.tap(find.byKey(const Key('bookmark-move-cancel')));
      await tester.pumpAndSettle();
      expect(await colorRows(db), {'red': elsewhere});

      // Confirm moves it here.
      await tester.tap(find.byKey(const Key('verse-action-color-red')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bookmark-move-confirm')));
      await tester.pumpAndSettle();
      expect(await colorRows(db), {'red': const VerseRef('gen', 1, 2)});
    });

    testWidgets('a verse can be a favourite and carry several colours', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);
      const here = VerseRef('gen', 1, 2);

      await tester.pumpWidget(
        _testReader(
          db,
          gen1,
          verseBookmarksStream: Stream.value([
            VerseBookmark(here, DateTime(2026)),
          ]),
          colorBookmarksStream: Stream.value([
            ColorBookmark(BookmarkColor.blue, here, DateTime(2026)),
            ColorBookmark(BookmarkColor.purple, here, DateTime(2026)),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      final marks = find.descendant(
        of: find.byKey(const Key('verse-marks-2')),
        matching: find.byIcon(Icons.bookmark),
      );
      expect(marks, findsNWidgets(3));
    });

    testWidgets('opening at a verse highlights it without the panel', (
      tester,
    ) async {
      final db = _openTestDb();
      await insertVerses(db);

      await tester.pumpWidget(_testReader(db, gen1, initialVerse: 2));
      await tester.pumpAndSettle();

      final view = tester.widget<VerseChapterView>(
        find.byType(VerseChapterView),
      );
      expect(view.selectedVerse, 2);
      expect(view.scrollToVerse, 2);
      expect(find.byKey(const Key('verse-action-panel')), findsNothing);
    });
  });

  group('footnotes', () {
    const gen1 = ChapterRef('gen', 1);
    const verses =
        '<p>1 <sup>1</sup> Prvý verš textu. <a href="#v2"><sup>2</sup></a> '
        'Druhý verš textu. <sup>3</sup> Tretí verš textu.</p>';

    Future<void> insert(
      AppDatabase db, {
      String? notesHtml,
      int parserVersion = SsvConstants.parserVersion,
    }) {
      return db.chapterTextDao.upsertChapterText(
        ref: gen1,
        htmlContent: verses,
        notesHtml: notesHtml,
        sourceUrl: 'https://example.test/gen/1',
        parserVersion: parserVersion,
        cachedAt: DateTime(2026, 1, 1),
      );
    }

    testWidgets('a verse with a note ends with ⋮ that opens the note', (
      tester,
    ) async {
      final db = _openTestDb();
      await insert(
        db,
        notesHtml:
            '<div id="v2"><div class="faq">2. Krátka poznámka.</div></div>',
      );

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verse-note-mark-2')), findsOneWidget);
      expect(find.byKey(const Key('verse-note-mark-1')), findsNothing);

      await tester.tap(find.byKey(const Key('verse-note-mark-2')));
      await tester.pumpAndSettle();

      expect(find.text('Genezis 1,2'), findsOneWidget);
      expect(find.text('POZNÁMKA'), findsOneWidget);
      expect(find.text('Krátka poznámka.'), findsOneWidget);
      // A short note is shown whole, without "Čítať celú".
      expect(find.byKey(const Key('verse-note-more')), findsNothing);
    });

    testWidgets('a verse without a note has no note block', (tester) async {
      final db = _openTestDb();
      await insert(
        db,
        notesHtml:
            '<div id="v2"><div class="faq">2. Krátka poznámka.</div></div>',
      );

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('Tretí verš'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verse-action-panel')), findsOneWidget);
      expect(find.byKey(const Key('verse-notes')), findsNothing);
    });

    testWidgets('a range note shows for every verse in the range', (
      tester,
    ) async {
      final db = _openTestDb();
      await insert(
        db,
        notesHtml:
            '<div id="v2"><div class="faq">2 – 3. Rozsahová poznámka.</div>'
            '</div>',
      );

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('Tretí verš'));
      await tester.pumpAndSettle();

      expect(find.text('POZNÁMKA K VERŠOM 2 – 3'), findsOneWidget);
      expect(find.text('Rozsahová poznámka.'), findsOneWidget);
    });

    testWidgets('a long note opens with "Čítať celú"', (tester) async {
      final db = _openTestDb();
      final long = List.filled(30, 'Dlhé vysvetlenie verša.').join(' ');
      await insert(
        db,
        notesHtml: '<div id="v2"><div class="faq">2. $long</div></div>',
      );

      await tester.pumpWidget(_testReader(db, gen1));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('verse-note-mark-2')));
      await tester.pumpAndSettle();

      Text noteText() =>
          tester.widget<Text>(find.byKey(const Key('verse-note-text-2')));
      expect(noteText().maxLines, 3);
      expect(find.text('Čítať celú ▾'), findsOneWidget);

      await tester.tap(find.byKey(const Key('verse-note-more')));
      await tester.pumpAndSettle();

      expect(noteText().maxLines, isNull);
      expect(find.text('Zbaliť ▴'), findsOneWidget);
    });

    testWidgets('the original view lists the notes under the text', (
      tester,
    ) async {
      final db = _openTestDb();
      await insert(
        db,
        notesHtml:
            '<div id="v2"><div class="faq">2. Krátka poznámka.</div></div>',
      );

      await tester.pumpWidget(
        _testReader(db, gen1, textView: ReaderTextView.original),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chapter-notes')), findsOneWidget);
      expect(_richText('2. Krátka poznámka.'), findsOneWidget);
    });

    testWidgets('a chapter cached without notes is fetched again once', (
      tester,
    ) async {
      final db = _openTestDb();
      await insert(db, parserVersion: 1);
      final downloads = _FakeDownloadService();

      await tester.pumpWidget(_testReader(db, gen1, downloads: downloads));
      await tester.pumpAndSettle();

      expect(downloads.refreshed, [gen1]);
    });

    testWidgets('a current chapter is not fetched again', (tester) async {
      final db = _openTestDb();
      await insert(db);
      final downloads = _FakeDownloadService();

      await tester.pumpWidget(_testReader(db, gen1, downloads: downloads));
      await tester.pumpAndSettle();

      expect(downloads.refreshed, isEmpty);
    });
  });
}
