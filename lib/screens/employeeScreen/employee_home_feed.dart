import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/job_card.dart';

/// Read-only feed of job posts for a Crew member — "Home · job posts",
/// mirroring the admin dashboard's Today/Upcoming split. Employees never see
/// the "post a job" entry point; that's admin-only (see [OrgHomePage] and its
/// FAB). Job cards look the same as the admin dashboard's — only the overline
/// (posted-time vs. date) and the admin-only edit/hours actions differ.
class EmployeeHomeFeed extends StatefulWidget {
  final AuthResult session;
  const EmployeeHomeFeed({required this.session, super.key});

  @override
  State<EmployeeHomeFeed> createState() => _EmployeeHomeFeedState();
}

class _EmployeeHomeFeedState extends State<EmployeeHomeFeed> {
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
    _todayFuture = ApiClient.getMyJobPosts(
      token: widget.session.token,
      employeeId: widget.session.userId,
      from: today,
      to: today,
    );
    _upcomingFuture = ApiClient.getMyJobPosts(
      token: widget.session.token,
      employeeId: widget.session.userId,
      from: today.add(const Duration(days: 1)),
      to: today.add(const Duration(days: 7)),
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_todayFuture, _upcomingFuture]);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: FTabs(
          expands: true,
          children: [
            .entry(
              label: const Text('Today'),
              child: _JobList(
                session: widget.session,
                future: _todayFuture,
                onRefresh: _refresh,
                emptyText: 'No jobs scheduled today.',
              ),
            ),
            .entry(
              label: const Text('Upcoming'),
              child: _JobList(
                session: widget.session,
                future: _upcomingFuture,
                onRefresh: _refresh,
                emptyText: 'Nothing coming up in the next 7 days.',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _JobList extends StatelessWidget {
  final AuthResult session;
  final Future<List<JobAdSummary>> future;
  final Future<void> Function() onRefresh;
  final String emptyText;

  const _JobList({
    required this.session,
    required this.future,
    required this.onRefresh,
    required this.emptyText,
  });

  String _postedLabel(DateTime? createdAt) {
    if (createdAt == null) return 'JOB POSTED';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inHours < 1) return 'NEW JOB POSTED · ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'NEW JOB POSTED · ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'JOB POSTED · yesterday';
    return 'JOB POSTED · ${DateFormat('d MMM').format(createdAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FutureBuilder<List<JobAdSummary>>(
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
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
            ),
          );
        }

        final jobs = snapshot.data ?? const <JobAdSummary>[];

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
                    style: typography.body.sm.copyWith(color: colors.mutedForeground),
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
              final isLeading = job.leader?.id == session.userId;
              final others = [
                if (!isLeading && job.leader != null) job.leader!,
                ...job.crew.where((e) => e.id != session.userId),
              ];

              final timeLabel = job.startTime?.substring(0, 5);
              final descriptionParts = [
                DateFormat('EEE d MMM').format(job.workDate),
                ?timeLabel,
                if (job.jobType != null && job.jobType!.isNotEmpty) job.jobType!,
                if (isLeading) "you're leading",
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: JobCard(
                  overline: Text(_postedLabel(job.createdAt)),
                  status: job.status,
                  addressLine: job.addressLine,
                  descriptionText: descriptionParts.join(' · '),
                  notes: job.notes,
                  avatarPeople: others,
                  avatarLabel: others.isEmpty
                      ? null
                      : Text('with ${others.map((e) => e.fullName).join(', ')}'),
                  leader: job.leader,
                  crew: job.crew,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
