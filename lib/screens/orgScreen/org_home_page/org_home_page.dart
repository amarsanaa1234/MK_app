import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/payroll/job_hours_entry_page.dart';
import 'package:mk_app/widgets/job_card.dart';

import 'org_sheet.dart';

class OrgHomePage extends StatefulWidget {
  final AuthResult session;
  const OrgHomePage({required this.session, super.key});

  @override
  State<OrgHomePage> createState() => _OrgHomePageState();
}

class _OrgHomePageState extends State<OrgHomePage> {
  late Future<List<JobAdSummary>> _todayFuture;
  late Future<List<JobAdSummary>> _upcomingFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _todayFuture = ApiClient.getJobAds(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: today,
      to: today,
    );
    _upcomingFuture = ApiClient.getJobAds(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: today.add(const Duration(days: 1)),
      to: today.add(const Duration(days: 7)),
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_todayFuture, _upcomingFuture]);
  }

  Future<void> _openNewPost() async {
    await openNewPostSheet(context, widget.session);
    if (!mounted) return;
    _refresh();
  }

  Future<void> _editJob(JobAdSummary job) async {
    await openNewPostSheet(context, widget.session, existingJob: job);
    if (!mounted) return;
    _refresh();
  }

  Future<void> _enterHours(JobAdSummary job) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JobHoursEntryPage(session: widget.session, job: job)),
    );
    if (saved == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton(
      onPressed: _openNewPost,
      backgroundColor: context.theme.colors.primary,
      foregroundColor: context.theme.colors.primaryForeground,
      child: const Icon(Icons.add),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FTabs(
            expands: true,
            children: [
              .entry(
                label: const Text('Today'),
                child: _JobList(
                  future: _todayFuture,
                  onRefresh: _refresh,
                  emptyText: 'No jobs scheduled today.',
                  onEdit: _editJob,
                  onEnterHours: _enterHours,
                ),
              ),
              .entry(
                label: const Text('Upcoming'),
                child: _JobList(
                  future: _upcomingFuture,
                  onRefresh: _refresh,
                  emptyText: 'Nothing coming up in the next 7 days.',
                  onEdit: _editJob,
                  onEnterHours: _enterHours,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _JobList extends StatelessWidget {
  final Future<List<JobAdSummary>> future;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final ValueChanged<JobAdSummary> onEdit;
  final ValueChanged<JobAdSummary> onEnterHours;

  const _JobList({
    required this.future,
    required this.onRefresh,
    required this.emptyText,
    required this.onEdit,
    required this.onEnterHours,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<List<JobAdSummary>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: FCircularProgress());
      }

      if (snapshot.hasError) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.theme.colors.error),
                ),
              ),
            ],
          ),
        );
      }

      final jobs = [...(snapshot.data ?? const <JobAdSummary>[])]
        ..sort((a, b) {
          final byDate = a.workDate.compareTo(b.workDate);
          if (byDate != 0) return byDate;
          return (a.startTime ?? '').compareTo(b.startTime ?? '');
        });

      if (jobs.isEmpty) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.theme.colors.mutedForeground),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            final crew = [if (job.leader != null) job.leader!, ...job.crew];
            final timeLabel = job.startTime?.substring(0, 5);
            final descriptionParts = [
              ?timeLabel,
              if (job.jobType != null && job.jobType!.isNotEmpty) job.jobType!,
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: JobCard(
                overline: Text(_dateLabel(job.workDate)),
                status: job.status,
                addressLine: job.addressLine,
                descriptionText: descriptionParts.isEmpty ? 'Job details pending' : descriptionParts.join(' · '),
                notes: job.notes,
                inductionUrl: job.inductionUrl,
                avatarPeople: crew,
                avatarLabel: crew.isEmpty
                    ? null
                    : Text(
                        job.leader != null
                            ? 'Lead: ${job.leader!.fullName}'
                                  '${job.crew.isNotEmpty ? ' +${job.crew.length}' : ''}'
                            : 'with ${crew.map((e) => e.fullName).join(', ')}',
                      ),
                leader: job.leader,
                crew: job.crew,
                onEdit: () => onEdit(job),
                onEnterHours: () => onEnterHours(job),
              ),
            );
          },
        ),
      );
    },
  );
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = date.difference(today).inDays;
  final formatted = DateFormat('EEE d MMM').format(date);
  if (diff == 0) return 'Today · $formatted';
  if (diff == 1) return 'Tomorrow · $formatted';
  return formatted;
}
