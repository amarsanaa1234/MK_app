import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/choose_plan_page.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_parts.dart';

/// Shown to an admin who tries to invite crew once the workspace has hit its
/// plan's people limit. Resolves to true when the plan was changed.
Future<bool> openLimitReachedSheet(
  BuildContext context, {
  required AuthResult session,
  required PlanInfo plan,
  required String businessName,
}) async {
  final changed = await showFSheet<bool>(
    context: context,
    side: .btt,
    mainAxisMaxRatio: 0.9,
    builder: (sheetContext) => _LimitReachedSheet(session: session, plan: plan, businessName: businessName),
  );
  return changed ?? false;
}

class _LimitReachedSheet extends StatefulWidget {
  final AuthResult session;
  final PlanInfo plan;
  final String businessName;
  const _LimitReachedSheet({required this.session, required this.plan, required this.businessName});

  @override
  State<_LimitReachedSheet> createState() => _LimitReachedSheetState();
}

class _LimitReachedSheetState extends State<_LimitReachedSheet> {
  bool _busy = false;

  PlanSpec get _current => planSpecOf(widget.plan.plan);
  PlanSpec? get _next => nextPlanAfter(widget.plan.plan);

  Future<void> _startTrial(PlanSpec next) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final updated = await ApiClient.changePlan(
        token: widget.session.token,
        adminId: widget.session.userId,
        plan: next.code,
        yearly: false,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('${next.name} trial started — ${updated.trialLengthDays} days, no card needed')),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
    }
  }

  Future<void> _seePlans() async {
    final navigator = Navigator.of(context);
    final updated = await navigator.push<PlanInfo>(
      MaterialPageRoute(builder: (_) => ChoosePlanPage(session: widget.session, current: widget.plan)),
    );
    if (updated != null && mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final plan = widget.plan;
    final next = _next;
    final trialAvailable = !plan.trialUsed && next != null;

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
              Text(
                "You've reached ${plan.maxPeople} people",
                style: typography.display.xl.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.businessName} is on the ${_current.name} plan.',
                style: typography.body.md.copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('People', style: typography.body.md.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    '${plan.peopleCount} of ${plan.maxPeople}',
                    style: typography.body.md.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              UsageBar(value: plan.peopleCount, max: plan.maxPeople),
              const SizedBox(height: 16),
              NoticeBox(
                child: Text(
                  next == null
                      ? "New crew can't join until you free up a spot."
                      : "New crew can't join until you upgrade or free up a spot.",
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: 18),
                Text(
                  '${next.name.toUpperCase()} ADDS',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 6),
                for (final line in next.additions) CheckLine(line),
                const SizedBox(height: 18),
                FButton(
                  onPress: _busy ? null : (trialAvailable ? () => _startTrial(next) : _seePlans),
                  child: _busy
                      ? const FCircularProgress(size: .xs)
                      : Text(trialAvailable ? 'Start 30-day free trial' : 'See all plans'),
                ),
                if (trialAvailable) ...[
                  const SizedBox(height: 10),
                  FButton(variant: .outline, onPress: _busy ? null : _seePlans, child: const Text('See all plans')),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No card needed to start.',
                      style: typography.body.xs.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
