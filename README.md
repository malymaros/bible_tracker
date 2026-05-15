# Bible Tracker

Slovak Catholic Bible reading tracker with an integrated offline reader, built with Flutter.

Bible text is sourced from [biblia.ssv.sk](https://biblia.ssv.sk).

This project also serves as an experiment in AI-assisted development — the entire codebase was built using [Claude Code](https://claude.ai/code).

## Features

- **Bible browser** — all 73 Catholic books grouped by Old and New Testament, with deuterocanonical books marked
- **Offline reader** — download chapters from biblia.ssv.sk and read without internet; mark chapters as read/unread
- **Bookmarks** — bookmark chapters from the reader for quick access
- **Reading plan** — create a custom plan by selecting books and a reading period; tracks daily progress with ahead/behind status
- **Statistics** — chapter completion counts by testament and plan progress overview

## Requirements

- Flutter SDK (Dart ^3.11.1)
- Android device or emulator (API 21+)

## Getting started

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build smaller split APKs (recommended for distribution)
flutter build apk --release --split-per-abi
```

## Project structure

```
lib/
  app/          # MaterialApp, GoRouter, theme
  core/
    constants/  # 73 Catholic Bible books (static data), verse counts
    models/     # Domain entities: BibleBook, ChapterRef, PlanDay, ...
    services/   # SsvScraper, DownloadService, PlanGenerator, StatisticsCalculator
    utils/      # ChapterCursor, date helpers
  db/           # Drift SQLite database (5 tables, 4 DAOs)
  features/
    bible/      # Book browser + download management + chapter reader
    plan/       # Reading plan creation and progress tracking
    statistics/ # Reading statistics screen
  shared/       # Cross-feature Riverpod providers and widgets
  l10n/         # Localization (Slovak)
```

## Tech stack

| Package | Version | Purpose |
|---|---|---|
| flutter_riverpod | ^3.3.1 | State management |
| drift + drift_flutter | ^2.33.0 | SQLite persistence |
| go_router | ^17.2.3 | Navigation |
| html | ^0.15.5 | HTML parsing for SSV chapters |
| http | ^1.2.2 | Chapter downloads |
| url_launcher | ^6.3.2 | Open SSV website links |

## Attribution

Bible text © Spolok svätého Vojtecha (SSV).
