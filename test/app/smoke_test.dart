import 'package:bible_tracker/app/app.dart';
import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/plan/screens/plan_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Opens a fresh in-memory database for each test.
AppDatabase _testDb() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

// Builds BibleTrackerApp with the real router overridden to allow widget-test
// navigation without requiring a platform window.
Widget _testApp(
  AppDatabase db, {
  Map<String, int> downloadedCounts = const {},
}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWith((ref) {
      return db;
    }),
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

  // ── Bottom navigation ────────────────────────────────────────────────────

  testWidgets('bottom navigation bar has 3 destinations', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });

  testWidgets('localized tab labels are visible', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    expect(find.text('Biblia'), findsWidgets);
    expect(find.text('Plán'), findsWidgets);
    expect(find.text('Štatistika'), findsWidgets);
  });

  testWidgets('initial route shows Biblia screen', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    // AppBar title on the Biblia placeholder
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Biblia')),
      findsOneWidget,
    );
  });

  testWidgets('tapping Plán tab navigates to plan screen', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plán').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Plán čítania'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping Štatistika tab navigates to statistics screen', (
    tester,
  ) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Štatistika').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Štatistika čítania'),
      ),
      findsOneWidget,
    );
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
    expect(l10n.tabBiblia, 'Biblia');
    expect(l10n.tabPlan, 'Plán');
    expect(l10n.tabStatistika, 'Štatistika');
  });

  // ── GoRouter ─────────────────────────────────────────────────────────────

  testWidgets('GoRouter is present in the widget tree', (tester) async {
    final db = _testDb();
    await tester.pumpWidget(_testApp(db));
    await tester.pumpAndSettle();

    // InheritedGoRouter is available somewhere in the tree.
    final context = tester.element(find.byType(NavigationBar));
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

    await tester.tap(find.text('Biblia').last);
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
