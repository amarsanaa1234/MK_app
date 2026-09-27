import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/home_page.dart';
import 'package:mk_app/screens/landing_page.dart';
import 'package:mk_app/screens/orgScreen/workspaces/add_workspace_page.dart';
import 'package:mk_app/screens/orgScreen/workspaces/workspace_widgets.dart';
import 'package:mk_app/utils/pay_period.dart';
import 'package:mk_app/utils/workspace_prefs.dart';
import 'package:mk_app/widgets/employee_overview_view.dart';
import 'package:mk_app/widgets/user_avatar.dart';

/// The signed-in user's own profile — works for both Admin and Employee.
/// Separate from [OrgProfile], which is the business's own card.
class UserProfilePage extends StatefulWidget {
  final AuthResult session;

  /// Called when an admin opens a different workspace from the Workspaces section.
  final ValueChanged<AuthResult>? onSessionChanged;

  /// Lets the Workspaces section send an admin on to another screen (Plan & billing).
  final ValueChanged<AppSection>? onOpenSection;

  const UserProfilePage({required this.session, this.onSessionChanged, this.onOpenSection, super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.getMyProfile(widget.session.token);
  }

  Future<void> _refresh() {
    final future = ApiClient.getMyProfile(widget.session.token);
    setState(() => _future = future);
    return future;
  }

  Future<void> _logout(BuildContext context) async {
    await WorkspacePrefs.clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  void _editComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing your profile is coming soon')),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: typography.body.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: FDivider(style: .delta(color: colors.border))),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String? value) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? '—' : value,
              textAlign: TextAlign.end,
              style: typography.body.sm.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Crew see the same hours-and-pay view an admin gets of them; admins have no hours,
    // so they keep the plain profile below.
    if (widget.session.userType != 'Admin') {
      return _EmployeeProfile(
        session: widget.session,
        onEdit: () => _editComingSoon(context),
        onLogout: () => _logout(context),
      );
    }

    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: FutureBuilder<UserProfile>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: FCircularProgress(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: typography.body.sm.copyWith(color: colors.error),
                    ),
                    const SizedBox(height: 8),
                    FButton(variant: .outline, size: .sm, onPress: _refresh, child: const Text('Retry')),
                  ],
                ),
              );
            }

            final profile = snapshot.data!;
            final roleLabel = profile.userType == 'Admin' ? 'Admin' : 'Crew';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(fullName: profile.fullName, photoUrl: profile.photoUrl, size: 84),
                const SizedBox(height: 20),
                Text(profile.fullName, textAlign: TextAlign.center, style: typography.display.lg),
                const SizedBox(height: 6),
                Text(
                  roleLabel,
                  textAlign: TextAlign.center,
                  style: typography.body.sm.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: 24),
                _sectionLabel(context, 'Contact'),
                const SizedBox(height: 8),
                _detailRow(context, 'Email', profile.username),
                FDivider(style: .delta(color: colors.border)),
                _detailRow(context, 'Phone', profile.phone),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Employment'),
                const SizedBox(height: 8),
                _detailRow(
                  context,
                  'Started',
                  profile.createdAt == null ? null : DateFormat('d MMM yyyy').format(profile.createdAt!),
                ),
                if (profile.userType != 'Admin') ...[
                  FDivider(style: .delta(color: colors.border)),
                  _detailRow(
                    context,
                    'Pay rate',
                    profile.payRate == null ? 'Not set' : '\$${profile.payRate!.toStringAsFixed(2)}/h',
                  ),
                ],
                if (profile.userType == 'Admin') ...[
                  const SizedBox(height: 16),
                  _AdminWorkspacesSection(
                    session: widget.session,
                    onSessionChanged: widget.onSessionChanged,
                    onOpenSection: widget.onOpenSection,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  child: FButton(
                    variant: .outline,
                    onPress: () => _editComingSoon(context),
                    child: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 280,
                  child: FButton(
                    variant: .destructive,
                    onPress: () => _logout(context),
                    child: const Text('Log out'),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}

/// Admin profile → "Workspaces": every business this admin runs, with a way to open one and — on
/// the Business plan, while there is room — to add another. Free and Pro admins see an upgrade
/// prompt instead, since running several workspaces is a Business feature.
class _AdminWorkspacesSection extends StatefulWidget {
  final AuthResult session;
  final ValueChanged<AuthResult>? onSessionChanged;
  final ValueChanged<AppSection>? onOpenSection;
  const _AdminWorkspacesSection({required this.session, this.onSessionChanged, this.onOpenSection});

  @override
  State<_AdminWorkspacesSection> createState() => _AdminWorkspacesSectionState();
}

class _AdminWorkspacesSectionState extends State<_AdminWorkspacesSection> {
  late Future<(List<WorkspaceSummary>, PlanInfo)> _future;
  String? _switching;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = () async {
      final workspaces = ApiClient.getMyWorkspaces(token: widget.session.token, adminId: widget.session.userId);
      final plan = ApiClient.getPlan(token: widget.session.token, adminId: widget.session.userId);
      return (await workspaces, await plan);
    }();
  }

  Future<void> _open(WorkspaceSummary workspace) async {
    if (workspace.active || _switching != null) return;
    setState(() {
      _switching = workspace.organizationId;
      _error = null;
    });
    try {
      final session = await ApiClient.switchWorkspace(
        token: widget.session.token,
        adminId: widget.session.userId,
        organizationId: workspace.organizationId,
      );
      widget.onSessionChanged?.call(session);
    } catch (e) {
      if (mounted) {
        setState(() {
          _switching = null;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push<AddWorkspaceResult>(
      MaterialPageRoute(builder: (_) => AddWorkspacePage(session: widget.session)),
    );
    if (result == null || !mounted) return;
    final switched = result.switchedSession;
    if (switched != null) {
      widget.onSessionChanged?.call(switched);
    } else {
      setState(_load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FutureBuilder<(List<WorkspaceSummary>, PlanInfo)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: FCircularProgress());
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString(), style: typography.body.sm.copyWith(color: colors.error));
        }
        final (workspaces, plan) = snapshot.data!;
        final business = plan.maxWorkspaces > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  business ? 'WORKSPACES · ${plan.workspacesUsed} OF ${plan.maxWorkspaces}' : 'WORKSPACES',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: FDivider(style: .delta(color: colors.border))),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < workspaces.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              WorkspaceRow(
                workspace: workspaces[i],
                index: i,
                current: workspaces[i].active,
                onTap: () => _open(workspaces[i]),
                trailing: _switching == workspaces[i].organizationId
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : workspaces[i].active
                    ? const WorkspacePill('Active')
                    : Icon(FLucideIcons.chevronRight, size: 18, color: colors.mutedForeground),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: typography.body.sm.copyWith(color: colors.error)),
            ],
            const SizedBox(height: 12),
            if (plan.canAddWorkspace)
              FButton(variant: .outline, onPress: _add, child: const Text('+ Add workspace'))
            else if (!business)
              _UpgradeForWorkspaces(onSeePlans: widget.onOpenSection == null ? null : () => widget.onOpenSection!(AppSection.planBilling))
            else
              Text(
                'All ${plan.maxWorkspaces} workspaces on your plan are in use.',
                style: typography.body.xs.copyWith(color: colors.mutedForeground),
              ),
          ],
        );
      },
    );
  }
}

class _UpgradeForWorkspaces extends StatelessWidget {
  final VoidCallback? onSeePlans;
  const _UpgradeForWorkspaces({this.onSeePlans});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Run more than one business? Extra workspaces come with the Business plan.',
              style: typography.body.sm.copyWith(height: 1.4),
            ),
          ),
          if (onSeePlans != null) ...[
            const SizedBox(width: 10),
            FButton(variant: .outline, size: .sm, onPress: onSeePlans, child: const Text('See plans')),
          ],
        ],
      ),
    );
  }
}

/// An employee's own profile: this pay period's hours, pay, days worked and shifts, with the
/// account actions underneath.
class _EmployeeProfile extends StatefulWidget {
  final AuthResult session;
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  const _EmployeeProfile({required this.session, required this.onEdit, required this.onLogout});

  @override
  State<_EmployeeProfile> createState() => _EmployeeProfileState();
}

class _EmployeeProfileState extends State<_EmployeeProfile> {
  PayPeriod _period = PayPeriod.current();
  late Future<EmployeeOverview> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _shiftPeriod(PayPeriod period) {
    setState(() {
      _period = period;
      _load();
    });
  }

  void _load() {
    _future = ApiClient.getMyOverview(
      token: widget.session.token,
      employeeId: widget.session.userId,
      from: _period.start,
      to: _period.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FutureBuilder<EmployeeOverview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: FCircularProgress());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: typography.body.sm.copyWith(color: colors.error),
                  ),
                  const SizedBox(height: 8),
                  FButton(variant: .outline, size: .sm, onPress: () => setState(_load), child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        return EmployeeOverviewView(
          employee: snapshot.data!,
          periodLabel: _period.label,
          onPreviousPeriod: () => _shiftPeriod(_period.previous),
          onNextPeriod: _period.isCurrent ? null : () => _shiftPeriod(_period.next),
          footer: [
            FButton(variant: .outline, onPress: widget.onEdit, child: const Text('Edit profile')),
            const SizedBox(height: 10),
            FButton(variant: .destructive, onPress: widget.onLogout, child: const Text('Log out')),
          ],
        );
      },
    );
  }
}
