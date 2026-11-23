import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';

/// Colour of a favourite verse's bookmark.
const Color kFavouriteBookmarkColor = AppColors.gold;

/// Display colour of a classic bookmark.
Color bookmarkColorOf(BookmarkColor color) => switch (color) {
  BookmarkColor.red => const Color(0xFFD0342C),
  BookmarkColor.blue => const Color(0xFF2D6FD2),
  BookmarkColor.green => const Color(0xFF2E8B4E),
  BookmarkColor.purple => const Color(0xFF8150C9),
  BookmarkColor.gray => const Color(0xFF66707D),
};

/// Name of a classic bookmark's colour, for screen readers.
String bookmarkColorName(AppLocalizations l10n, BookmarkColor color) =>
    switch (color) {
      BookmarkColor.red => l10n.bookmarkColorRed,
      BookmarkColor.blue => l10n.bookmarkColorBlue,
      BookmarkColor.green => l10n.bookmarkColorGreen,
      BookmarkColor.purple => l10n.bookmarkColorPurple,
      BookmarkColor.gray => l10n.bookmarkColorGray,
    };

/// Short reference of a verse: "Ž 46,2".
String verseAbbreviation(VerseRef verse) {
  final book = kBibleBooks.firstWhere((b) => b.id == verse.bookId);
  return '${book.shortName} ${verse.chapterNumber},${verse.verseNumber}';
}

/// Full reference of a verse: "Žalmy 46,2".
String verseFullName(VerseRef verse) {
  final book = kBibleBooks.firstWhere((b) => b.id == verse.bookId);
  return '${book.name} ${verse.chapterNumber},${verse.verseNumber}';
}

/// A bookmark ribbon, optionally with a white tick on it.
class BookmarkGlyph extends StatelessWidget {
  final Color color;
  final double size;
  final bool checked;

  const BookmarkGlyph({
    super.key,
    required this.color,
    this.size = 24,
    this.checked = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.bookmark, color: color, size: size);
    if (!checked) return icon;
    return Stack(
      alignment: Alignment.center,
      children: [
        icon,
        Padding(
          padding: EdgeInsets.only(bottom: size * 0.18),
          child: Icon(Icons.check, color: Colors.white, size: size * 0.5),
        ),
      ],
    );
  }
}
