class ReadingPlan {
  final String id;

  /// Normalized to date-only (no time component).
  final DateTime startDate;

  final int totalDays;

  /// Immutable ordered list of book IDs included in this plan.
  /// Order matches the canonical SSV ordering of the selected books.
  final List<String> selectedBookIds;

  final DateTime createdAt;

  ReadingPlan({
    required this.id,
    required DateTime startDate,
    required this.totalDays,
    required List<String> selectedBookIds,
    required this.createdAt,
  })  : startDate = DateTime(startDate.year, startDate.month, startDate.day),
        selectedBookIds = List.unmodifiable(selectedBookIds);

  @override
  String toString() =>
      'ReadingPlan(id: $id, startDate: $startDate, totalDays: $totalDays, '
      'books: ${selectedBookIds.length})';
}
