# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`bible_tracker` is a Slovak Catholic Bible reading tracker with an integrated offline reader (Flutter, Dart SDK ^3.11.1). Bible text is sourced from biblia.ssv.sk (SSV — Spolok svätého Vojtecha) with explicit permission.

## Commands

```bash
# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (lint)
flutter analyze

# Get/update dependencies
flutter pub get
flutter pub upgrade

# Build release APK
flutter build apk --release

# Build split APKs (smaller, per ABI)
flutter build apk --release --split-per-abi

# Regenerate Drift/Riverpod generated files
dart run build_runner build --delete-conflicting-outputs
```

## Code style

Linting is configured via `flutter_lints` (`analysis_options.yaml`). Run `flutter analyze` to check before committing. No custom lint rules are active yet.

## Architecture

Feature-first layout under `lib/`:

```
app/          # MaterialApp, GoRouter, theme (light + dark)
core/
  constants/  # Static compile-time data (kBibleBooks, verse counts — never in DB)
  models/     # Domain entities and value objects
  services/   # Pure business logic (SsvScraper, DownloadService, PlanGenerator, StatisticsCalculator)
  utils/      # ChapterCursor, date helpers, chapter count formatting
db/           # Drift database, tables, DAOs
features/
  bible/      # Book browser + download management + chapter reader (tab 1)
  rosary/     # Rosary list, detail and guide (from the today's reading card)
  plan/       # Reading plan creation and tracking (tab 2)
  statistics/ # Global reading statistics (tab 3)
shared/       # Cross-feature providers and widgets
l10n/         # ARB files (Slovak only for MVP)
```

### Key domain rules

- **All 73 Catholic Bible books** are defined as `const List<BibleBook> kBibleBooks` in `core/constants/bible_books.dart`. This is static data — never persisted to the database.
- **`BibleBook.ssvSlug`** is the exact URL segment used by biblia.ssv.sk. Chapter URL format: `https://biblia.ssv.sk/biblia/kniha/{ssvSlug}/kapitola/{chapter}.xhtml#ct`
- **SSV canonical ordering** (the `order` field, 1–73) places the Maccabees at positions 45–46, at the end of the OT after Malachi — not after Esther as in some other Catholic orderings.
- **Chapter counts** follow the Catholic/Vulgate canon: Esther=16, Daniel=14, Joel=4, Tobit=14, Baruch=6.
- **Progress is global**: marking a chapter as read in the reader affects the plan progress and statistics simultaneously. There is no per-plan or per-feature progress copy.
- **The reading plan schedule is immutable** after creation. Selected books cannot be changed; the user must delete and recreate the plan.

### State management

Riverpod 2.x with `@riverpod` code generation. DB streams feed Riverpod providers; computed providers derive from those streams. No business logic in widgets.

### Navigation

GoRouter with flat named routes. No `StatefulShellRoute` — bottom navigation is handled at the screen level. Routes:

| Path | Screen |
|---|---|
| `/plan` | PlanScreen (initial route) |
| `/books` | BibliaScreen — book browser |
| `/books/reader/:bookId/:chapter` | ReaderScreen (from Bible tab) |
| `/plan/reader/:bookId/:chapter` | ReaderScreen (from Plan tab, `ReaderContext.plan`) |
| `/statistics` | StatistikaScreen |

The reader widget (`ReaderScreen`) is shared between both reader routes; `ReaderContext` tells it which tab it was opened from.

### Persistence

Drift (SQLite), schema version 5. Seven tables:

| Table | Purpose |
|---|---|
| `chapter_texts` | Downloaded chapter HTML/text from SSV, plus its footnotes (`notes_html`, schema 4) |
| `read_chapters` | Global read progress (bookId + chapterNumber + readAt) |
| `reading_plans` | Active reading plan metadata |
| `plan_days` | Per-day chapter assignments for the active plan |
| `verse_bookmarks` | Favourite verses, gold, any number (bookId + chapterNumber + verseNumber + bookmarkedAt); schema 2 chapter bookmarks were migrated to verse 1, schema ≤ 4 bookmarks became favourites |
| `color_bookmarks` | Classic bookmarks (schema 5): one row per colour (`color` = `BookmarkColor` name, primary key) with the verse it lies on — each colour lies on one verse at most |
| `app_settings` | Key/value user preferences (e.g. `reader_text_view`) |

### Features

- **Bible browser** — browse all 73 books grouped by testament; shows download status and bookmarked chapters per book.
- **Offline reader** — downloads chapter HTML from biblia.ssv.sk; reads offline afterward; FAB toggles read/unread state.
- **Verse view** — `VerseParser` splits the stored SSV HTML into verses; the reader draws them with its own layout (default). A neutral app-bar toggle switches every reader to the original HTML view (one app-wide setting). Chapters whose verse numbers do not only go up fall back to the original view.
- **Footnotes** — the scraper also stores SSV `div.faqs` (`parserVersion` 2); `NoteParser` turns it into `ChapterNote`s (single verse or range "20 – 24"). In the verse view a verse with a note ends with a gold ⋮; the verse panel shows the note (3 lines, "Čítať celú"), range notes show for every verse in the range. The original view lists notes under the text. Chapters cached by parser 1 are fetched again quietly when opened (and by "Stiahnuť knihu").
- **Bookmarks** — tap a verse: the panel has "Obľúbený verš" (gold, on/off, any number) and "Klasická záložka" (5 colours red/blue/green/purple/gray, each one bookmark like a ribbon; under each its place "Ž 46,2" or "–"). Tap a free colour to place it, a ticked one to take it out; taking a colour from another verse asks "Presunúť záložku?". A verse can be a favourite and carry any colours at once; its marks start the verse (gold first). No helper texts in this UI. List via the bookmark icon in the Bible tab app bar: switch "Obľúbené | Klasické" (favourites first, grouped by book in Bible order; classic = 5 rows in colour order, free ones "–"); opens the reader at the verse. Colours/abbreviations in `shared/widgets/bookmark_ui.dart`.
- **Online reader (website)** — `tool/ssv_backup.dart` saves every SSV chapter page + extracted JSON to a local backup (outside the repo); `tool/ssv_site.dart` turns it into the static reader `website/.../bible-tracker/biblia/` (gitignored, uploaded by hand).
- **Verse counts** — `verse_counts.dart` is generated from the SSV text (`tool/verse_counts_from_ssv.dart`); shown in the chapter grid and plan rows.
- **Rosary** — `features/rosary/`, reached only from the rosary button in the top-right corner of the plan's today's reading card: list of the 4 rosaries (today preselected), detail with mysteries and prayer order, step-by-step guide. Content in `core/constants/rosary.dart`.
- **Reading plan** — create a plan by selecting books and a day count; immutable schedule after creation; tracks daily progress with ahead/behind status.
- **Statistics** — global chapter counts by testament, plan progress metrics.
- **Light + dark theme** — follows system theme (`ThemeMode.system`).
