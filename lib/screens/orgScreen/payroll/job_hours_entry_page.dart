import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/user_avatar.dart';

/// Admin-only: log every crew member's hours for one job post in a single
/// pass, instead of picking employee-then-job in the Payroll calculator.
/// Opened from the "Enter hours" action on a job card.
class JobHoursEntryPage extends StatefulWidget {
  final AuthResult session;
  final JobAdSummary job;
  const JobHoursEntryPage({required this.session, required this.job, super.key});

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
    _future = ApiClient.getJobHours(
      token: widget.session.token,
      adminId: widget.session.userId,
      jobAdId: widget.job.id,
    ).then((entries) {
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

  Future<void> _saveAll(List<EmployeeHours> entries) async {
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
                  child: _saving ? const FCircularProgress(size: .xs) : const Text('Save hours'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
