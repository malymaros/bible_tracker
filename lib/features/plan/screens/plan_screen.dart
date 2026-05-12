import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_generator.dart';
import 'package:bible_tracker/core/services/plan_progress_calculator.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final activePlanProvider = StreamProvider<ReadingPlan?>((ref) {
  return ref.watch(planDaoProvider).watchActivePlan();
});

final planDaysProvider = StreamProvider.family<List<PlanDay>, String>((
  ref,
  planId,
) {
  return ref.watch(planDaoProvider).watchPlanDays(planId);
});

final readChaptersProvider = StreamProvider<Set<ChapterRef>>((ref) {
  return ref.watch(progressDaoProvider).watchAllReadChapters();
});

final todayProvider = Provider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activePlan = ref.watch(activePlanProvider);

    return activePlan.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.screenPlan)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.screenPlan)),
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
      appBar: AppBar(title: Text(l10n.screenPlan)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.planCreateTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('plan-start-date-button'),
              onPressed: _pickStartDate,
              icon: const Icon(Icons.calendar_today),
              label: Text('${l10n.planStartDate}: ${_formatDate(_startDate)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('plan-total-days-field'),
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.planTotalDays,
                border: const OutlineInputBorder(),
                errorText: validation,
              ),
            ),
            const SizedBox(height: 16),
            _PreviewLine(
              label: l10n.planSelectedChapters,
              value: '$selectedChapters',
            ),
            _PreviewLine(
              label: l10n.planDateRange,
              value: endDate == null
                  ? l10n.planDateRangeUnavailable
                  : '${_formatDate(_startDate)} - ${_formatDate(endDate)}',
            ),
            const SizedBox(height: 16),
            Text(
              l10n.planIncludedBooks,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final group in _bookGroups)
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
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('plan-create-button'),
              onPressed: validation == null && selectedBooks.isNotEmpty
                  ? () => _createPlan(selectedBooks, totalDays!)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.planCreateAction),
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

class _ExistingPlanScreen extends ConsumerWidget {
  final ReadingPlan plan;

  const _ExistingPlanScreen({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final days =
        ref.watch(planDaysProvider(plan.id)).value ?? const <PlanDay>[];
    final readChapters =
        ref.watch(readChaptersProvider).value ?? const <ChapterRef>{};
    final today = ref.watch(todayProvider);
    final progress = PlanProgressCalculator.calculate(
      plan: plan,
      days: days,
      readChapters: readChapters,
      today: today,
    );
    final todayDay = days.where((day) => _sameDate(day.scheduledDate, today));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenPlan),
        actions: [
          IconButton(
            tooltip: l10n.planDeleteAction,
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PlanProgressPanel(progress: progress),
          const SizedBox(height: 12),
          Text(
            l10n.planTodayReading,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (todayDay.isEmpty)
            Text(l10n.planNoReadingToday)
          else
            for (final day in todayDay)
              _PlanDayCard(day: day, today: today, readChapters: readChapters),
          const SizedBox(height: 18),
          Text(
            l10n.planSchedule,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final day in days)
            _PlanDayCard(day: day, today: today, readChapters: readChapters),
        ],
      ),
    );
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

class _PlanProgressPanel extends StatelessWidget {
  final PlanProgress progress;

  const _PlanProgressPanel({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = progress.isAhead
        ? l10n.planAhead
        : progress.isBehind
        ? l10n.planBehind
        : l10n.planOnTrack;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.totalPlanChapters == 0
                  ? 0
                  : progress.completedPlanChapters / progress.totalPlanChapters,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.planCompletedChapters}: '
              '${progress.completedPlanChapters}/${progress.totalPlanChapters}',
            ),
            Text(
              '${l10n.planExpectedByToday}: '
              '${progress.expectedChaptersByToday}',
            ),
            Text(
              '${l10n.planAheadBehind}: '
              '${progress.aheadBehindChapterCount}',
            ),
            Text(
              '${l10n.planCompletionPercent}: '
              '${progress.completionPercent.toStringAsFixed(1)} %',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanDayCard extends ConsumerWidget {
  final PlanDay day;
  final DateTime today;
  final Set<ChapterRef> readChapters;

  const _PlanDayCard({
    required this.day,
    required this.today,
    required this.readChapters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isToday = _sameDate(day.scheduledDate, today);

    return Card(
      key: Key('plan-day-${day.dayNumber}'),
      color: isToday ? Theme.of(context).colorScheme.primaryContainer : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.planDay} ${day.dayNumber} - ${_formatDate(day.scheduledDate)}'
              '${isToday ? ' (${l10n.planToday})' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final chapter in day.chapters)
              _PlanChapterTile(
                chapter: chapter,
                isRead: readChapters.contains(chapter),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanChapterTile extends ConsumerWidget {
  final ChapterRef chapter;
  final bool isRead;

  const _PlanChapterTile({required this.chapter, required this.isRead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final book = _bookById(chapter.bookId);
    final label = '${book.shortName} ${chapter.chapterNumber}';

    return ListTile(
      key: Key('plan-chapter-${chapter.bookId}-${chapter.chapterNumber}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(isRead ? Icons.check_circle : Icons.radio_button_unchecked),
      title: Text(label),
      subtitle: Text(
        isRead ? l10n.planChapterCompleted : l10n.planChapterIncomplete,
      ),
      onTap: () => context.push(
        '/biblia/reader/${chapter.bookId}/${chapter.chapterNumber}',
      ),
      trailing: IconButton(
        tooltip: isRead ? l10n.readerMarkUnread : l10n.readerMarkRead,
        icon: Icon(isRead ? Icons.undo : Icons.check),
        onPressed: () async {
          final dao = ref.read(progressDaoProvider);
          if (isRead) {
            await dao.markUnread(chapter);
          } else {
            await dao.markRead(chapter, DateTime.now());
          }
        },
      ),
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
    return ExpansionTile(
      key: Key('plan-book-group-${group.category.name}'),
      initiallyExpanded: group.category == CatholicCategory.pentateuch,
      title: Text(group.title),
      children: [
        for (final book in group.books)
          CheckboxListTile(
            key: Key('plan-book-${book.id}'),
            value: selectedBookIds.contains(book.id),
            onChanged: (selected) => onChanged(book.id, selected ?? false),
            title: Text(book.name),
            subtitle: Text('${book.chapterCount}'),
          ),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, key: Key('plan-preview-$label')),
        ],
      ),
    );
  }
}

class _BookGroup {
  final CatholicCategory category;
  final String title;

  const _BookGroup(this.category, this.title);

  List<BibleBook> get books =>
      kBibleBooks.where((book) => book.category == category).toList();
}

const _bookGroups = [
  _BookGroup(CatholicCategory.pentateuch, 'Pentateuch'),
  _BookGroup(CatholicCategory.historicalBooks, 'Historické knihy'),
  _BookGroup(CatholicCategory.wisdomBooks, 'Múdroslovné knihy'),
  _BookGroup(CatholicCategory.propheticBooks, 'Prorocké knihy'),
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
