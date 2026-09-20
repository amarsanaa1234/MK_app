import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/theme/theme.dart';
import 'package:mk_app/widgets/pay_rate_dialog.dart';

/// Opens the dialog from a button and records what it resolved to.
Future<void> _pumpHost(WidgetTester tester, void Function(double?) onResult) {
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(data: darkTheme, child: child!),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onResult(
              await showPayRateDialog(context: context, name: 'amarsanaa', currentRate: 51),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Regression: disposing the text controller from the caller as soon as the dialog
  // closed crashed the app ("_dependents.isEmpty" assertion) while it animated away.
  testWidgets('saving a new rate returns it and closes cleanly', (tester) async {
    double? result;
    var resolved = false;
    await _pumpHost(tester, (value) {
      result = value;
      resolved = true;
    });

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('amarsanaa · pay rate'), findsOneWidget);
    expect(find.text('51.00'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '62.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, 62.5);
    expect(find.text('amarsanaa · pay rate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling returns null and closes cleanly', (tester) async {
    double? result = -1;
    await _pumpHost(tester, (value) => result = value);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('amarsanaa · pay rate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can be opened and saved repeatedly', (tester) async {
    final results = <double?>[];
    await _pumpHost(tester, results.add);

    for (final rate in ['40', '45']) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), rate);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    expect(results, [40.0, 45.0]);
    expect(tester.takeException(), isNull);
  });
}
