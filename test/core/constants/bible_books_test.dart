import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kBibleBooks', () {
    test('contains exactly 73 books', () {
      expect(kBibleBooks.length, 73);
    });

    test('orders are exactly 1–73 with no gaps and no duplicates', () {
      final orders = kBibleBooks.map((b) => b.order).toList()..sort();
      expect(orders, List.generate(73, (i) => i + 1));
    });

    test('all book ids are unique', () {
      final ids = kBibleBooks.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate id found: ${_findDuplicates(ids)}');
    });

    test('all SSV slugs are unique', () {
      final slugs = kBibleBooks.map((b) => b.ssvSlug).toList();
      expect(slugs.toSet().length, slugs.length,
          reason: 'Duplicate ssvSlug found: ${_findDuplicates(slugs)}');
    });

    test('total chapter count is 1334', () {
      final total = kBibleBooks.fold<int>(0, (sum, b) => sum + b.chapterCount);
      expect(total, 1334);
    });

    test('exactly 7 deuterocanonical books', () {
      final deutero = kBibleBooks.where((b) => b.isDeuterocanonical).toList();
      expect(deutero.length, 7,
          reason:
              'Expected 7 deuterocanonical books (Tobit, Judith, 1 Maccabees, '
              '2 Maccabees, Wisdom, Sirach, Baruch). '
              'Found: ${deutero.map((b) => b.id).join(', ')}');
    });

    test('deuterocanonical books are the correct seven', () {
      final deuteroIds =
          kBibleBooks.where((b) => b.isDeuterocanonical).map((b) => b.id).toSet();
      expect(
        deuteroIds,
        {'tob', 'jdt', '1macc', '2macc', 'wis', 'sir', 'bar'},
      );
    });

    test('Esther has 16 chapters (Catholic canon with deuterocanonical additions)', () {
      final esther = kBibleBooks.firstWhere((b) => b.id == 'esth');
      expect(esther.chapterCount, 16);
    });

    test('Daniel has 14 chapters (Catholic canon with deuterocanonical additions)', () {
      final daniel = kBibleBooks.firstWhere((b) => b.id == 'dan');
      expect(daniel.chapterCount, 14);
    });

    test('Joel has 4 chapters (Catholic/Vulgate tradition)', () {
      final joel = kBibleBooks.firstWhere((b) => b.id == 'joel');
      expect(joel.chapterCount, 4);
    });

    test('Old Testament has 46 books', () {
      final ot = kBibleBooks.where((b) => b.testament == Testament.oldTestament);
      expect(ot.length, 46);
    });

    test('New Testament has 27 books', () {
      final nt = kBibleBooks.where((b) => b.testament == Testament.newTestament);
      expect(nt.length, 27);
    });

    test('1 and 2 Maccabees are categorised as historicalBooks', () {
      final macc1 = kBibleBooks.firstWhere((b) => b.id == '1macc');
      final macc2 = kBibleBooks.firstWhere((b) => b.id == '2macc');
      expect(macc1.category, CatholicCategory.historicalBooks);
      expect(macc2.category, CatholicCategory.historicalBooks);
    });

    test('1 and 2 Maccabees have orders 45 and 46 (end of OT, SSV ordering)', () {
      final macc1 = kBibleBooks.firstWhere((b) => b.id == '1macc');
      final macc2 = kBibleBooks.firstWhere((b) => b.id == '2macc');
      expect(macc1.order, 45);
      expect(macc2.order, 46);
    });

    test('no book has an empty id, name, shortName, or ssvSlug', () {
      for (final book in kBibleBooks) {
        expect(book.id.isNotEmpty, isTrue, reason: 'order ${book.order}: empty id');
        expect(book.name.isNotEmpty, isTrue, reason: '${book.id}: empty name');
        expect(book.shortName.isNotEmpty, isTrue, reason: '${book.id}: empty shortName');
        expect(book.ssvSlug.isNotEmpty, isTrue, reason: '${book.id}: empty ssvSlug');
      }
    });

    test('all chapter counts are positive', () {
      for (final book in kBibleBooks) {
        expect(book.chapterCount, greaterThan(0),
            reason: '${book.id} has chapterCount ${book.chapterCount}');
      }
    });

    test('list is sorted by order', () {
      for (int i = 1; i < kBibleBooks.length; i++) {
        expect(
          kBibleBooks[i].order,
          kBibleBooks[i - 1].order + 1,
          reason:
              'List is not sorted: ${kBibleBooks[i - 1].id}(${kBibleBooks[i - 1].order}) '
              'followed by ${kBibleBooks[i].id}(${kBibleBooks[i].order})',
        );
      }
    });
  });
}

List<T> _findDuplicates<T>(List<T> items) {
  final seen = <T>{};
  return items.where((item) => !seen.add(item)).toList();
}
