import 'package:flutter/material.dart';
import 'package:mk_app/screens/employeeScreen/employee_home_feed.dart';
import 'package:mk_app/screens/employeeScreen/my_timesheet_page.dart';
import 'package:mk_app/screens/header/header.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_billing_page.dart';
import 'package:mk_app/screens/orgScreen/employees/employees_page.dart';
import 'package:mk_app/screens/orgScreen/org_home_page/org_home_page.dart';
import 'package:mk_app/screens/orgScreen/org_profile/org_profile.dart';
import 'package:mk_app/screens/orgScreen/payroll/pay_rates_page.dart';
import 'package:mk_app/screens/orgScreen/payroll/payroll_calculator_page.dart';
import 'package:mk_app/screens/orgScreen/payroll/timesheets_page.dart';
import 'package:mk_app/screens/profile/user_profile_page.dart';

import '../api/api_client.dart';

enum AppSection {
  dashboard,
  profile,
  organizationProfile,
  myRoster,
  myTimesheet,
  payRates,
  planBilling,
  gettingStarted,
  employees,
  payroll,
  timesheets,
}

class HomePage extends StatefulWidget {
  final AuthResult session;

  const HomePage({super.key, required this.session});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppSection _section = AppSection.dashboard;

  void _select(AppSection section) => setState(() => _section = section);

  bool get _isAdmin => widget.session.userType == 'Admin';

  Widget _body() => switch (_section) {
    AppSection.dashboard => _isAdmin
        ? OrgHomePage(session: widget.session)
        : EmployeeHomeFeed(session: widget.session),
    AppSection.profile => UserProfilePage(session: widget.session),
    AppSection.organizationProfile => OrgProfile(session: widget.session),
    AppSection.payRates => PayRatesPage(session: widget.session),
    AppSection.planBilling => PlanBillingPage(session: widget.session),
    AppSection.payroll => PayrollCalculatorPage(session: widget.session),
    AppSection.timesheets => TimesheetsPage(session: widget.session),
    AppSection.myTimesheet => MyTimesheetPage(session: widget.session),
    AppSection.myRoster => const _ComingSoon(title: 'My roster'),
    AppSection.gettingStarted => const _ComingSoon(title: 'Getting Started'),
    AppSection.employees => EmployeesPage(session: widget.session),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(session: widget.session, onSelectSection: _select),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: _body(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon({required this.title});

  @override
  Widget build(BuildContext context) => Center(
    child: Text('$title — coming soon', style: Theme.of(context).textTheme.bodyMedium),
  );
}
