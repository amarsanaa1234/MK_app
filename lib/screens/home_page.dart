import 'package:flutter/material.dart';
import 'package:mk_app/screens/header/header.dart';
import 'package:mk_app/screens/orgScreen/org_home_page/org_home_page.dart';
import 'package:mk_app/screens/orgScreen/org_profile/org_profile.dart';

import '../api/api_client.dart';

/// The sections reachable from the sidebar. Adding a new sidebar destination
/// means adding a case here and a matching branch in [_HomePageState._body].
enum AppSection {
  dashboard,
  profile,
  organizations,
  myRoster,
  payRates,
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

  Widget _body() => switch (_section) {
    AppSection.dashboard => OrgHomePage(session: widget.session),
    AppSection.profile => OrgProfile(session: widget.session),
    AppSection.organizations => const _ComingSoon(title: 'Organizations'),
    AppSection.myRoster => const _ComingSoon(title: 'My roster'),
    AppSection.payRates => const _ComingSoon(title: 'Pay rates'),
    AppSection.gettingStarted => const _ComingSoon(title: 'Getting Started'),
    AppSection.employees => const _ComingSoon(title: 'Employees'),
    AppSection.payroll => const _ComingSoon(title: 'Payroll'),
    AppSection.timesheets => const _ComingSoon(title: 'Timesheets'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header is built once here and never rebuilt when the section
            // changes below — only the body swaps.
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
