import 'package:bible_tracker/core/utils/verse_count_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Slovak plural forms of verš', () {
    expect(formatVerseCount(1), '1 verš');
    expect(formatVerseCount(2), '2 verše');
    expect(formatVerseCount(4), '4 verše');
    expect(formatVerseCount(5), '5 veršov');
    expect(formatVerseCount(21), '21 veršov');
    expect(formatVerseCount(0), '0 veršov');
  });

  test('short form', () {
    expect(formatVerseCountShort(31), '31 v.');
  });
}
