import 'dart:async';

import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/features/bible/widgets/verse_chapter_view.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
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
  ReaderTextView textView = ReaderTextView.verses,
  int? initialVerse,
}) {
  // Drift streams left open at the end of a widget test leave a pending
  // timer, so the stream providers the reader watches are faked here and
  // the tests check the database through the DAOs.
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
      verseBookmarksProvider.overrideWith(
        (_) => verseBookmarksStream ?? Stream.value(const []),
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

  testWidgets('books reader shows bookmark icon in AppBar', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Free reading chapter');

    await tester.pumpWidget(_testReader(db, ref));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-bookmark-button')), findsOneWidget);
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

  testWidgets('books reader can toggle bookmark', (tester) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Bookmarkable chapter');

    await tester.pumpWidget(_testReader(db, ref));
    await tester.pumpAndSettle();

    expect(
      await db.bookmarkDao.isBookmarked(VerseRef.inChapter(ref, 1)),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('reader-bookmark-button')));
    await tester.pumpAndSettle();

    expect(
      await db.bookmarkDao.isBookmarked(VerseRef.inChapter(ref, 1)),
      isTrue,
    );
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

  testWidgets('swipe boundary Genesis 50 navigates to Exodus 1', (tester) async {
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

  testWidgets('swipe right at first chapter stays on Genesis 1', (tester) async {
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

    testWidgets('the original view setting shows the raw HTML', (
      tester,
    ) async {
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

    testWidgets('tapping a verse opens actions and bookmarks it', (
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

      await tester.tap(find.byKey(const Key('verse-action-bookmark')));
      await tester.pumpAndSettle();

      expect(
        await db.bookmarkDao.isBookmarked(const VerseRef('gen', 1, 2)),
        isTrue,
      );
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
}
