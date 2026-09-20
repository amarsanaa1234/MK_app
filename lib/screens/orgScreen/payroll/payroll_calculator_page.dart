import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';

/// Admin-only: pick a crew member and one of their job posts, log hours
/// against it, and see the pay figure computed from their pay rate.
///
/// Jobs created via the "Post a job" flow only get a flat crew list
/// (JobAdCrew), not the formal Assignment the hours-recording backend
/// expects — the backend's `recordHoursForJob` bridges that by creating the
/// Assignment on first save, so this screen doesn't need to know about it.
class PayrollCalculatorPage extends StatefulWidget {
  final AuthResult session;
  const PayrollCalculatorPage({required this.session, super.key});

  @override
  State<PayrollCalculatorPage> createState() => _PayrollCalculatorPageState();
}

class _PayrollCalculatorPageState extends State<PayrollCalculatorPage> {
  late final Future<List<EmployeeDetail>> _employeesFuture;
  late final Future<List<JobAdSummary>> _jobsFuture;

  EmployeeDetail? _employee;
  JobAdSummary? _job;
  final _hoursController = TextEditingController();
  bool _saving = false;
  Future<List<WorkHourEntrySummary>>? _recentFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = ApiClient.getEmployeesWithRates(
      token: widget.session.token,
      adminId: widget.session.userId,
    );
    final now = DateTime.now();
    _jobsFuture = ApiClient.getJobAds(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: now.subtract(const Duration(days: 30)),
      to: now.add(const Duration(days: 30)),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  void _selectEmployee(EmployeeDetail? employee) {
    setState(() {
      _employee = employee;
      _job = null;
      _recentFuture = employee == null
          ? null
          : ApiClient.getRecentWorkHours(
              token: widget.session.token,
              adminId: widget.session.userId,
              employeeId: employee.id,
            );
    });
  }

  double? get _hours => double.tryParse(_hoursController.text);

  double? get _payAmount {
    final rate = _employee?.payRate;
    final hours = _hours;
    if (rate == null || hours == null) return null;
    return rate * hours;
  }

  Future<void> _save() async {
    final employee = _employee;
    final job = _job;
    final hours = _hours;
    if (employee == null || job == null || hours == null) return;

    setState(() => _saving = true);
    try {
      await ApiClient.recordHoursForJob(
        token: widget.session.token,
        adminId: widget.session.userId,
        jobAdId: job.id,
        employeeId: employee.id,
        workDate: job.workDate,
        hours: hours,
      );
      if (!mounted) return;
      setState(() {
        _recentFuture = ApiClient.getRecentWorkHours(
          token: widget.session.token,
          adminId: widget.session.userId,
          employeeId: employee.id,
        );
        _hoursController.clear();
        _job = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to timesheet')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payroll calculator', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(DateFormat('EEE d MMM yyyy').format(DateTime.now()), style: typography.body.sm.copyWith(color: colors.mutedForeground)),
          const SizedBox(height: 20),

          FutureBuilder<List<EmployeeDetail>>(
            future: _employeesFuture,
            builder: (context, snapshot) {
              final employees = snapshot.data ?? const <EmployeeDetail>[];
              return FSelect<EmployeeDetail>.searchBuilder(
                hint: 'Select crew member',
                format: (e) => e.fullName,
                control: FSelectControl<EmployeeDetail>.managed(onChange: _selectEmployee),
                filter: (query) async => query.isEmpty
                    ? employees
                    : employees.where((e) => e.fullName.toLowerCase().contains(query.toLowerCase())),
                contentBuilder: (context, _, items) => [
                  for (final e in items) .item(title: Text(e.fullName), value: e),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          if (_employee != null) ...[
            FutureBuilder<List<JobAdSummary>>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                final jobs = (snapshot.data ?? const <JobAdSummary>[])
                    .where(
                      (j) =>
                          j.leader?.id == _employee!.id || j.crew.any((c) => c.id == _employee!.id),
                    )
                    .toList()
                  ..sort((a, b) => b.workDate.compareTo(a.workDate));

                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 44, child: Center(child: FCircularProgress()));
                }
                if (jobs.isEmpty) {
                  return Text(
                    '${_employee!.fullName} has no job posts in the last/next 30 days.',
                    style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  );
                }

                return FSelect<JobAdSummary>.searchBuilder(
                  hint: 'Select job',
                  format: (j) => '${DateFormat('d MMM').format(j.workDate)} · ${j.addressLine ?? j.jobType ?? 'Job'}',
                  control: FSelectControl<JobAdSummary>.managed(onChange: (j) => setState(() => _job = j)),
                  filter: (query) async => query.isEmpty
                      ? jobs
                      : jobs.where((j) => (j.addressLine ?? '').toLowerCase().contains(query.toLowerCase())),
                  contentBuilder: (context, _, items) => [
                    for (final j in items)
                      .item(
                        title: Text('${DateFormat('EEE d MMM').format(j.workDate)} · ${j.addressLine ?? j.jobType ?? 'Job'}'),
                        value: j,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hours worked', style: typography.body.sm.copyWith(color: colors.mutedForeground)),
                      const SizedBox(height: 6),
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _hoursController,
                          onChange: (_) => setState(() {}),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hourly rate', style: typography.body.sm.copyWith(color: colors.mutedForeground)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _employee!.payRate == null
                              ? 'Not set'
                              : '\$${_employee!.payRate!.toStringAsFixed(2)}/h',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hours != null && _employee!.payRate != null)
                    Text(
                      '${_hours!.toStringAsFixed(1)} h × \$${_employee!.payRate!.toStringAsFixed(2)}/h',
                      style: typography.body.sm.copyWith(color: colors.mutedForeground),
                    ),
                  Text(
                    _payAmount == null ? '—' : '\$${_payAmount!.toStringAsFixed(2)}',
                    style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            FButton(
              onPress: (_job == null || _hours == null || _employee!.payRate == null || _saving)
                  ? null
                  : _save,
              child: _saving ? const FCircularProgress(size: .xs) : const Text('Save to timesheet'),
            ),
            const SizedBox(height: 24),

            Text('RECENT ENTRIES', style: typography.body.xs.copyWith(color: colors.mutedForeground, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            FutureBuilder<List<WorkHourEntrySummary>>(
              future: _recentFuture,
              builder: (context, snapshot) {
                final entries = snapshot.data ?? const <WorkHourEntrySummary>[];
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: FCircularProgress()),
                  );
                }
                if (entries.isEmpty) {
                  return Text('No entries yet.', style: typography.body.sm.copyWith(color: colors.mutedForeground));
                }
                return Column(
                  children: [
                    for (final entry in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(DateFormat('EEE d MMM').format(entry.workDate)),
                            const Spacer(),
                            Text(
                              '${entry.hoursWorked.toStringAsFixed(1)}h'
                              '${_employee!.payRate == null ? '' : ' · \$${(entry.hoursWorked * _employee!.payRate!).toStringAsFixed(2)}'}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
