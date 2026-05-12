/// Returns the Slovak plural form of "kapitola" for the given [count].
///
/// Slovak plural rules:
///   1           → kapitola
///   2–4         → kapitoly
///   11–14       → kapitol  (override: always genitive plural)
///   22–24, etc. → kapitoly (mod10 in 2–4, mod100 not in 11–14)
///   everything else → kapitol
String formatChapterCount(int count) {
  if (count == 1) return '$count kapitola';
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 11 || mod100 > 14)) {
    return '$count kapitoly';
  }
  return '$count kapitol';
}
