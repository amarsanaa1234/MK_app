import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_parts.dart';
import 'package:mk_app/widgets/job_card.dart' show jobStatusColor, jobStatusLabels;
import 'package:mk_app/widgets/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Crew only: "My roster" — the signed-in person's week, day by day. Today's job comes with
/// directions, days off are shown as days off (so a gap never looks like a missing shift), and a
/// tap on any shift opens who is on it, the site notes and the induction link.
class MyRosterPage extends StatefulWidget {
  final AuthResult session;
  const MyRosterPage({required this.session, super.key});

  @override
  State<MyRosterPage> createState() => _MyRosterPageState();
}

class _MyRosterPageState extends State<MyRosterPage> {
  late DateTime _weekStart = _mondayOf(DateTime.now());
  late Future<List<JobAdSummary>> _future;
  DateTime? _selected;
  final Map<DateTime, GlobalKey> _dayKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOf(DateTime d) {
    final day = _dateOnly(d);
    return DateTime(day.year, day.month, day.day - (day.weekday - 1));
  }

  DateTime _day(int offset) => DateTime(_weekStart.year, _weekStart.month, _weekStart.day + offset);

  bool get _isThisWeek => _weekStart == _mondayOf(DateTime.now());

  void _load() {
    _future = ApiClient.getMyJobPosts(
      token: widget.session.token,
      employeeId: widget.session.userId,
      from: _weekStart,
      to: _day(6),
    );
  }

  void _goToWeek(DateTime monday) {
    setState(() {
      _weekStart = monday;
      _selected = null;
      _dayKeys.clear();
      _load();
    });
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  GlobalKey _keyFor(DateTime day) => _dayKeys.putIfAbsent(day, GlobalKey.new);

  void _scrollTo(DateTime day) {
    setState(() => _selected = day);
    final ctx = _dayKeys[day]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  bool _leading(JobAdSummary job) => job.leader?.id == widget.session.userId;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final rangeLabel =
        '${DateFormat('d').format(_weekStart)} – ${DateFormat('d MMM yyyy').format(_day(6))}';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text('My roster', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            [
              if (widget.session.businessName.isNotEmpty) widget.session.businessName,
              widget.session.fullName,
            ].join(' · '),
            style: typography.body.md.copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _NavArrow(icon: FLucideIcons.chevronLeft, onTap: () => _goToWeek(_day(-7))),
              const SizedBox(width: 8),
              Text(rangeLabel, style: typography.body.sm.copyWith(fontWeight: FontWeight.w600, fontFamily: 'JetBrains Mono')),
              const SizedBox(width: 8),
              _NavArrow(icon: FLucideIcons.chevronRight, onTap: () => _goToWeek(_day(7))),
              const Spacer(),
              if (!_isThisWeek)
                GestureDetector(
                  onTap: () => _goToWeek(_mondayOf(DateTime.now())),
                  child: Text(
                    'Today',
                    style: typography.body.sm.copyWith(color: kPlanBlue, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<JobAdSummary>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: FCircularProgress());
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
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
              return _week(context, snapshot.data ?? const []);
            },
          ),
        ],
      ),
    );
  }

  Widget _week(BuildContext context, List<JobAdSummary> jobs) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final today = _dateOnly(DateTime.now());

    // Jobs per day, earliest start first.
    final byDay = <DateTime, List<JobAdSummary>>{};
    for (final job in jobs) {
      byDay.putIfAbsent(_dateOnly(job.workDate), () => []).add(job);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    }

    final days = [for (var i = 0; i < 7; i++) _day(i)];
    final offDays = days.where((d) => !byDay.containsKey(d)).length;
    final leading = jobs.where(_leading).length;
    final selected = _selected ?? (days.contains(today) ? today : days.firstWhere(byDay.containsKey, orElse: () => days.first));

    // Consecutive days off collapse into one row ("Sat 15 – Sun 16 Aug · Days off").
    final sections = <Widget>[];
    var i = 0;
    while (i < days.length) {
      final day = days[i];
      final dayJobs = byDay[day];
      if (dayJobs != null) {
        final isToday = day == today;
        sections.add(
          KeyedSubtree(
            key: _keyFor(day),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${isToday ? 'TODAY · ' : ''}${DateFormat('EEE d MMM').format(day).toUpperCase()}',
                        style: typography.body.xs.copyWith(
                          color: isToday ? kPlanBlue : colors.mutedForeground,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                    Text(
                      '${dayJobs.length} ${dayJobs.length == 1 ? 'shift' : 'shifts'}',
                      style: typography.body.xs.copyWith(color: colors.mutedForeground, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final job in dayJobs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ShiftCard(
                      job: job,
                      leading: _leading(job),
                      today: isToday,
                      me: widget.session.userId,
                      onTap: () => _openShift(job),
                    ),
                  ),
              ],
            ),
          ),
        );
        i++;
      } else {
        var j = i;
        while (j + 1 < days.length && !byDay.containsKey(days[j + 1])) {
          j++;
        }
        final first = days[i];
        final last = days[j];
        final label = i == j
            ? DateFormat('EEE d MMM').format(first)
            : '${DateFormat('EEE d').format(first)} – ${DateFormat('EEE d MMM').format(last)}';
        sections.add(
          KeyedSubtree(
            key: _keyFor(first),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: typography.body.sm.copyWith(color: colors.mutedForeground))),
                    Text(
                      i == j ? 'Day off' : 'Days off',
                      style: typography.body.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        // Every day in the merged run scrolls to the same row.
        for (var k = i + 1; k <= j; k++) {
          _dayKeys[days[k]] = _keyFor(first);
        }
        i = j + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayStrip(
          days: days,
          today: today,
          selected: selected,
          hasShift: byDay.containsKey,
          onSelect: _scrollTo,
        ),
        const SizedBox(height: 12),
        _Tally(items: [('Shifts', jobs.length), ('Leading', leading), ('Days off', offDays)]),
        ...sections,
      ],
    );
  }

  void _openShift(JobAdSummary job) {
    showFSheet<void>(
      context: context,
      side: .btt,
      mainAxisMaxRatio: 0.92,
      builder: (_) => _ShiftSheet(job: job, me: widget.session.userId),
    );
  }
}

Future<void> _openDirections(String address) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 16, color: colors.mutedForeground),
      ),
    );
  }
}

/// Mon..Sun as seven cells: today filled, days with a shift carry a dot.
class _DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;
  final DateTime selected;
  final bool Function(DateTime) hasShift;
  final ValueChanged<DateTime> onSelect;
  const _DayStrip({
    required this.days,
    required this.today,
    required this.selected,
    required this.hasShift,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(day),
                child: _cell(colors, typography, day),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cell(FColors colors, FTypography typography, DateTime day) {
    final isToday = day == today;
    final isSelected = day == selected;
    final filled = isToday;
    final fg = filled ? kPlanInk : colors.foreground;
    final dim = filled ? kPlanInk.withValues(alpha: 0.75) : colors.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: filled ? kPlanBlue : null,
        borderRadius: BorderRadius.circular(10),
        border: !filled && isSelected ? Border.all(color: kPlanBlue, width: 1.5) : null,
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEE').format(day).toUpperCase(),
            style: typography.body.xs2.copyWith(color: dim, letterSpacing: 0.4),
          ),
          const SizedBox(height: 3),
          Text('${day.day}', style: typography.body.lg.copyWith(color: fg, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasShift(day) ? (filled ? kPlanInk : kPlanBlue) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  final List<(String, int)> items;
  const _Tally({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: colors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items[i].$2}',
                        style: typography.display.lg.copyWith(fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$1.toUpperCase(),
                        style: typography.body.xs2.copyWith(color: colors.mutedForeground, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final bool lead;
  final bool onTint;
  const _RolePill({required this.lead, this.onTint = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final filled = lead && onTint;
    final bg = filled
        ? kPlanBlue
        : lead
        ? kPlanBlue.withValues(alpha: 0.18)
        : Colors.transparent;
    final fg = filled ? kPlanInk : (lead ? kPlanBlue : colors.mutedForeground);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: lead ? null : Border.all(color: colors.border),
      ),
      child: Text(
        lead ? 'Lead' : 'Crew',
        style: context.theme.typography.body.xs.copyWith(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final JobAdSummary job;
  final bool leading;
  final bool today;
  final String me;
  final VoidCallback onTap;
  const _ShiftCard({
    required this.job,
    required this.leading,
    required this.today,
    required this.me,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final others = [
      if (!leading && job.leader != null) job.leader!,
      ...job.crew.where((e) => e.id != me),
    ];
    final time = job.startTime == null ? '—' : job.startTime!.substring(0, 5);
    final subtitle = [
      if (job.jobType != null && job.jobType!.isNotEmpty) job.jobType!,
    ].join(' · ');
    final status = job.status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: today ? kPlanBlue.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: today ? Colors.transparent : colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(time, style: typography.body.sm.copyWith(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (status != 'OPEN') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: jobStatusColor(context, status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        jobStatusLabels[status] ?? status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: jobStatusColor(context, status)),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _RolePill(lead: leading, onTint: today),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.addressLine ?? 'No address set',
                style: typography.body.md.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: typography.body.sm.copyWith(color: colors.mutedForeground)),
              ],
              if (others.isNotEmpty) ...[
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  child: AvatarGroup(
                    people: others.take(3).toList(),
                    label: Text(
                      'with ${others.take(2).map((e) => e.fullName).join(', ')}'
                      '${others.length > 2 ? ', +${others.length - 2}' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              if (today && job.addressLine != null) ...[
                const SizedBox(height: 10),
                FButton(onPress: () => _openDirections(job.addressLine!), child: const Text('Get directions')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One shift in full: who is leading, who is with you, the site notes and the induction link.
class _ShiftSheet extends StatelessWidget {
  final JobAdSummary job;
  final String me;
  const _ShiftSheet({required this.job, required this.me});

  bool get _leading => job.leader?.id == me;

  Future<void> _call(BuildContext context, String phone) async {
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't start the call")));
    }
  }

  Future<void> _openInduction(BuildContext context) async {
    var raw = job.inductionUrl!.trim();
    if (!raw.contains('://')) raw = 'https://$raw';
    final uri = Uri.tryParse(raw);
    final opened = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open the induction link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final time = job.startTime == null ? '—' : job.startTime!.substring(0, 5);
    final people = [
      if (job.leader != null) (job.leader!, true),
      ...job.crew.where((e) => e.id != job.leader?.id).map((e) => (e, false)),
    ];
    final hasNotes = job.notes != null && job.notes!.trim().isNotEmpty;
    final hasInduction = job.inductionUrl != null && job.inductionUrl!.trim().isNotEmpty;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: typography.body.xs.copyWith(
          color: colors.mutedForeground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );

    Widget infoRow(String k, String v, {bool mono = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Text(k, style: typography.body.sm.copyWith(color: colors.mutedForeground)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: mono ? 'JetBrains Mono' : null,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RolePill(lead: _leading, onTint: true),
                  if (job.jobType != null && job.jobType!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        job.jobType!,
                        style: typography.body.xs.copyWith(color: colors.mutedForeground, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.addressLine ?? 'No address set',
                style: typography.display.xl.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('EEE d MMM').format(job.workDate)} · $time',
                style: typography.body.sm.copyWith(color: colors.mutedForeground, fontFamily: 'JetBrains Mono'),
              ),
              const SizedBox(height: 12),
              infoRow('Start', time, mono: true),
              infoRow('Your role', _leading ? 'Lead' : 'Crew'),
              label('CREW · ${people.length}'),
              for (final (person, isLead) in people)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
                  child: Row(
                    children: [
                      UserAvatar(fullName: person.fullName, photoUrl: person.photoUrl, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: person.fullName,
                                style: typography.body.md.copyWith(fontWeight: FontWeight.w700),
                                children: [
                                  if (person.id == me)
                                    TextSpan(
                                      text: ' (you)',
                                      style: typography.body.md.copyWith(color: colors.mutedForeground),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              isLead ? 'Lead' : 'Crew',
                              style: typography.body.xs.copyWith(color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      if (person.id != me && person.phone != null && person.phone!.trim().isNotEmpty)
                        GestureDetector(
                          onTap: () => _call(context, person.phone!),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              'Call',
                              style: typography.body.sm.copyWith(color: kPlanBlue, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (hasNotes) ...[
                label('SITE NOTES'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(job.notes!.trim(), style: typography.body.sm.copyWith(height: 1.45)),
                ),
              ],
              if (hasInduction) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openInduction(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Site induction', style: typography.body.md.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Text('Open ›', style: typography.body.sm.copyWith(color: kPlanBlue, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FButton(
                onPress: job.addressLine == null ? null : () => _openDirections(job.addressLine!),
                child: const Text('Get directions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
