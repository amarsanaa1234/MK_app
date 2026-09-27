import 'package:flutter/material.dart';
import 'package:mk_app/screens/employeeScreen/employee_home_feed.dart';
import 'package:mk_app/screens/employeeScreen/my_roster_page.dart';
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
import 'package:mk_app/utils/workspace_prefs.dart';

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

  /// The session the app is running on. It only changes when an admin who runs several
  /// workspaces opens a different one (see [_sessionChanged]).
  late AuthResult _session = widget.session;

  void _select(AppSection section) => setState(() => _section = section);

  /// A different workspace was opened: every screen below is rebuilt against the new session.
  void _sessionChanged(AuthResult session) {
    if (session.organizationId == _session.organizationId) return;
    setState(() => _session = session);
    WorkspacePrefs.markChosen(session.userId);
  }

  bool get _isAdmin => _session.userType == 'Admin';

  Widget _body() => switch (_section) {
    AppSection.dashboard => _isAdmin
        ? OrgHomePage(session: _session)
        : EmployeeHomeFeed(session: _session),
    AppSection.profile => UserProfilePage(
      session: _session,
      onSessionChanged: _sessionChanged,
      onOpenSection: _select,
    ),
    AppSection.organizationProfile => OrgProfile(session: _session),
    AppSection.payRates => PayRatesPage(session: _session),
    AppSection.planBilling => PlanBillingPage(session: _session),
    AppSection.payroll => PayrollCalculatorPage(session: _session),
    AppSection.timesheets => TimesheetsPage(session: _session),
    AppSection.myTimesheet => MyTimesheetPage(session: _session),
    // "My roster" is a crew screen — admins schedule the jobs, they don't work a roster.
    AppSection.myRoster => _isAdmin ? OrgHomePage(session: _session) : MyRosterPage(session: _session),
    AppSection.gettingStarted => const _ComingSoon(title: 'Getting Started'),
    AppSection.employees => EmployeesPage(session: _session),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(session: _session, onSelectSection: _select, onSessionChanged: _sessionChanged),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  // Keyed by workspace so every screen refetches its data after a switch.
                  child: KeyedSubtree(key: ValueKey(_session.organizationId), child: _body()),
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
