import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/payroll/job_hours_entry_page.dart';
import 'package:mk_app/utils/pay_period.dart';
import 'package:mk_app/widgets/app_dialog.dart';
import 'package:mk_app/widgets/employee_overview_view.dart';
import 'package:mk_app/widgets/pay_rate_dialog.dart';

const _kBackLink = Color(0xFF7BA4D9);

/// Admin-only: one crew member's hours, shifts and contact details for a pay
/// period, with the actions an admin needs at the end of it — fix a missing
/// log, change the pay rate, mark the period as paid, or remove the person.
class EmployeeDetailPage extends StatefulWidget {
  final AuthResult session;
  final String employeeId;
  final PayPeriod period;
  final String? businessName;

  const EmployeeDetailPage({
    required this.session,
    required this.employeeId,
    required this.period,
    this.businessName,
    super.key,
  });

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  late Future<EmployeeOverview> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.getEmployeeOverview(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: widget.period.start,
      to: widget.period.end,
    ).then((all) => all.firstWhere((e) => e.id == widget.employeeId));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editRate(EmployeeOverview employee) async {
    final result = await showPayRateDialog(
      context: context,
      name: employee.fullName,
      currentRate: employee.payRate,
    );
    if (result == null || !mounted) return;

    await _run(
      () => ApiClient.updatePayRate(
        token: widget.session.token,
        adminId: widget.session.userId,
        employeeId: employee.id,
        payRate: result,
      ),
    );
  }

  Future<void> _togglePaid(EmployeeOverview employee) => _run(
    () => ApiClient.setPeriodPaid(
      token: widget.session.token,
      adminId: widget.session.userId,
      employeeId: employee.id,
      from: widget.period.start,
      to: widget.period.end,
      paid: !employee.paid,
    ),
  );

  /// Asks before removing — this takes the person out of the workspace, so it is never
  /// one tap.
  Future<void> _confirmRemove(EmployeeOverview employee) async {
    final confirmed = await showFAppDialog<bool>(
      context: context,
      title: 'Remove ${employee.fullName}?',
      bodyText:
          'They will lose access to the app and come off upcoming jobs. '
          'Their past hours and pay history are kept.',
      actions: [
        FButton(variant: .ghost, onPress: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FButton(variant: .destructive, onPress: () => Navigator.of(context).pop(true), child: const Text('Remove')),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.removeEmployee(
        token: widget.session.token,
        adminId: widget.session.userId,
        employeeId: employee.id,
      );
      messenger.showSnackBar(SnackBar(content: Text('${employee.fullName} was removed')));
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
    }
  }

  Future<void> _fixLog(Shift shift) async {
    setState(() => _busy = true);
    try {
      final jobs = await ApiClient.getJobAds(
        token: widget.session.token,
        adminId: widget.session.userId,
        from: shift.date,
        to: shift.date,
      );
      final job = jobs.where((j) => j.id == shift.jobAdId).firstOrNull;
      if (job == null) throw ApiException('That job could not be found.');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JobHoursEntryPage(session: widget.session, job: job)),
      );
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, size: 22, color: _kBackLink),
                          Text(
                            'Employees',
                            style: typography.body.md.copyWith(color: _kBackLink, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<EmployeeOverview>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: FCircularProgress());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(snapshot.error.toString(), style: TextStyle(color: colors.error)),
                          ),
                        );
                      }
                      final employee = snapshot.data!;
                      return EmployeeOverviewView(
                        employee: employee,
                        periodLabel: widget.period.label,
                        onFixLog: _fixLog,
                        footer: [
                          FButton(
                            onPress: _busy ? null : () => _togglePaid(employee),
                            child: _busy
                                ? const FCircularProgress(size: .xs)
                                : Text(employee.paid ? 'Paid · Undo' : 'Mark period as paid'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FButton(
                                  variant: .outline,
                                  onPress: _busy ? null : () => _editRate(employee),
                                  child: const Text('Edit pay rate'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FButton(
                                  variant: .outline,
                                  onPress: _busy ? null : () => _confirmRemove(employee),
                                  prefix: Icon(FLucideIcons.userMinus, color: colors.destructive),
                                  child: Text('Remove', style: TextStyle(color: colors.destructive)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
