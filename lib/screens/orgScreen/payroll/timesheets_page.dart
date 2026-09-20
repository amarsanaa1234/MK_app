import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/utils/pay_period.dart';
import 'package:mk_app/widgets/user_avatar.dart';

/// Admin-only: each crew member's hours logged vs. missing (vs. genuinely off)
/// over a rolling two-week window.
class TimesheetsPage extends StatefulWidget {
  final AuthResult session;
  const TimesheetsPage({required this.session, super.key});

  @override
  State<TimesheetsPage> createState() => _TimesheetsPageState();
}

class _TimesheetsPageState extends State<TimesheetsPage> {
  PayPeriod _period = PayPeriod.current();
  bool _missingOnly = false;
  late Future<List<TimesheetSummary>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.getTimesheets(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: _period.start,
      to: _period.end,
    );
  }

  void _shiftPeriod(PayPeriod period) {
    setState(() {
      _period = period;
      _load();
    });
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
              Text('Timesheets', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _RoundIconButton(icon: Icons.chevron_left, onPressed: () => _shiftPeriod(_period.previous)),
                    Expanded(
                      child: Text(
                        _period.label,
                        textAlign: TextAlign.center,
                        style: typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.chevron_right,
                      onPressed: _period.isCurrent ? null : () => _shiftPeriod(_period.next),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<TimesheetSummary>>(
                future: _future,
                builder: (context, snapshot) {
                  final missingCount = (snapshot.data ?? const <TimesheetSummary>[])
                      .where((r) => r.missingLogs > 0)
                      .length;
                  return _FilterPills(
                    missingOnly: _missingOnly,
                    missingCount: missingCount,
                    onChanged: (v) => setState(() => _missingOnly = v),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<TimesheetSummary>>(
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

              var rows = snapshot.data ?? const <TimesheetSummary>[];
              if (_missingOnly) {
                rows = rows.where((r) => r.missingLogs > 0).toList();
              }

              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    _missingOnly ? 'No missing logs in this window.' : 'No crew in this window.',
                    style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _TimesheetRow(row: rows[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chevron button for stepping the date window — plain [IconButton] visually
/// clashes with the pill-shaped container it sits in, so this trims the
/// tap target and disables-out the color itself instead.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? colors.mutedForeground.withValues(alpha: 0.35) : colors.foreground,
          ),
        ),
      ),
    );
  }
}

/// "Missing logs · N" / "All crew" segmented toggle.
class _FilterPills extends StatelessWidget {
  final bool missingOnly;
  final int missingCount;
  final ValueChanged<bool> onChanged;
  const _FilterPills({required this.missingOnly, required this.missingCount, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    Widget pill(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.foreground : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(
                color: selected ? colors.background : colors.mutedForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Missing logs · $missingCount', missingOnly, () => onChanged(true)),
        const SizedBox(width: 8),
        pill('All crew', !missingOnly, () => onChanged(false)),
      ],
    );
  }
}

class _TimesheetRow extends StatelessWidget {
  final TimesheetSummary row;
  const _TimesheetRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(fullName: row.employeeFullName, photoUrl: row.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.employeeFullName, style: typography.body.sm.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [for (final day in row.days) _DayDot(status: day.status)],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${row.totalHours.toStringAsFixed(1)}h',
            style: typography.body.md.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// A single day in a [_TimesheetRow]'s calendar strip — green for worked,
/// red for missing a log, a hollow ring for a job still to come, and faint
/// gray for a day the employee wasn't rostered at all.
class _DayDot extends StatelessWidget {
  final String status;
  const _DayDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    if (status == 'UPCOMING') {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.primary, width: 1.5),
        ),
      );
    }
    final color = switch (status) {
      'WORKED' => const Color(0xFF3FB27F),
      'MISSING' => colors.destructive,
      _ => colors.mutedForeground.withValues(alpha: 0.3),
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
