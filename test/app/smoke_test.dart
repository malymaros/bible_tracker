import 'package:bible_tracker/app/app.dart';
import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

AppDatabase _testDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Widget _testApp(
  AppDatabase db, {
  Map<String, int> downloadedCounts = const {},
}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWith((ref) => db),
    downloadedChapterCountsProvider.overrideWith(
      (ref) => Stream.value(downloadedCounts),
    ),
    activePlanProvider.overrideWith((ref) => Stream.value(null)),
    readChaptersProvider.overrideWith((ref) => Stream.value(const {})),
  ],
  child: const BibleTrackerApp(),
);

Future<void> _insertChapter(AppDatabase db, ChapterRef ref, String text) {
  return db.chapterTextDao.upsertChapterText(
    ref: ref,
    htmlContent: '<p>$text</p>',
    plainText: text,
    sourceUrl: 'https://example.test/${ref.bookId}/${ref.chapterNumber}',
    parserVersion: 1,
    cachedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  // ── App startup ──────────────────────────────────────────────────────────

  testWidgets('app starts without errors', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    expect(find.byType(BibleTrackerApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial route shows Plan screen', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    // Plan screen shows create-plan title when no plan exists
    expect(find.text('Vytvoriť plán čítania'), findsOneWidget);
  });

  testWidgets('no bottom navigation bar', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('Knihy button opens Books screen', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plan-books-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('Biblia'), findsWidgets);
    expect(find.text('Pentateuch'), findsOneWidget);
  });

  // ── Localizations ────────────────────────────────────────────────────────

  testWidgets('AppLocalizations resolves for Slovak locale', (tester) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(l10n.appTitle, 'Bible Tracker');
    expect(l10n.navBooks, 'Knihy');
    expect(l10n.planTotalProgressTitle, 'Pokrok plánu');
  });

  // ── GoRouter ─────────────────────────────────────────────────────────────

  testWidgets('GoRouter is present in the widget tree', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(GoRouter.maybeOf(context), isNotNull);
  });

  testWidgets('chapter picker opens reader screen', (tester) async {
    final db = _testDb();
    const ref = ChapterRef('phlm', 1);
    final philemon = kBibleBooks.firstWhere((book) => book.id == 'phlm');
    await _insertChapter(db, ref, 'Reader opened from picker');

    await tester.pumpWidget(
      _testApp(db, downloadedCounts: {'phlm': philemon.chapterCount}),
    );
    await tester.pumpAndSettle();

    // Navigate to Books screen via Knjiy button
    await tester.tap(find.byKey(const Key('plan-books-nav-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('book-row-phlm')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('book-row-phlm')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();

    expect(find.text('List Filemonovi 1'), findsOneWidget);
    expect(
      find.text('Reader opened from picker', findRichText: true),
      findsOneWidget,
    );
  });
}
