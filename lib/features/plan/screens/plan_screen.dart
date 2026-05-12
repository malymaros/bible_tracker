import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/utils/chapter_count_format.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_generator.dart';
import 'package:bible_tracker/features/bible/screens/biblia_screen.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/features/statistics/screens/statistika_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlan = ref.watch(activePlanProvider);

    return activePlan.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: const _BooksNavLeading(),
          leadingWidth: 48,
          title: const _PlanAppBarTitle(),
          centerTitle: true,
          backgroundColor: _PlanColors.background,
          surfaceTintColor: _PlanColors.background,
        ),
        backgroundColor: _PlanColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: const _BooksNavLeading(),
          leadingWidth: 48,
          title: const _PlanAppBarTitle(),
          centerTitle: true,
          backgroundColor: _PlanColors.background,
          surfaceTintColor: _PlanColors.background,
        ),
        backgroundColor: _PlanColors.background,
        body: Center(child: Text(error.toString())),
      ),
      data: (plan) {
        if (plan == null) {
          return const CreatePlanScreen();
        }
        return _ExistingPlanScreen(plan: plan);
      },
    );
  }
}

class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  late DateTime _startDate;
  final _daysController = TextEditingController(text: '365');
  late final Set<String> _selectedBookIds;

  @override
  void initState() {
    super.initState();
    _startDate = ref.read(todayProvider);
    _selectedBookIds = {for (final book in kBibleBooks) book.id};
    _daysController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedBooks = _selectedBooks;
    final selectedChapters = _selectedChapterCount;
    final totalDays = int.tryParse(_daysController.text.trim());
    final validation = _validationMessage(l10n, totalDays, selectedChapters);
    final endDate = totalDays == null || totalDays < 1
        ? null
        : _startDate.add(Duration(days: totalDays - 1));

    return Scaffold(
      appBar: AppBar(
        leading: const _BooksNavLeading(),
        leadingWidth: 48,
        title: const _PlanAppBarTitle(),
        centerTitle: true,
        backgroundColor: _PlanColors.background,
        surfaceTintColor: _PlanColors.background,
      ),
      backgroundColor: _PlanColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.planCreateTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _PlanColors.textStrong,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                key: const Key('plan-start-date-button'),
                onPressed: _pickStartDate,
                icon: const Icon(Icons.calendar_today, size: 20),
                label: Text(
                  '${l10n.planStartDate}: ${_formatDate(_startDate)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('plan-total-days-field'),
              controller: _daysController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                color: _PlanColors.textStrong,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: l10n.planTotalDays,
                labelStyle: const TextStyle(fontSize: 17),
                border: const OutlineInputBorder(),
                errorText: validation,
                errorStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _PreviewLine(
                    label: l10n.planSelectedBooks,
                    value: '${selectedBooks.length}',
                  ),
                  const SizedBox(height: 6),
                  _PreviewLine(
                    label: l10n.planSelectedChapters,
                    value: formatChapterCount(selectedChapters),
                  ),
                  const SizedBox(height: 6),
                  _PreviewLine(
                    label: l10n.planDateRange,
                    value: endDate == null
                        ? l10n.planDateRangeUnavailable
                        : '${_formatDate(_startDate)} - ${_formatDate(endDate)}',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(
                l10n.planIncludedBooks,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _PlanColors.textStrong,
                ),
              ),
            ),
            const TestamentHeader(title: 'Starý zákon'),
            for (final group in _otBookGroups)
              _BookSelectionGroup(
                group: group,
                selectedBookIds: _selectedBookIds,
                onChanged: (bookId, selected) {
                  setState(() {
                    if (selected) {
                      _selectedBookIds.add(bookId);
                    } else {
                      _selectedBookIds.remove(bookId);
                    }
                  });
                },
              ),
            const TestamentHeader(title: 'Nový zákon'),
            for (final group in _ntBookGroups)
              _BookSelectionGroup(
                group: group,
                selectedBookIds: _selectedBookIds,
                onChanged: (bookId, selected) {
                  setState(() {
                    if (selected) {
                      _selectedBookIds.add(bookId);
                    } else {
                      _selectedBookIds.remove(bookId);
                    }
                  });
                },
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                key: const Key('plan-create-button'),
                onPressed: validation == null && selectedBooks.isNotEmpty
                    ? () => _createPlan(selectedBooks, totalDays!)
                    : null,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  l10n.planCreateAction,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BibleBook> get _selectedBooks {
    return kBibleBooks
        .where((book) => _selectedBookIds.contains(book.id))
        .toList();
  }

  int get _selectedChapterCount {
    return _selectedBooks.fold(0, (sum, book) => sum + book.chapterCount);
  }

  String? _validationMessage(
    AppLocalizations l10n,
    int? totalDays,
    int selectedChapters,
  ) {
    if (totalDays == null || totalDays < 1) {
      return l10n.planInvalidDayCount;
    }
    if (_selectedBookIds.isEmpty) {
      return l10n.planSelectAtLeastOneBook;
    }
    if (totalDays > selectedChapters) {
      return l10n.planTooManyDays;
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(
        () => _startDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _createPlan(List<BibleBook> selectedBooks, int totalDays) async {
    final plan = ReadingPlan(
      id: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      startDate: _startDate,
      totalDays: totalDays,
      selectedBookIds: selectedBooks.map((book) => book.id).toList(),
      createdAt: DateTime.now(),
    );
    final days = PlanGenerator.generatePlan(
      planId: plan.id,
      startDate: plan.startDate,
      totalDays: plan.totalDays,
      selectedBooks: selectedBooks,
    );
    await ref.read(planDaoProvider).insertPlanWithDays(plan, days);
  }
}

class _ExistingPlanScreen extends ConsumerStatefulWidget {
  final ReadingPlan plan;

  const _ExistingPlanScreen({required this.plan});

  @override
  ConsumerState<_ExistingPlanScreen> createState() =>
      _ExistingPlanScreenState();
}

class _ExistingPlanScreenState extends ConsumerState<_ExistingPlanScreen> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days =
        ref.watch(planDaysProvider(widget.plan.id)).value ?? const <PlanDay>[];
    final readChapters =
        ref.watch(readChaptersProvider).value ?? const <ChapterRef>{};
    final today = ref.watch(todayProvider);
    final selectedIndex = _effectiveSelectedIndex(days, today);
    final selectedDay = days.isEmpty ? null : days[selectedIndex];

    return Scaffold(
      backgroundColor: _PlanColors.background,
      appBar: AppBar(
        leading: const _BooksNavLeading(),
        leadingWidth: 48,
        title: const _PlanAppBarTitle(),
        centerTitle: true,
        backgroundColor: _PlanColors.background,
        surfaceTintColor: _PlanColors.background,
        actions: [
          IconButton(
            tooltip: l10n.planDeleteAction,
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(Icons.delete_outline, color: _PlanColors.textMuted),
          ),
        ],
      ),
      body: selectedDay == null
          ? Center(child: Text(l10n.planNoReadingToday))
          : GestureDetector(
              key: const Key('plan-day-swipe-area'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200) {
                  _selectDay(selectedIndex + 1, days.length);
                } else if (velocity > 200) {
                  _selectDay(selectedIndex - 1, days.length);
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _DayNavigationCard(
                    day: selectedDay,
                    totalDays: days.length,
                    canGoPrevious: selectedIndex > 0,
                    canGoNext: selectedIndex < days.length - 1,
                    onPrevious: () =>
                        _selectDay(selectedIndex - 1, days.length),
                    onNext: () => _selectDay(selectedIndex + 1, days.length),
                  ),
                  const SizedBox(height: 14),
                  _TotalProgressCard(
                    plan: widget.plan,
                    days: days,
                    readChapters: readChapters,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StatistikaScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BooksInPlanNavCard(plan: widget.plan),
                  const SizedBox(height: 18),
                  _DailyReadingsCard(
                    day: selectedDay,
                    readChapters: readChapters,
                  ),
                ],
              ),
            ),
    );
  }

  int _effectiveSelectedIndex(List<PlanDay> days, DateTime today) {
    if (days.isEmpty) return 0;
    final existing = _selectedDayIndex;
    if (existing != null) return existing.clamp(0, days.length - 1);
    final todayIndex = days.indexWhere(
      (day) => _sameDate(day.scheduledDate, today),
    );
    if (todayIndex != -1) return todayIndex;
    final nextIndex = days.indexWhere(
      (day) => day.scheduledDate.isAfter(today),
    );
    return nextIndex == -1 ? days.length - 1 : nextIndex;
  }

  void _selectDay(int index, int totalDays) {
    if (index < 0 || index >= totalDays) return;
    setState(() => _selectedDayIndex = index);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planDeleteTitle),
        content: Text(l10n.planDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.planCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.planDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(planDaoProvider).deleteActivePlan();
    }
  }
}

class _BooksNavLeading extends StatelessWidget {
  const _BooksNavLeading();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('plan-books-nav-button'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BibliaScreen()),
      ),
      icon: const Icon(Icons.menu_book_outlined),
      color: _PlanColors.goldDark,
    );
  }
}

class _PlanAppBarTitle extends StatelessWidget {
  const _PlanAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Plán čítania Biblie',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _PlanColors.text,
      ),
    );
  }
}

class _TotalProgressCard extends StatelessWidget {
  final ReadingPlan plan;
  final List<PlanDay> days;
  final Set<ChapterRef> readChapters;
  final VoidCallback onTap;

  const _TotalProgressCard({
    required this.plan,
    required this.days,
    required this.readChapters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = _totalPlanChapters(days);
    final completed = _completedPlanChapters(days, readChapters);
    final totalBooks = plan.selectedBookIds.length;
    final completedBooks = _completedBooksCount(plan, days, readChapters);
    final percent = total == 0 ? 0.0 : completed / total;

    return GestureDetector(
      onTap: onTap,
      child: _PlanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.planTotalProgressTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _PlanColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(percent * 100).round()} %',
                  key: const Key('plan-total-progress-percent'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _PlanColors.goldDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: const Key('plan-total-progress-bar'),
                value: percent,
                minHeight: 9,
                backgroundColor: _PlanColors.goldSoft,
                valueColor: AlwaysStoppedAnimation(_PlanColors.gold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$completedBooks / $totalBooks ${l10n.planBooksUnit}',
                  key: const Key('plan-total-progress-books'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: _PlanColors.text),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('·', style: TextStyle(color: _PlanColors.textMuted)),
                ),
                Text(
                  '$completed / $total ${l10n.planChaptersCompletedLower}',
                  key: const Key('plan-total-progress-chapters'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: _PlanColors.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BooksInPlanNavCard extends StatelessWidget {
  final ReadingPlan plan;

  const _BooksInPlanNavCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      key: const Key('plan-books-in-plan-button'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BooksInPlanScreen(plan: plan),
        ),
      ),
      child: _PlanCard(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: _PlanColors.goldSoft,
              foregroundColor: _PlanColors.goldDark,
              child: Icon(Icons.library_books_outlined, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.planBooksInPlan,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _PlanColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _PlanColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _DayNavigationCard extends StatelessWidget {
  final PlanDay day;
  final int totalDays;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DayNavigationCard({
    required this.day,
    required this.totalDays,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _PlanCard(
      child: Row(
        children: [
          _RoundGoldIconButton(
            key: const Key('plan-previous-day-button'),
            icon: Icons.chevron_left,
            onPressed: canGoPrevious ? onPrevious : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${l10n.planDay} ${day.dayNumber} / $totalDays',
                  key: Key('plan-current-day-${day.dayNumber}'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _PlanColors.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(day.scheduledDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _PlanColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _RoundGoldIconButton(
            key: const Key('plan-next-day-button'),
            icon: Icons.chevron_right,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _DailyReadingsCard extends StatelessWidget {
  final PlanDay day;
  final Set<ChapterRef> readChapters;

  const _DailyReadingsCard({required this.day, required this.readChapters});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupChaptersByBook(day.chapters);
    final l10n = AppLocalizations.of(context)!;
    return _PlanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.planTodayReading,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _PlanColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final group in grouped) ...[
            Text(
              _bookChapterRangeLabel(group.book, group.chapters),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _PlanColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final chapter in group.chapters)
              _PlanChapterCheckboxTile(
                chapter: chapter,
                isRead: readChapters.contains(chapter),
              ),
            if (group != grouped.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class BooksInPlanScreen extends ConsumerWidget {
  final ReadingPlan plan;

  const BooksInPlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final days =
        ref.watch(planDaysProvider(plan.id)).value ?? const <PlanDay>[];
    final readChapters =
        ref.watch(readChaptersProvider).value ?? const <ChapterRef>{};
    final bookProgress = _bookProgressForPlan(plan, days, readChapters);

    final otBooks = bookProgress
        .where((bp) => bp.book.testament == Testament.oldTestament)
        .toList();
    final ntBooks = bookProgress
        .where((bp) => bp.book.testament == Testament.newTestament)
        .toList();

    return Scaffold(
      backgroundColor: _PlanColors.background,
      appBar: AppBar(title: Text(l10n.planBooksInPlan)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (otBooks.isNotEmpty) ...[
            const TestamentHeader(title: 'Starý zákon'),
            for (final progress in otBooks)
              _PlanBookProgressTile(progress: progress),
          ],
          if (ntBooks.isNotEmpty) ...[
            const TestamentHeader(title: 'Nový zákon'),
            for (final progress in ntBooks)
              _PlanBookProgressTile(progress: progress),
          ],
        ],
      ),
    );
  }
}

class _PlanBookProgressTile extends ConsumerWidget {
  final _BookProgress progress;

  const _PlanBookProgressTile({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = progress.completedChapters;
    final total = progress.chapters.length;
    final isComplete = total > 0 && completed == total;
    final percent = total == 0 ? 0.0 : completed / total;

    return Card(
      key: Key('plan-book-progress-${progress.book.id}'),
      elevation: 0,
      color: _PlanColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: BookIconBadge(abbreviation: progress.book.shortName, size: 40),
          title: Text(
            progress.book.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _PlanColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$completed/$total',
                  key: Key('plan-book-count-${progress.book.id}'),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: Key('plan-book-progress-bar-${progress.book.id}'),
                    value: percent,
                    minHeight: 7,
                    backgroundColor: _PlanColors.goldSoft,
                    valueColor: AlwaysStoppedAnimation(_PlanColors.gold),
                  ),
                ),
              ],
            ),
          ),
          trailing: Checkbox(
            key: Key('plan-book-complete-${progress.book.id}'),
            value: isComplete,
            activeColor: _PlanColors.goldDark,
            onChanged: (_) => _toggleBook(context, ref, isComplete),
          ),
          children: [
            for (final chapter in progress.chapters)
              _PlanChapterCheckboxTile(
                chapter: chapter,
                isRead: progress.readChapters.contains(chapter),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBook(
    BuildContext context,
    WidgetRef ref,
    bool isComplete,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(progressDaoProvider);
    if (isComplete) {
      for (final chapter in progress.chapters) {
        await dao.markUnread(chapter);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planCompleteBookTitle),
        content: Text('${l10n.planCompleteBookMessage} ${progress.book.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.planCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.planCompleteBookAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final now = DateTime.now();
    for (final chapter in progress.chapters) {
      await dao.markRead(chapter, now);
    }
  }
}

class _PlanChapterCheckboxTile extends ConsumerWidget {
  final ChapterRef chapter;
  final bool isRead;

  const _PlanChapterCheckboxTile({required this.chapter, required this.isRead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = _bookById(chapter.bookId);
    final label = '${book.name} ${chapter.chapterNumber}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              key: Key('plan-chapter-${chapter.bookId}-${chapter.chapterNumber}'),
              value: isRead,
              activeColor: _PlanColors.goldDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => _toggle(ref),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggle(ref),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                  color: isRead ? _PlanColors.textMuted : _PlanColors.textStrong,
                  decoration: isRead ? TextDecoration.lineThrough : null,
                  decorationColor: _PlanColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ),
          IconButton(
            key: Key(
              'plan-open-chapter-${chapter.bookId}-${chapter.chapterNumber}',
            ),
            tooltip: label,
            icon: const Icon(Icons.menu_book_outlined, size: 20),
            color: _PlanColors.goldDark,
            onPressed: () => _openReader(context),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref) async {
    final dao = ref.read(progressDaoProvider);
    if (isRead) {
      await dao.markUnread(chapter);
    } else {
      await dao.markRead(chapter, DateTime.now());
    }
  }

  void _openReader(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          bookId: chapter.bookId,
          chapterNumber: chapter.chapterNumber,
          canMarkRead: true,
        ),
      ),
    );
  }
}

class _RoundGoldIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundGoldIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: _PlanColors.goldSoft,
        foregroundColor: _PlanColors.goldDark,
        disabledBackgroundColor: _PlanColors.cardMuted,
        disabledForegroundColor: _PlanColors.textMuted.withValues(alpha: 0.45),
      ),
      icon: Icon(icon),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Widget child;

  const _PlanCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _PlanColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _PlanColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _BookSelectionGroup extends StatelessWidget {
  final _BookGroup group;
  final Set<String> selectedBookIds;
  final void Function(String bookId, bool selected) onChanged;

  const _BookSelectionGroup({
    required this.group,
    required this.selectedBookIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: _PlanColors.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _PlanColors.cardBorder),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: Key('plan-book-group-${group.category.name}'),
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
            title: Text(
              group.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _PlanColors.text,
              ),
            ),
            children: [
              const Divider(height: 1, thickness: 1, color: _PlanColors.cardBorder),
              for (final book in group.books)
                _BookCheckboxRow(
                  key: Key('plan-book-${book.id}'),
                  book: book,
                  selected: selectedBookIds.contains(book.id),
                  onChanged: (v) => onChanged(book.id, v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _PlanColors.text,
            ),
          ),
        ),
        Text(
          value,
          key: Key('plan-preview-$label'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _PlanColors.textStrong,
          ),
        ),
      ],
    );
  }
}

class _BookCheckboxRow extends StatelessWidget {
  final BibleBook book;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _BookCheckboxRow({
    super.key,
    required this.book,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            BookIconBadge(abbreviation: book.shortName, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? _PlanColors.textStrong
                          : _PlanColors.textMuted,
                    ),
                  ),
                  Text(
                    '+${formatChapterCount(book.chapterCount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _PlanColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: _PlanColors.goldDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookChapterGroup {
  final BibleBook book;
  final List<ChapterRef> chapters;

  const _BookChapterGroup({required this.book, required this.chapters});
}

class _BookProgress {
  final BibleBook book;
  final List<ChapterRef> chapters;
  final Set<ChapterRef> readChapters;

  const _BookProgress({
    required this.book,
    required this.chapters,
    required this.readChapters,
  });

  int get completedChapters =>
      chapters.where((chapter) => readChapters.contains(chapter)).length;
}

class _BookGroup {
  final CatholicCategory category;
  final String title;

  const _BookGroup(this.category, this.title);

  List<BibleBook> get books =>
      kBibleBooks.where((book) => book.category == category).toList();
}

const _otBookGroups = [
  _BookGroup(CatholicCategory.pentateuch, 'Pentateuch'),
  _BookGroup(CatholicCategory.historicalBooks, 'Historické knihy'),
  _BookGroup(CatholicCategory.wisdomBooks, 'Múdroslovné knihy'),
  _BookGroup(CatholicCategory.propheticBooks, 'Prorocké knihy'),
];

const _ntBookGroups = [
  _BookGroup(CatholicCategory.gospels, 'Evanjeliá'),
  _BookGroup(CatholicCategory.acts, 'Skutky apoštolov'),
  _BookGroup(CatholicCategory.paulineLetters, 'Pavlove listy'),
  _BookGroup(CatholicCategory.catholicLetters, 'Katolícke listy'),
  _BookGroup(CatholicCategory.revelation, 'Zjavenie'),
];

BibleBook _bookById(String bookId) {
  return kBibleBooks.firstWhere((book) => book.id == bookId);
}

String _formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _completedCount(List<ChapterRef> chapters, Set<ChapterRef> readChapters) {
  return chapters.where((chapter) => readChapters.contains(chapter)).length;
}

int _totalPlanChapters(List<PlanDay> days) {
  return days.fold(0, (sum, day) => sum + day.chapters.length);
}

int _completedPlanChapters(List<PlanDay> days, Set<ChapterRef> readChapters) {
  return days.fold(
    0,
    (sum, day) => sum + _completedCount(day.chapters, readChapters),
  );
}

int _completedBooksCount(
  ReadingPlan plan,
  List<PlanDay> days,
  Set<ChapterRef> readChapters,
) {
  return _bookProgressForPlan(plan, days, readChapters)
      .where(
        (bp) => bp.chapters.isNotEmpty && bp.completedChapters == bp.chapters.length,
      )
      .length;
}

List<_BookChapterGroup> _groupChaptersByBook(List<ChapterRef> chapters) {
  final groups = <_BookChapterGroup>[];
  for (final chapter in chapters) {
    if (groups.isNotEmpty && groups.last.book.id == chapter.bookId) {
      groups.last.chapters.add(chapter);
    } else {
      groups.add(
        _BookChapterGroup(book: _bookById(chapter.bookId), chapters: [chapter]),
      );
    }
  }
  return groups;
}

String _bookChapterRangeLabel(BibleBook book, List<ChapterRef> chapters) {
  if (chapters.length == 1) {
    return '${book.name} ${chapters.single.chapterNumber}';
  }
  return '${book.name} ${chapters.first.chapterNumber}–${chapters.last.chapterNumber}';
}

List<_BookProgress> _bookProgressForPlan(
  ReadingPlan plan,
  List<PlanDay> days,
  Set<ChapterRef> readChapters,
) {
  final chaptersByBook = <String, List<ChapterRef>>{};
  for (final day in days) {
    for (final chapter in day.chapters) {
      chaptersByBook.putIfAbsent(chapter.bookId, () => []).add(chapter);
    }
  }
  return [
    for (final bookId in plan.selectedBookIds)
      if (chaptersByBook.containsKey(bookId))
        _BookProgress(
          book: _bookById(bookId),
          chapters: chaptersByBook[bookId]!,
          readChapters: readChapters,
        ),
  ];
}

class _PlanColors {
  static const background = Color(0xFFFFFCF7);
  static const card = Colors.white;
  static const cardMuted = Color(0xFFF3EEE6);
  static const cardBorder = Color(0xFFF0E3CC);
  static const gold = Color(0xFFD6A645);
  static const goldDark = Color(0xFF9B6A10);
  static const goldSoft = Color(0xFFF7E8C3);
  static const text = Color(0xFF2B2418);
  static const textStrong = Color(0xFF1A110A);
  static const textMuted = Color(0xFF5A5047);
}
