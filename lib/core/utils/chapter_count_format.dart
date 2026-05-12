/// Returns the Slovak plural form of "kapitola" for the given [count].

String formatChapterCount(int count) {
  if (count == 1) return '$count kapitola';
  if (count == 2) return '$count kapitoly';
  if (count == 3) return '$count kapitoly';
  if (count == 4) return '$count kapitoly';
  return '$count kapitol';
}
