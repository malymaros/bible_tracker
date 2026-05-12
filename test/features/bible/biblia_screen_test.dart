import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/services/download_service.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/bible/screens/biblia_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

BibleBook _book(String id) => kBibleBooks.firstWhere((book) => book.id == id);

Widget _testScreen(
  AppDatabase db, {
  DownloadService? downloadService,
  Map<String, int> downloadedCounts = const {},
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        return db;
      }),
      downloadedChapterCountsProvider.overrideWith(
        (ref) => Stream.value(downloadedCounts),
      ),
      if (downloadService != null)
        downloadServiceProvider.overrideWithValue(downloadService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BibliaScreen(),
    ),
  );
}

Future<void> _scrollGroupIntoView(
  WidgetTester tester,
  CatholicCategory category,
) {
  return tester.scrollUntilVisible(
    find.byKey(Key('book-group-${category.name}')),
    500,
    scrollable: find.byType(Scrollable).first,
  );
}

class _FakeDownloadService implements DownloadService {
  final Stream<BookDownloadProgress> Function(BibleBook book) handler;

  _FakeDownloadService(this.handler);

  @override
  Stream<BookDownloadProgress> downloadBook(BibleBook book) => handler(book);
}

void main() {
  testWidgets('shows Slovak Catholic book groups', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testScreen(db));
    await tester.pumpAndSettle();

    expect(find.text('Pentateuch'), findsOneWidget);
    expect(find.text('Historické knihy'), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.wisdomBooks);
    expect(find.text('Múdroslovné knihy'), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.propheticBooks);
    expect(find.text('Prorocké knihy'), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.gospels);
    expect(find.text('Evanjeliá'), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.acts);
    expect(find.byKey(const Key('book-group-acts')), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.paulineLetters);
    expect(find.text('Pavlove listy'), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.catholicLetters);
    expect(find.text('Katolícke listy'), findsOneWidget);

    await _scrollGroupIntoView(tester, CatholicCategory.revelation);
    expect(find.byKey(const Key('book-group-revelation')), findsOneWidget);
  });

  testWidgets('shows visible book rows', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(_testScreen(db));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('book-row-gen')), findsOneWidget);
    expect(find.text('Genezis'), findsOneWidget);
    expect(find.byKey(const Key('book-row-exod')), findsOneWidget);
    expect(find.text('Exodus'), findsOneWidget);
    expect(find.byKey(const Key('book-row-lev')), findsOneWidget);
    expect(find.text('Levitikus'), findsOneWidget);
  });

  testWidgets('shows not downloaded, partial, and downloaded labels', (
    tester,
  ) async {
    final db = _openTestDb();

    await tester.pumpWidget(
      _testScreen(
        db,
        downloadedCounts: {'gen': 1, 'exod': _book('exod').chapterCount},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('čiastočne stiahnuté'), findsOneWidget);
    expect(find.text('stiahnuté'), findsOneWidget);
    expect(find.text('nestiahnuté'), findsWidgets);
  });

  testWidgets('shows downloading label while a book is downloading', (
    tester,
  ) async {
    final db = _openTestDb();
    final fakeDownloadService = _FakeDownloadService((book) {
      return Stream.value(
        BookDownloadProgress(
          bookId: book.id,
          downloadedChapters: 0,
          totalChapters: book.chapterCount,
          status: BookDownloadStatus.downloading,
        ),
      );
    });

    await tester.pumpWidget(
      _testScreen(db, downloadService: fakeDownloadService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('book-row-gen')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stiahnuť knihu'));
    await tester.pumpAndSettle();

    expect(find.text('sťahuje sa'), findsOneWidget);
  });

  testWidgets('shows error label when a download fails', (tester) async {
    final db = _openTestDb();
    final fakeDownloadService = _FakeDownloadService((book) {
      return Stream.value(
        BookDownloadProgress(
          bookId: book.id,
          downloadedChapters: 0,
          totalChapters: book.chapterCount,
          status: BookDownloadStatus.failed,
          errorMessage: 'failed',
        ),
      );
    });

    await tester.pumpWidget(
      _testScreen(db, downloadService: fakeDownloadService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('book-row-gen')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stiahnuť knihu'));
    await tester.pumpAndSettle();

    expect(find.text('chyba'), findsOneWidget);
  });

  testWidgets('tapping a downloaded book opens chapter picker', (tester) async {
    final db = _openTestDb();

    await tester.pumpWidget(
      _testScreen(db, downloadedCounts: {'phlm': _book('phlm').chapterCount}),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('book-row-phlm')),
      find.byType(Scrollable).first,
      const Offset(0, -500),
    );
    await tester.ensureVisible(find.byKey(const Key('book-row-phlm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('book-row-phlm')));
    await tester.pumpAndSettle();

    expect(find.text('List Filemonovi'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Vymazať stiahnutý text'), findsOneWidget);
  });
}
