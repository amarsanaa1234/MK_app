import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/employees/employees_page.dart';
import 'package:mk_app/widgets/copy_text.dart';
import 'package:mk_app/widgets/overview_widgets.dart';
import 'package:mk_app/widgets/user_avatar.dart';

const _kWorkedTile = Color(0xFF8DC79B);
const _kMissingTile = Color(0xFFE8837B);
const _kTileInk = Color(0xFF1B2127);
const _kAvatarTeal = Color(0xFF8FB9BF);

/// One crew member's hours, pay, days worked, shifts and contact details for a
/// pay period. Used for the admin's employee page and for an employee's own
/// profile, so the two always look the same.
///
/// [onFixLog] is admin-only: when set, missing days and shifts are tappable.
/// [footer] holds whatever actions belong under the details.
class EmployeeOverviewView extends StatelessWidget {
  final EmployeeOverview employee;
  final String periodLabel;
  final ValueChanged<Shift>? onFixLog;
  final List<Widget> footer;

  /// When set, the days-worked heading gets arrows to step through pay periods.
  final VoidCallback? onPreviousPeriod;

  /// Null while already on the current period (nothing later to show).
  final VoidCallback? onNextPeriod;

  const EmployeeOverviewView({
    required this.employee,
    required this.periodLabel,
    this.onFixLog,
    this.footer = const [],
    this.onPreviousPeriod,
    this.onNextPeriod,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    Widget sectionLabel(String text, {bool line = true}) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Text(
            text,
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          if (line) ...[
            const SizedBox(width: 10),
            Expanded(child: Divider(height: 1, color: colors.border)),
          ],
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: UserAvatar(
              fullName: employee.fullName,
              photoUrl: employee.photoUrl,
              size: 84,
              color: _kAvatarTeal,
              textColor: _kTileInk,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            employee.fullName,
            textAlign: TextAlign.center,
            style: typography.display.xl.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            _subtitle(employee),
            textAlign: TextAlign.center,
            style: typography.body.md.copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (employee.employeeCode != null) _Chip(text: employee.employeeCode!, mono: true),
              if (employee.onSite) _Chip(text: 'On site since ${employee.onSiteSince}'),
              if (employee.paid) const PaidBadge(paid: true),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 18),
          StatStrip(
            items: [
              StatItem(value: '${employee.totalHours.toStringAsFixed(1)}h', label: 'THIS PERIOD'),
              StatItem(
                value: employee.payRate == null ? '—' : formatMoney(employee.payRate!),
                label: 'RATE / H',
              ),
              StatItem(
                value: formatMoney(employee.owed),
                label: 'OWED',
                valueColor: employee.owed > 0 ? kOwedOrange : colors.mutedForeground,
              ),
            ],
          ),
          if (onPreviousPeriod == null)
            sectionLabel('DAYS WORKED · ${periodLabel.toUpperCase()}')
          else
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'DAYS WORKED · ${periodLabel.toUpperCase()}',
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  _PeriodArrow(icon: Icons.chevron_left, onPressed: onPreviousPeriod),
                  _PeriodArrow(icon: Icons.chevron_right, onPressed: onNextPeriod),
                ],
              ),
            ),
          _DayGrid(
            days: employee.days,
            missingShifts: onFixLog == null
                ? const {}
                : {
                    for (final shift in employee.shifts.where((s) => s.status == 'MISSING'))
                      DateUtils.dateOnly(shift.date): shift,
                  },
            onFixLog: onFixLog,
          ),
          if (onFixLog != null && employee.missingLogs > 0) ...[
            const SizedBox(height: 10),
            Text('Tap a red day to fix its hours.', style: typography.body.xs.copyWith(color: _kMissingTile)),
          ],
          if (employee.shifts.isNotEmpty) ...[
            sectionLabel('SHIFTS · ${employee.shifts.length}', line: false),
            ShiftList(shifts: employee.shifts, onFixLog: onFixLog),
          ],
          sectionLabel('CONTACT'),
          _ContactRow(label: 'Email', value: employee.email ?? '—', copyable: employee.email != null),
          _ContactRow(
            label: 'Phone',
            value: employee.phone == null || employee.phone!.isEmpty ? '—' : employee.phone!,
            copyable: employee.phone != null && employee.phone!.isNotEmpty,
          ),
          if (footer.isNotEmpty) ...[const SizedBox(height: 24), ...footer],
        ],
      ),
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
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null ? colors.mutedForeground.withValues(alpha: 0.35) : colors.foreground,
        ),
      ),
    );
  }
}

/// "Crew", or "Crew · Office lead" when they led a job in the period (the most recent one).
String _subtitle(EmployeeOverview employee) {
  final led = employee.shifts.where((s) => s.lead && (s.jobType ?? '').isNotEmpty).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return led.isEmpty ? 'Crew' : 'Crew · ${led.first.jobType} lead';
}

class _Chip extends StatelessWidget {
  final String text;
  final bool mono;
  const _Chip({required this.text, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(mono ? 8 : 999),
      ),
      child: Text(
        text,
        style: context.theme.typography.body.xs.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          fontFamily: mono ? 'JetBrains Mono' : null,
        ),
      ),
    );
  }
}

/// Rows of seven tiles (Mon–Sun), one per day of the period. When [onFixLog] is set a
/// red (missing) day can be tapped to fix its hours.
class _DayGrid extends StatelessWidget {
  final List<TimesheetDay> days;
  final Map<DateTime, Shift> missingShifts;
  final ValueChanged<Shift>? onFixLog;
  const _DayGrid({required this.days, required this.missingShifts, this.onFixLog});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    Widget tile(TimesheetDay day) {
      final Color background;
      final Widget child;
      switch (day.status) {
        case 'WORKED':
          background = _kWorkedTile;
          child = Text(
            day.hoursWorked!.toStringAsFixed(1),
            style: typography.body.sm.copyWith(fontWeight: FontWeight.w700, color: _kTileInk),
          );
        case 'MISSING':
          background = _kMissingTile;
          child = const Icon(FLucideIcons.flag, size: 16, color: _kTileInk);
        case 'UPCOMING':
          background = Colors.transparent;
          child = Icon(FLucideIcons.clock, size: 15, color: colors.primary);
        default:
          background = colors.secondary;
          child = Text('–', style: typography.body.sm.copyWith(color: colors.mutedForeground));
      }
      final box = Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: day.status == 'UPCOMING' ? Border.all(color: colors.primary.withValues(alpha: 0.6)) : null,
        ),
        child: child,
      );

      final missing = day.status == 'MISSING' ? missingShifts[DateUtils.dateOnly(day.date)] : null;
      return missing == null || onFixLog == null ? box : GestureDetector(onTap: () => onFixLog!(missing), child: box);
    }

    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    Widget week(List<TimesheetDay> slice) => Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < slice.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(child: tile(slice[i])),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 0; i < slice.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${labels[i]}\n${slice[i].date.day}',
                  textAlign: TextAlign.center,
                  style: typography.body.xs2.copyWith(color: colors.mutedForeground, height: 1.3),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return Column(
      children: [
        for (var start = 0; start < days.length; start += 7) ...[
          if (start > 0) const SizedBox(height: 12),
          week(days.sublist(start, (start + 7).clamp(0, days.length))),
        ],
      ],
    );
  }
}

/// Every job in the period as date, address and hours. With a month of work this gets
/// long, so it scrolls inside a fixed-height box instead of stretching the whole page.
/// A missing shift links to "Fix log" only when [onFixLog] is given (admins).
@visibleForTesting
class ShiftList extends StatelessWidget {
  static const _rowHeight = 46.0;
  static const _maxVisibleRows = 5;

  final List<Shift> shifts;
  final ValueChanged<Shift>? onFixLog;
  const ShiftList({required this.shifts, this.onFixLog, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final visibleRows = shifts.length < _maxVisibleRows ? shifts.length : _maxVisibleRows;

    return Container(
      height: visibleRows * _rowHeight,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border), bottom: BorderSide(color: colors.border)),
      ),
      child: Scrollbar(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemExtent: _rowHeight,
          itemCount: shifts.length,
          itemBuilder: (context, index) => _ShiftRow(
            shift: shifts[index],
            showDivider: index < shifts.length - 1,
            onFixLog: onFixLog == null ? null : () => onFixLog!(shifts[index]),
          ),
        ),
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final Shift shift;
  final bool showDivider;
  final VoidCallback? onFixLog;
  const _ShiftRow({required this.shift, required this.showDivider, this.onFixLog});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final missing = shift.status == 'MISSING';
    final upcoming = shift.status == 'UPCOMING';
    final day = DateFormat('EEE d MMM').format(shift.date);

    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: colors.border)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              missing ? '$day · no hours logged' : '$day · ${shift.addressLine ?? 'No address'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.body.sm.copyWith(color: missing ? _kMissingTile : colors.mutedForeground),
            ),
          ),
          const SizedBox(width: 8),
          if (missing && onFixLog != null)
            GestureDetector(
              onTap: onFixLog,
              child: Text(
                'Fix log',
                style: typography.body.sm.copyWith(color: _kMissingTile, fontWeight: FontWeight.w800),
              ),
            )
          else if (upcoming)
            Text('Upcoming', style: typography.body.sm.copyWith(color: colors.mutedForeground))
          else if (!missing)
            Text(
              '${shift.hoursWorked!.toStringAsFixed(1)}h',
              style: typography.body.sm.copyWith(fontWeight: FontWeight.w800, color: colors.foreground),
            ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _ContactRow({required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final valueStyle = typography.body.md.copyWith(fontWeight: FontWeight.w800, color: colors.foreground);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Text(label, style: typography.body.md.copyWith(color: colors.mutedForeground)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: copyable
                  ? CopyableText(text: value, style: valueStyle, alignment: MainAxisAlignment.end)
                  : Text(value, textAlign: TextAlign.right, style: valueStyle),
            ),
          ),
        ],
      ),
    );
  }
}
