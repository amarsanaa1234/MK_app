import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/app_dialog.dart';
import 'package:mk_app/widgets/user_avatar.dart';

/// Whether [session]'s user leads [job] and still owes its hours: on or after the
/// work day, and nothing logged yet by them or an admin.
bool leadCanEnterHours(AuthResult session, JobAdSummary job) {
  final now = DateTime.now();
  final workDay = DateTime(job.workDate.year, job.workDate.month, job.workDate.day);
  return job.leader?.id == session.userId &&
      !job.hoursLogged &&
      !workDay.isAfter(DateTime(now.year, now.month, now.day));
}

/// Warns the lead that hours can be entered only once, then opens the entry page.
/// Returns true once the hours were submitted.
Future<bool> enterHoursAsLead(BuildContext context, AuthResult session, JobAdSummary job) async {
  final proceed = await showFAppDialog<bool>(
    context: context,
    title: 'One-time entry',
    bodyText: 'As the lead you can enter the crew\'s hours for this job only once. '
        'After you submit, the hours can\'t be changed from your side — your admin will review them.',
    actions: [
      FButton(variant: .ghost, onPress: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      FButton(onPress: () => Navigator.of(context).pop(true), child: const Text('Continue')),
    ],
  );
  if (proceed != true || !context.mounted) return false;

  final submitted = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => JobHoursEntryPage(session: session, job: job, asLead: true)),
  );
  if (submitted != true || !context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hours submitted')));
  return true;
}

/// Log every crew member's hours for one job post in a single pass, instead of
/// picking employee-then-job in the Payroll calculator. Opened from the
/// "Enter hours" action on a job card.
///
/// Admins can save and re-save freely. With [asLead] the job's lead fills in the
/// whole crew once: every field is required and the submission is final — an
/// admin reviews and corrects it afterwards if needed.
class JobHoursEntryPage extends StatefulWidget {
  final AuthResult session;
  final JobAdSummary job;
  final bool asLead;
  const JobHoursEntryPage({required this.session, required this.job, this.asLead = false, super.key});

  @override
  State<JobHoursEntryPage> createState() => _JobHoursEntryPageState();
}

class _JobHoursEntryPageState extends State<JobHoursEntryPage> {
  late Future<List<EmployeeHours>> _future;
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final request = widget.asLead
        ? ApiClient.getJobHoursAsLead(
            token: widget.session.token,
            employeeId: widget.session.userId,
            jobAdId: widget.job.id,
          )
        : ApiClient.getJobHours(
            token: widget.session.token,
            adminId: widget.session.userId,
            jobAdId: widget.job.id,
          );
    _future = request.then((entries) {
      for (final entry in entries) {
        _controllers.putIfAbsent(
          entry.employeeId,
          () => TextEditingController(
            text: entry.hoursWorked == null ? '' : entry.hoursWorked!.toStringAsFixed(1),
          ),
        );
      }
      return entries;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitAsLead(List<EmployeeHours> entries) async {
    final hours = <String, double>{};
    for (final entry in entries) {
      final value = double.tryParse(_controllers[entry.employeeId]?.text.trim().replaceAll(',', '.') ?? '');
      if (value == null || value < 0) {
        _showError('Enter hours for ${entry.fullName}.');
        return;
      }
      hours[entry.employeeId] = value;
    }

    final confirmed = await showFAppDialog<bool>(
      context: context,
      title: 'Submit hours?',
      bodyText: 'This is your only chance to enter hours for this job. '
          'Once submitted you can\'t change them — ask your admin if something needs fixing.',
      actions: [
        FButton(variant: .ghost, onPress: () => Navigator.of(context).pop(false), child: const Text('Check again')),
        FButton(onPress: () => Navigator.of(context).pop(true), child: const Text('Submit')),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ApiClient.submitHoursAsLead(
        token: widget.session.token,
        employeeId: widget.session.userId,
        jobAdId: widget.job.id,
        hoursByEmployee: hours,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAll(List<EmployeeHours> entries) async {
    if (widget.asLead) return _submitAsLead(entries);
    setState(() => _saving = true);
    try {
      for (final entry in entries) {
        final text = _controllers[entry.employeeId]?.text.trim() ?? '';
        if (text.isEmpty) continue;
        final hours = double.tryParse(text);
        if (hours == null) continue;

        await ApiClient.recordHoursForJob(
          token: widget.session.token,
          adminId: widget.session.userId,
          jobAdId: widget.job.id,
          employeeId: entry.employeeId,
          workDate: widget.job.workDate,
          hours: hours,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: const Text('Enter hours'),
      ),
      body: FutureBuilder<List<EmployeeHours>>(
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

          final entries = snapshot.data ?? const <EmployeeHours>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.jobType ?? 'Job',
                        style: typography.body.md.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.job.addressLine ?? 'No address set',
                        style: typography.body.sm.copyWith(color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.asLead)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.destructive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: colors.destructive),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can submit hours only once. Check every entry before submitting.',
                            style: typography.body.sm.copyWith(color: colors.destructive),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (entries.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No crew assigned to this job yet.',
                      style: typography.body.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final controller = _controllers[entry.employeeId]!;
                      return Row(
                        children: [
                          UserAvatar(fullName: entry.fullName, photoUrl: entry.photoUrl),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.fullName, style: typography.body.sm)),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: controller,
                              textAlign: TextAlign.end,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(suffixText: 'h', isDense: true),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FButton(
                  onPress: (_saving || entries.isEmpty) ? null : () => _saveAll(entries),
                  child: _saving
                      ? const FCircularProgress(size: .xs)
                      : Text(widget.asLead ? 'Submit hours' : 'Save hours'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
