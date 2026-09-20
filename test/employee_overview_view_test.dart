import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/theme/theme.dart';
import 'package:mk_app/widgets/employee_overview_view.dart';

EmployeeOverview _overview() {
  final start = DateTime(2026, 9, 7);
  return EmployeeOverview(
    id: 'e1',
    fullName: 'amarsanaa',
    role: 'Crew',
    email: 'test1@gmail.com',
    phone: '042160265',
    payRate: 51,
    totalHours: 56,
    missingLogs: 1,
    owed: 2856,
    employeeCode: 'MK-0002',
    days: [
      for (var i = 0; i < 14; i++)
        TimesheetDay(
          date: start.add(Duration(days: i)),
          status: i == 9 ? 'MISSING' : (i % 3 == 0 ? 'WORKED' : 'OFF'),
          hoursWorked: i == 9 || i % 3 != 0 ? null : 8,
        ),
    ],
    shifts: [
      Shift(date: DateTime(2026, 9, 7), jobAdId: 'j1', addressLine: '5 Pittwater Rd', hoursWorked: 6.5, status: 'WORKED', jobType: 'Office', lead: true),
      Shift(date: DateTime(2026, 9, 16), jobAdId: 'j2', addressLine: '9 Bronte Rd', status: 'MISSING'),
    ],
  );
}

Future<void> _pump(WidgetTester tester, {ValueChanged<Shift>? onFixLog}) {
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(data: darkTheme, child: child!),
      home: Scaffold(
        body: EmployeeOverviewView(
          employee: _overview(),
          periodLabel: '7 Sep – 20 Sep',
          onFixLog: onFixLog,
          footer: const [Text('FOOTER')],
        ),
      ),
    ),
  );
}

void main() {
  periodArrowTests();
  testWidgets('own profile shows hours, pay, subtitle and code but no admin-only fix links', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester);

    expect(find.text('amarsanaa'), findsOneWidget);
    expect(find.text('Crew · Office lead'), findsOneWidget);
    expect(find.text('MK-0002'), findsOneWidget);
    expect(find.text('56.0h'), findsOneWidget);
    expect(find.text(r'$2,856'), findsOneWidget);
    expect(find.textContaining('7 SEP – 20 SEP'), findsOneWidget);
    expect(find.text('FOOTER'), findsOneWidget);

    expect(find.text('Fix log'), findsNothing);
    expect(find.textContaining('Tap a red day'), findsNothing);
    expect(find.text('Wed 16 Sep · no hours logged'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin view offers Fix log on missing shifts', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Shift? tapped;
    await _pump(tester, onFixLog: (s) => tapped = s);

    expect(find.textContaining('Tap a red day'), findsOneWidget);
    await tester.tap(find.text('Fix log'));
    expect(tapped?.jobAdId, 'j2');
    expect(tester.takeException(), isNull);
  });
}

void _bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpWithArrows(WidgetTester tester, {VoidCallback? previous, VoidCallback? next}) {
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(data: darkTheme, child: child!),
      home: Scaffold(
        body: EmployeeOverviewView(
          employee: _overview(),
          periodLabel: '7 Sep – 20 Sep',
          onPreviousPeriod: previous,
          onNextPeriod: next,
        ),
      ),
    ),
  );
}

void periodArrowTests() {
  testWidgets('period arrows step back, and forward only when there is a later period', (tester) async {
    _bigView(tester);
    var back = 0;
    await _pumpWithArrows(tester, previous: () => back++, next: null);

    await tester.tap(find.byIcon(Icons.chevron_left));
    expect(back, 1);

    // On the current period the forward arrow is disabled: tapping does nothing.
    final forward = tester.widget<InkWell>(find.ancestor(of: find.byIcon(Icons.chevron_right), matching: find.byType(InkWell)).first);
    expect(forward.onTap, isNull);

    var next = 0;
    await _pumpWithArrows(tester, previous: () {}, next: () => next++);
    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(next, 1);
    expect(tester.takeException(), isNull);
  });
}
