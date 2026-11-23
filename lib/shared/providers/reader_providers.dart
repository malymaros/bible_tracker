import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the reader draws chapter text. One app-wide choice: switching it in
/// any reader applies to every place that shows Scripture.
enum ReaderTextView {
  /// Text split into verses, our own typography, verses can be tapped.
  verses,

  /// The SSV HTML drawn as before version 1.1.
  original,
}

const _textViewKey = 'reader_text_view';

final readerTextViewProvider = StreamProvider<ReaderTextView>((ref) {
  return ref
      .watch(settingsDaoProvider)
      .watchValue(_textViewKey)
      .map(
        (v) => v == ReaderTextView.original.name
            ? ReaderTextView.original
            : ReaderTextView.verses,
      );
});

Future<void> setReaderTextView(WidgetRef ref, ReaderTextView view) {
  return ref.read(settingsDaoProvider).setValue(_textViewKey, view.name);
}

/// Favourite verses (gold bookmarks).
final verseBookmarksProvider = StreamProvider<List<VerseBookmark>>((ref) {
  return ref.watch(bookmarkDaoProvider).watchAll();
});

/// The classic colour bookmarks that lie somewhere.
final colorBookmarksProvider = StreamProvider<List<ColorBookmark>>((ref) {
  return ref.watch(bookmarkDaoProvider).watchColors();
});

/// Chapters that hold at least one bookmark, favourite or classic (for the
/// dots in the chapter grid).
final bookmarkedChaptersProvider = StreamProvider<Set<ChapterRef>>((ref) {
  return ref.watch(bookmarkDaoProvider).watchBookmarkedChapters();
});
