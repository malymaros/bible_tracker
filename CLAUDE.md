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
```

## Code style

Linting is configured via `flutter_lints` (`analysis_options.yaml`). Run `flutter analyze` to check before committing. No custom lint rules are active yet.

## Architecture

Feature-first layout under `lib/`:

```
app/          # MaterialApp, GoRouter, theme
core/
  constants/  # Static compile-time data (kBibleBooks — never in DB)
  models/     # Domain entities and value objects
  services/   # Pure business logic (SsvScraper, DownloadService, PlanGenerator, StatisticsCalculator)
  utils/      # ChapterCursor, date helpers
db/           # Drift database, tables, DAOs
features/
  bible/      # Book browser + download management (tab 1)
  reader/     # Shared chapter reader (opened from both bible and plan tabs)
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

GoRouter `StatefulShellRoute` for three persistent tabs: `/biblia`, `/plan`, `/statistika`. The reader screen lives in both `/biblia/reader/...` and `/plan/reader/...` route trees — same widget, different parent routes.

### Persistence

Drift (SQLite). Four tables: `chapter_texts`, `read_chapters`, `reading_plans`, `plan_days`.
