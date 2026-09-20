import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/limit_reached_sheet.dart';
import 'package:mk_app/screens/orgScreen/employees/employee_detail_page.dart';
import 'package:mk_app/screens/orgScreen/employees/invite_crew_sheet.dart';
import 'package:mk_app/utils/pay_period.dart';
import 'package:mk_app/widgets/overview_widgets.dart';
import 'package:mk_app/widgets/user_avatar.dart';

const kPaidGreen = Color(0xFF3FB27F);
const kOwedOrange = Color(0xFFE0964F);

String formatMoney(double value) =>
    NumberFormat.currency(symbol: r'$', decimalDigits: value % 1 == 0 ? 0 : 2).format(value);

/// Admin-only: everyone registered under the workspace, with the current pay
/// period's hours, pay rate and paid status on one row.
class EmployeesPage extends StatefulWidget {
  final AuthResult session;
  const EmployeesPage({required this.session, super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  static const _pageSize = 6;
  static const _tabAll = 0;
  static const _tabCrew = 1;
  static const _tabAdmins = 2;

  PayPeriod _period = PayPeriod.current();
  late Future<List<EmployeeOverview>> _future;
  late final Future<WorkspaceProfile> _workspaceFuture;
  String _query = '';
  int _tab = _tabAll;
  bool _unpaidOnly = false;
  int _visible = _pageSize;

  @override
  void initState() {
    super.initState();
    _workspaceFuture = ApiClient.getMyWorkspace(widget.session.token);
    _load();
  }

  void _load() {
    _future = ApiClient.getEmployeeOverview(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: _period.start,
      to: _period.end,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  void _shiftPeriod(PayPeriod period) {
    setState(() {
      _period = period;
      _visible = _pageSize;
      _load();
    });
  }

  Future<void> _openDetail(EmployeeOverview employee) async {
    final workspace = await _workspaceFuture.then<WorkspaceProfile?>((w) => w).catchError((_) => null);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeDetailPage(
          session: widget.session,
          employeeId: employee.id,
          period: _period,
          businessName: workspace?.businessName,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _invite(List<EmployeeOverview> people) async {
    final workspace = await _workspaceFuture.then<WorkspaceProfile?>((w) => w).catchError((_) => null);
    if (!mounted) return;

    // At the plan's people limit nobody new can join, so explain that instead of
    // handing out a code that would be refused.
    final plan = await ApiClient.getPlan(
      token: widget.session.token,
      adminId: widget.session.userId,
    ).then<PlanInfo?>((p) => p).catchError((_) => null);
    if (!mounted) return;
    if (plan != null && plan.full) {
      final changed = await openLimitReachedSheet(
        context,
        session: widget.session,
        plan: plan,
        businessName: workspace?.businessName ?? 'Your workspace',
      );
      if (changed && mounted) await _refresh();
      return;
    }

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    await openInviteCrewSheet(
      context,
      organizationId: widget.session.organizationId,
      businessName: workspace?.businessName ?? 'your workspace',
      joinedThisWeek: people
          .where((p) => !p.isAdmin && p.joinedAt != null && p.joinedAt!.isAfter(weekAgo))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FutureBuilder<List<EmployeeOverview>>(
      future: _future,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        final all = snapshot.data ?? const <EmployeeOverview>[];
        final crew = all.where((e) => !e.isAdmin).toList();
        final admins = all.where((e) => e.isAdmin).toList();
        final onSite = crew.where((e) => e.onSite).length;
        final unpaid = crew.where((e) => e.owed > 0).length;

        var rows = switch (_tab) {
          _tabCrew => crew,
          _tabAdmins => admins,
          _ => all,
        };
        rows = rows.where((e) => e.fullName.toLowerCase().contains(_query.toLowerCase())).toList();
        if (_unpaidOnly) rows = rows.where((e) => e.owed > 0).toList();

        final shown = rows.take(_visible).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Employees',
                          style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FButton(
                        size: .sm,
                        onPress: done ? () => _invite(all) : null,
                        child: const Text('+ Invite'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _PeriodArrow(icon: Icons.chevron_left, onPressed: () => _shiftPeriod(_period.previous)),
                      Expanded(
                        child: FutureBuilder<WorkspaceProfile>(
                          future: _workspaceFuture,
                          builder: (context, ws) => Text(
                            '${ws.data?.businessName ?? ''} · ${_period.label}',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: typography.body.sm.copyWith(color: colors.mutedForeground),
                          ),
                        ),
                      ),
                      _PeriodArrow(
                        icon: Icons.chevron_right,
                        onPressed: _period.isCurrent ? null : () => _shiftPeriod(_period.next),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatStrip(
                    items: [
                      StatItem(value: '${crew.length}', label: 'CREW'),
                      StatItem(value: '${admins.length}', label: 'ADMINS'),
                      StatItem(value: '$onSite', label: 'ON SITE', valueColor: kPaidGreen),
                      StatItem(
                        value: '$unpaid',
                        label: _unpaidOnly ? 'UNPAID ✓' : 'UNPAID',
                        valueColor: kOwedOrange,
                        onTap: () => setState(() {
                          _unpaidOnly = !_unpaidOnly;
                          _visible = _pageSize;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FTextField(
                    control: FTextFieldControl.managed(
                      onChange: (v) => setState(() {
                        _query = v.text;
                        _visible = _pageSize;
                      }),
                    ),
                    hint: 'Search by name',
                    prefixBuilder: (context, style, variants) => FTextField.prefixIconBuilder(
                      context,
                      style,
                      variants,
                      Icon(FLucideIcons.search, size: 16, color: colors.mutedForeground),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedPills(
                    labels: ['All · ${all.length}', 'Crew · ${crew.length}', 'Admins · ${admins.length}'],
                    selected: _tab,
                    onChanged: (i) => setState(() {
                      _tab = i;
                      _visible = _pageSize;
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (!done) return const Center(child: FCircularProgress());
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(snapshot.error.toString(), style: TextStyle(color: colors.error)),
                      ),
                    );
                  }
                  if (rows.isEmpty) {
                    return Center(
                      child: Text(
                        _unpaidOnly ? 'Nobody is owed this period.' : 'No one found.',
                        style: typography.body.sm.copyWith(color: colors.mutedForeground),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        for (final employee in shown) ...[
                          _EmployeeRow(
                            employee: employee,
                            onTap: employee.isAdmin ? null : () => _openDetail(employee),
                          ),
                          FDivider(style: .delta(color: colors.border)),
                        ],
                        if (rows.length > shown.length)
                          Center(
                            child: FButton(
                              variant: .ghost,
                              onPress: () => setState(() => _visible += 10),
                              child: Text('Show ${(rows.length - shown.length).clamp(0, 10)} more'),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PeriodArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _PeriodArrow({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null ? colors.mutedForeground.withValues(alpha: 0.35) : colors.foreground,
        ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final EmployeeOverview employee;
  final VoidCallback? onTap;
  const _EmployeeRow({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    final subtitle = employee.isAdmin
        ? 'Admin'
        : 'Crew · ${employee.payRate == null ? 'No rate set' : '${formatMoney(employee.payRate!)}/h'}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(fullName: employee.fullName, photoUrl: employee.photoUrl, size: 34),
                if (employee.onSite)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: kPaidGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.background, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.sm.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(color: colors.mutedForeground, fontSize: 11),
                  ),
                  if (employee.firstMissingDate != null)
                    Text(
                      '⚑ ${DateFormat('EEE d MMM').format(employee.firstMissingDate!)} — no log',
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(color: colors.destructive, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (!employee.isAdmin) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${employee.totalHours.toStringAsFixed(1)}h',
                    style: typography.body.sm.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  if (employee.paid)
                    const PaidBadge(paid: true)
                  else if (employee.owed > 0)
                    const PaidBadge(paid: false),
                ],
              ),
              Icon(Icons.chevron_right, size: 16, color: colors.mutedForeground),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Paid" / "Unpaid" pill.
class PaidBadge extends StatelessWidget {
  final bool paid;
  const PaidBadge({required this.paid, super.key});

  @override
  Widget build(BuildContext context) {
    final color = paid ? kPaidGreen : context.theme.colors.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            paid ? 'Paid' : 'Unpaid',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
