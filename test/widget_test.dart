// Keep the Material import compatible with earlier Flutter SDKs.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab11/main.dart' as vault;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loads and updates saved vault state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await vault.main();
    await tester.pumpAndSettle();
    expect(find.text('Hello, Guest User'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    for (final title in ['First note', 'Second note']) {
      await tester.enterText(find.byType(TextField).last, title);
      await tester.tap(find.text('Add note'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await vault.main();
    await tester.pumpAndSettle();
    expect(find.text('Hello, Alex'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('First note'), findsOneWidget);
    expect(find.text('Second note'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);

    await tester.tap(find.byTooltip('Delete note').first);
    await tester.pumpAndSettle();
    expect(find.text('Second note'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(vault.notesKey), isNot(contains('Second note')));
  });
}
