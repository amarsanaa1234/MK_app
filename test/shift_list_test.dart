import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/employee_overview_view.dart';
import 'package:mk_app/theme/theme.dart';

List<Shift> _shifts(int count) => [
  for (var i = 0; i < count; i++)
    Shift(
      date: DateTime(2026, 9, 1).add(Duration(days: i)),
      jobAdId: 'job-$i',
      addressLine: 'Address number $i',
      hoursWorked: i == 3 ? null : 8.0,
      status: i == 3 ? 'MISSING' : 'WORKED',
    ),
];

Future<void> _pump(WidgetTester tester, List<Shift> shifts, {void Function(Shift)? onFixLog}) {
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(data: darkTheme, child: child!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ShiftList(shifts: shifts, onFixLog: onFixLog),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a long list stays five rows tall and scrolls to the last shift', (tester) async {
    await _pump(tester, _shifts(20));

    expect(tester.getSize(find.byType(ShiftList)).height, 5 * 46.0);
    expect(find.textContaining('Address number 19'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.textContaining('Address number 19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short list only takes the room it needs', (tester) async {
    await _pump(tester, _shifts(2));
    expect(tester.getSize(find.byType(ShiftList)).height, 2 * 46.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing shift offers Fix log', (tester) async {
    Shift? tapped;
    await _pump(tester, _shifts(5), onFixLog: (s) => tapped = s);

    await tester.tap(find.text('Fix log'));
    expect(tapped?.jobAdId, 'job-3');
  });
}
