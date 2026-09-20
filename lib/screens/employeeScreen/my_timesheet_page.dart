import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/app_dialog.dart';

/// An employee's own logged hours over a rolling two-week window — date,
/// address, and hours per entry, with the period's total hours and days
/// worked, and the ability to step back to previous fortnights.
class MyTimesheetPage extends StatefulWidget {
  final AuthResult session;
  const MyTimesheetPage({required this.session, super.key});

  @override
  State<MyTimesheetPage> createState() => _MyTimesheetPageState();
}

class _MyTimesheetPageState extends State<MyTimesheetPage> {
  static const _windowDays = 14;

  int _weekOffset = 0;
  late Future<List<WorkHourEntrySummary>> _future;

  DateTime get _to => DateTime.now().subtract(Duration(days: _windowDays * _weekOffset));
  DateTime get _from => _to.subtract(const Duration(days: _windowDays - 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final from = DateTime(_from.year, _from.month, _from.day);
    final to = DateTime(_to.year, _to.month, _to.day);
    _future = ApiClient.getMyWorkHours(
      token: widget.session.token,
      employeeId: widget.session.userId,
      from: from,
      to: to,
    );
  }

  void _shiftWindow(int delta) {
    setState(() {
      _weekOffset += delta;
      if (_weekOffset < 0) _weekOffset = 0;
      _load();
    });
  }

  void _showEntryDetails(BuildContext context, WorkHourEntrySummary entry) {
    showFAppDialog<void>(
      context: context,
      title: DateFormat('EEEE, d MMMM yyyy').format(entry.workDate),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.jobAddressLine ?? 'No address on file',
            style: context.theme.typography.body.sm,
          ),
          const SizedBox(height: 10),
          Text(
            '${entry.hoursWorked.toStringAsFixed(1)} hours worked',
            style: context.theme.typography.body.sm.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        FButton(
          variant: .ghost,
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My timesheet', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftWindow(1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${DateFormat('d MMM').format(_from)} – ${DateFormat('d MMM').format(_to)}',
                      textAlign: TextAlign.center,
                      style: typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: _weekOffset == 0 ? null : () => _shiftWindow(-1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<WorkHourEntrySummary>>(
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

              final entries = snapshot.data ?? const <WorkHourEntrySummary>[];
              final totalHours = entries.fold<double>(0, (sum, e) => sum + e.hoursWorked);
              final daysWorked = entries.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Total hours',
                            value: totalHours.toStringAsFixed(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: 'Days worked',
                            value: '$daysWorked',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              'No hours logged in this window.',
                              style: typography.body.sm.copyWith(color: colors.mutedForeground),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) => FDivider(style: .delta(color: colors.border)),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat('EEE d MMM').format(entry.workDate),
                                        style: typography.body.sm.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      '${entry.hoursWorked.toStringAsFixed(1)}h',
                                      style: typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline, size: 18),
                                      color: colors.mutedForeground,
                                      tooltip: 'View details',
                                      onPressed: () => _showEntryDetails(context, entry),
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
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: typography.display.xl.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: typography.body.xs.copyWith(color: colors.mutedForeground)),
        ],
      ),
    );
  }
}
