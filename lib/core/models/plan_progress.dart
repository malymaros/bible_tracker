class PlanProgress {
  final String planId;
  final int totalPlanChapters;
  final int completedPlanChapters;

  /// Chapters scheduled on days up to and including today. Reported as a
  /// standalone statistic; the ahead/behind figures below no longer derive
  /// from it.
  final int expectedChaptersByToday;

  /// Chapter-level counterpart of [approximateDaysDelta], always carrying the
  /// same sign so the two never contradict each other.
  ///
  /// Behind: negative, the unread chapters left in past days.
  /// Otherwise: positive, the chapters already read beyond today — the whole
  /// days in [approximateDaysDelta] plus any partial progress into the day
  /// that follows them.
  final int aheadBehindChapterCount;

  /// Schedule drift in whole days.
  ///
  /// Negative = past days still holding unread chapters. Positive = days
  /// after today that are fully read, counted as an unbroken run. Zero = on
  /// track, which includes the ordinary state of today's reading not being
  /// done yet.
  ///
  /// Counted directly off the schedule, never converted from a chapter
  /// average: days hold wildly different chapter counts because the plan is
  /// balanced by verses, so an average day does not exist.
  final int approximateDaysDelta;

  final double completionPercent;

  final bool isAhead;
  final bool isBehind;
  final bool isOnTrack;

  const PlanProgress({
    required this.planId,
    required this.totalPlanChapters,
    required this.completedPlanChapters,
    required this.expectedChaptersByToday,
    required this.aheadBehindChapterCount,
    required this.approximateDaysDelta,
    required this.completionPercent,
  })  : isAhead = approximateDaysDelta > 0,
        isBehind = approximateDaysDelta < 0,
        isOnTrack = approximateDaysDelta == 0;

  @override
  String toString() =>
      'PlanProgress($planId, $completedPlanChapters/$totalPlanChapters, '
      'delta: $approximateDaysDelta d / $aheadBehindChapterCount ch)';
}
