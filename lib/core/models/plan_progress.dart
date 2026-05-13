class PlanProgress {
  final String planId;
  final int totalPlanChapters;
  final int completedPlanChapters;
  final int expectedChaptersByToday;

  /// completedPlanChapters − expectedChaptersByToday.
  /// Positive = ahead, negative = behind, zero = on track.
  final int aheadBehindChapterCount;

  /// Chapter delta expressed as approximate days using the plan's average
  /// chapters-per-day. Rounded to nearest integer; non-zero delta is clamped
  /// to a minimum of ±1 so a tiny delta never shows as 0 days.
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
  })  : isAhead = aheadBehindChapterCount > 0,
        isBehind = aheadBehindChapterCount < 0,
        isOnTrack = aheadBehindChapterCount == 0;

  @override
  String toString() =>
      'PlanProgress($planId, $completedPlanChapters/$totalPlanChapters, '
      'delta: $aheadBehindChapterCount)';
}
