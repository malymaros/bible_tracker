class PlanProgress {
  final String planId;
  final int totalPlanChapters;
  final int completedPlanChapters;
  final int expectedChaptersByToday;

  /// completedPlanChapters − expectedChaptersByToday.
  /// Positive = ahead, negative = behind, zero = on track.
  final int aheadBehindChapterCount;

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
    required this.completionPercent,
  })  : isAhead = aheadBehindChapterCount > 0,
        isBehind = aheadBehindChapterCount < 0,
        isOnTrack = aheadBehindChapterCount == 0;

  @override
  String toString() =>
      'PlanProgress($planId, $completedPlanChapters/$totalPlanChapters, '
      'delta: $aheadBehindChapterCount)';
}
