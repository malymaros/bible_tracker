/// Returns the Slovak plural form of "verš" for the given [count]
/// (1 verš, 2–4 verše, 0 and 5+ veršov).
String formatVerseCount(int count) {
  if (count == 1) return '$count verš';
  if (count >= 2 && count <= 4) return '$count verše';
  return '$count veršov';
}

/// Short form for tight places such as the chapter grid ("31 v.").
String formatVerseCountShort(int count) => '$count v.';
