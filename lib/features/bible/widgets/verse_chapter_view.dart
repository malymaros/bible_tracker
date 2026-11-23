import 'package:bible_tracker/core/models/chapter_note.dart';
import 'package:bible_tracker/core/models/parsed_chapter.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Draws a chapter split into verses ("Nové zobrazenie"): section headings,
/// paragraph headings, indented poetry, verse numbers. Each verse can be
/// tapped; [selectedVerse] is highlighted and [bookmarkedVerses] carry a
/// bookmark mark. A verse that opens an SSV footnote ([notes]) ends with a
/// "⋮" mark. When [scrollToVerse] is set the view scrolls to it once.
class VerseChapterView extends StatefulWidget {
  final ParsedChapter chapter;
  final Set<int> bookmarkedVerses;
  final List<ChapterNote> notes;
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
    this.notes = const [],
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

  /// For each note, the last segment of the verse it starts at: the "⋮" goes
  /// after that segment's text. Keyed by (block index, segment index); the
  /// value is the verse the mark opens.
  Map<(int, int), int> _noteMarks() {
    final marks = <(int, int), int>{};
    final blocks = widget.chapter.blocks;
    for (final note in widget.notes) {
      (int, int)? last;
      for (var b = 0; b < blocks.length; b++) {
        final block = blocks[b];
        if (block is! VerseParagraph) continue;
        for (var s = 0; s < block.segments.length; s++) {
          final seg = block.segments[s];
          final v = seg.verse;
          if (v != null && note.verse >= v && note.verse <= seg.verseEnd) {
            last = (b, s);
          }
        }
      }
      if (last == null) continue;
      final block = blocks[last.$1] as VerseParagraph;
      marks[last] = block.segments[last.$2].verse!;
    }
    return marks;
  }

  /// Verses of a multi-verse note that covers the selected verse: tinted so
  /// the reader sees what the note talks about.
  Set<int> _noteRange() {
    final selected = widget.selectedVerse;
    if (selected == null) return const {};
    return {
      for (final n in widget.notes)
        if (n.isRange && n.covers(selected))
          for (var v = n.verse; v <= n.verseEnd; v++) v,
    };
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScroll();
    final blocks = widget.chapter.blocks;
    final marks = _noteMarks();
    final range = _noteRange();
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
                  child: _block(blocks[i], i, marks, range),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(
    ChapterBlock block,
    int index,
    Map<(int, int), int> marks,
    Set<int> range,
  ) {
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
      VerseParagraph() => _paragraph(block, index, marks, range),
    };
  }

  Widget _paragraph(
    VerseParagraph p,
    int blockIndex,
    Map<(int, int), int> marks,
    Set<int> range,
  ) {
    const body = TextStyle(
      fontFamily: _serif,
      fontSize: 19,
      height: 1.75,
      color: AppColors.text,
    );
    final spans = <InlineSpan>[];
    for (var si = 0; si < p.segments.length; si++) {
      final s = p.segments[si];
      final verse = s.verse;
      final selected = verse != null && verse == widget.selectedVerse;
      final inRange = verse != null && !selected && range.contains(verse);
      final marked = verse != null && widget.bookmarkedVerses.contains(verse);
      final background = selected
          ? AppColors.goldSoft
          : inRange
          ? AppColors.gold.withValues(alpha: 0.12)
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
            text: '$number ',
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
      final noteVerse = marks[(blockIndex, si)];
      spans.add(
        TextSpan(
          text: noteVerse == null ? '${s.text.trim()} ' : s.text.trim(),
          recognizer: verse == null ? null : _recognizerFor(verse),
          style: background == null
              ? null
              : TextStyle(backgroundColor: background),
        ),
      );
      if (noteVerse != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _NoteMark(
              key: Key('verse-note-mark-$noteVerse'),
              onTap: () => widget.onVerseTap(noteVerse),
            ),
          ),
        );
        spans.add(const TextSpan(text: ' '));
      }
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

/// The "⋮" after a verse that has an SSV footnote; tapping it opens the verse.
class _NoteMark extends StatelessWidget {
  final VoidCallback onTap;

  const _NoteMark({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: Icon(Icons.more_vert, size: 18, color: AppColors.goldDark),
      ),
    );
  }
}
