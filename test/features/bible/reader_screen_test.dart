import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Widget _testReader(AppDatabase db, ChapterRef ref) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(bookId: ref.bookId, chapterNumber: ref.chapterNumber),
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

  testWidgets('reader has no read controls and does not change progress', (
    tester,
  ) async {
    final db = _openTestDb();
    const ref = ChapterRef('gen', 1);
    await _insertChapter(db, ref, 'Free reading chapter');

    await tester.pumpWidget(_testReader(db, ref));
    await tester.pumpAndSettle();

    expect(await db.progressDao.isRead(ref), isFalse);
    expect(find.text('Označiť ako prečítané'), findsNothing);
    expect(find.text('Označiť ako neprečítané'), findsNothing);
  });

  testWidgets('next and previous buttons navigate chapters', (tester) async {
    final db = _openTestDb();
    await _insertChapter(db, const ChapterRef('gen', 1), 'Genesis one');
    await _insertChapter(db, const ChapterRef('gen', 2), 'Genesis two');

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 1)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Genezis 2'), findsOneWidget);
    expect(_richText('Genesis two'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-previous-button')));
    await tester.pumpAndSettle();

    expect(find.text('Genezis 1'), findsOneWidget);
    expect(_richText('Genesis one'), findsOneWidget);
  });

  testWidgets('boundary Genesis 50 navigates to Exodus 1', (tester) async {
    final db = _openTestDb();
    await _insertChapter(db, const ChapterRef('gen', 50), 'Genesis fifty');
    await _insertChapter(db, const ChapterRef('exod', 1), 'Exodus one');

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 50)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Exodus 1'), findsOneWidget);
    expect(_richText('Exodus one'), findsOneWidget);
  });

  testWidgets('boundary Genesis 1 has no previous chapter', (tester) async {
    final db = _openTestDb();
    await _insertChapter(db, const ChapterRef('gen', 1), 'Genesis one');

    await tester.pumpWidget(_testReader(db, const ChapterRef('gen', 1)));
    await tester.pumpAndSettle();

    final previousButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('reader-previous-button')),
    );
    expect(previousButton.onPressed, isNull);
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
}
