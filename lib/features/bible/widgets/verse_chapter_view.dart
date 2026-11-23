import 'package:bible_tracker/core/models/parsed_chapter.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Draws a chapter split into verses ("Nové zobrazenie"): section headings,
/// paragraph headings, indented poetry, verse numbers. Each verse can be
/// tapped; [selectedVerse] is highlighted and [bookmarkedVerses] carry a
/// bookmark mark. When [scrollToVerse] is set the view scrolls to it once.
class VerseChapterView extends StatefulWidget {
  final ParsedChapter chapter;
  final Set<int> bookmarkedVerses;
  final int? selectedVerse;
  final int? scrollToVerse;
  final ValueChanged<int> onVerseTap;

  /// Extra space under the text so the action panel or FAB never hides it.
  final double bottomPadding;

  const VerseChapterView({
    super.key,
    required this.chapter,
    required this.bookmarkedVerses,
    required this.onVerseTap,
    this.selectedVerse,
    this.scrollToVerse,
    this.bottomPadding = 120,
  });

  @override
  State<VerseChapterView> createState() => _VerseChapterViewState();
}

class _VerseChapterViewState extends State<VerseChapterView> {
  static const _serif = 'serif';

  final _scrollController = ScrollController();
  final _recognizers = <int, TapGestureRecognizer>{};
  final _blockKeys = <int, GlobalKey>{};
  int? _scrolledTo;

  @override
  void didUpdateWidget(VerseChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.chapter, widget.chapter)) {
      _blockKeys.clear();
      _scrolledTo = null;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(int verse) => _recognizers.putIfAbsent(
    verse,
    () => TapGestureRecognizer()..onTap = () => widget.onVerseTap(verse),
  );

  void _scheduleScroll() {
    final target = widget.scrollToVerse;
    if (target == null || _scrolledTo == target) return;
    final blocks = widget.chapter.blocks;
    final index = blocks.indexWhere(
      (b) =>
          b is VerseParagraph &&
          b.segments.any((s) => s.startsVerse && s.verse == target),
    );
    if (index < 0) return;
    _scrolledTo = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _blockKeys[index]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.15,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScroll();
    final blocks = widget.chapter.blocks;
    return SafeArea(
      top: false,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          key: const Key('reader-verse-scroll'),
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(24, 12, 24, widget.bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < blocks.length; i++)
                KeyedSubtree(
                  key: _blockKeys.putIfAbsent(i, GlobalKey.new),
                  child: _block(context, blocks[i], i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(BuildContext context, ChapterBlock block, int index) {
    return switch (block) {
      SectionHeading(:final text) => Padding(
        padding: EdgeInsets.only(top: index == 0 ? 4 : 18, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: _serif,
            fontSize: 21,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: AppColors.text,
          ),
        ),
      ),
      VerseParagraph() => _paragraph(block),
    };
  }

  Widget _paragraph(VerseParagraph p) {
    const body = TextStyle(
      fontFamily: _serif,
      fontSize: 19,
      height: 1.75,
      color: AppColors.text,
    );
    final spans = <InlineSpan>[];
    for (final s in p.segments) {
      final verse = s.verse;
      final selected = verse != null && verse == widget.selectedVerse;
      final marked = verse != null && widget.bookmarkedVerses.contains(verse);
      final background = selected
          ? AppColors.goldSoft
          : marked
          ? AppColors.error.withValues(alpha: 0.07)
          : null;
      if (s.startsVerse) {
        if (marked) {
          spans.add(
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: 2),
                child: Icon(Icons.bookmark, size: 14, color: AppColors.error),
              ),
            ),
          );
        }
        final number = s.verseEnd != verse ? '$verse–${s.verseEnd}' : '$verse';
        spans.add(
          TextSpan(
            text: verse == 1 ? '$number ' : '$number ',
            recognizer: _recognizerFor(verse!),
            style: verse == 1
                ? const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    height: 1.2,
                  )
                : const TextStyle(
                    fontFamily: null,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDark,
                  ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: '${s.text.trim()} ',
          recognizer: verse == null ? null : _recognizerFor(verse),
          style: background == null
              ? null
              : TextStyle(backgroundColor: background),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: p.indented ? 24 : 0,
        bottom: p.indented ? 2 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.heading != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                p.heading!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.goldDark,
                ),
              ),
            ),
          Text.rich(TextSpan(style: body, children: spans)),
        ],
      ),
    );
  }
}
