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

Drift (SQLite), schema version 2. Five tables:

| Table | Purpose |
|---|---|
| `chapter_texts` | Downloaded chapter HTML/text from SSV |
| `read_chapters` | Global read progress (bookId + chapterNumber + readAt) |
| `reading_plans` | Active reading plan metadata |
| `plan_days` | Per-day chapter assignments for the active plan |
| `bookmarked_chapters` | Chapter bookmarks (bookId + chapterNumber + bookmarkedAt) |

### Features

- **Bible browser** — browse all 73 books grouped by testament; shows download status and bookmarked chapters per book.
- **Offline reader** — downloads chapter HTML from biblia.ssv.sk; reads offline afterward; FAB toggles read/unread state.
- **Bookmarks** — bookmark any chapter from the reader; accessible via the bookmark icon in the Bible tab app bar.
- **Reading plan** — create a plan by selecting books and a day count; immutable schedule after creation; tracks daily progress with ahead/behind status.
- **Statistics** — global chapter counts by testament, plan progress metrics.
- **Light + dark theme** — follows system theme (`ThemeMode.system`).
