import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, String abbreviation) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: BookIconBadge(abbreviation: abbreviation)),
        ),
      ),
    );
  }

  testWidgets('BookIconBadge fits short abbreviations without overflow', (
    tester,
  ) async {
    await pumpBadge(tester, 'Gn');

    expect(find.text('Gn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BookIconBadge scales long abbreviations without overflow', (
    tester,
  ) async {
    await pumpBadge(tester, '1 Sol');

    expect(find.text('1 Sol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BookIconBadge keeps consistent circle size', (tester) async {
    await pumpBadge(tester, 'Zjv');

    final size = tester.getSize(find.byType(BookIconBadge));
    expect(size.width, 40);
    expect(size.height, 40);
  });
}
