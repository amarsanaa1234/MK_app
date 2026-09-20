import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_parts.dart';
import 'package:mk_app/widgets/app_dialog.dart';
import 'package:mk_app/widgets/overview_widgets.dart';

/// Pricing screen: Free, Pro and Business side by side. Pops with the updated
/// [PlanInfo] when the plan was changed.
class ChoosePlanPage extends StatefulWidget {
  final AuthResult session;
  final PlanInfo current;
  const ChoosePlanPage({required this.session, required this.current, super.key});

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  late bool _yearly = widget.current.interval == 'YEARLY';
  String? _busyPlan;

  Future<void> _choose(PlanSpec spec) async {
    final current = widget.current;

    if (spec.code == 'FREE') {
      final over = current.peopleCount > planSpecOf('FREE').maxPeople;
      final confirmed = await showFAppDialog<bool>(
        context: context,
        title: 'Switch to Free?',
        bodyText: over
            ? 'The workspace goes back to ${spec.maxPeople} people. You have ${current.peopleCount}, so nobody is '
                  'removed, but new sign-ups pause until you are under the limit.'
            : 'The workspace goes back to ${spec.maxPeople} people and loses the Pro features.',
        actions: [
          FButton(variant: .ghost, onPress: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FButton(onPress: () => Navigator.of(context).pop(true), child: const Text('Switch to Free')),
        ],
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _busyPlan = spec.code);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final updated = await ApiClient.changePlan(
        token: widget.session.token,
        adminId: widget.session.userId,
        plan: spec.code,
        yearly: _yearly,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            spec.code == 'FREE'
                ? 'Switched to Free'
                : updated.trialUsed && current.onTrial
                ? 'Switched to ${spec.name}'
                : '${spec.name} trial started — ${updated.trialLengthDays} days, no card needed',
          ),
        ),
      );
      navigator.pop(updated);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busyPlan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, size: 22, color: kPlanBlue),
                          Text(
                            'Plan & billing',
                            style: typography.body.md.copyWith(color: kPlanBlue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Choose a plan', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Prices in AUD. Change or cancel anytime.',
                  style: typography.body.sm.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: 16),
                SegmentedPills(
                  labels: const ['Monthly', 'Yearly · 2 months free'],
                  weights: const [2, 3],
                  selected: _yearly ? 1 : 0,
                  onChanged: (i) => setState(() => _yearly = i == 1),
                ),
                const SizedBox(height: 16),
                for (final spec in kPlanSpecs) ...[
                  _PlanCard(
                    spec: spec,
                    yearly: _yearly,
                    isCurrent: widget.current.plan == spec.code,
                    trialAvailable: !widget.current.trialUsed,
                    busy: _busyPlan == spec.code,
                    disabled: _busyPlan != null,
                    onChoose: () => _choose(spec),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanSpec spec;
  final bool yearly;
  final bool isCurrent;
  final bool trialAvailable;
  final bool busy;
  final bool disabled;
  final VoidCallback onChoose;

  const _PlanCard({
    required this.spec,
    required this.yearly,
    required this.isCurrent,
    required this.trialAvailable,
    required this.busy,
    required this.disabled,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final free = spec.code == 'FREE';
    final pro = spec.code == 'PRO';

    final price = yearly ? spec.yearly : spec.monthly;
    final unit = free ? 'forever' : (yearly ? '/year' : '/month');
    final alt = free
        ? 'Up to ${spec.maxPeople} people'
        : 'Up to ${spec.maxPeople} people · or ${yearly ? '\$${spec.monthly}/month' : '\$${spec.yearly}/year'}';

    final String buttonLabel;
    if (free) {
      buttonLabel = 'Switch to Free';
    } else if (trialAvailable) {
      buttonLabel = pro ? 'Start 30-day free trial' : 'Start ${spec.name} trial';
    } else {
      buttonLabel = 'Choose ${spec.name}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCurrent ? kPlanBlue.withValues(alpha: 0.1) : colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrent ? kPlanBlue.withValues(alpha: 0.7) : colors.border, width: isCurrent ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.name.toUpperCase(),
                  style: typography.body.md.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
              ),
              if (isCurrent)
                const PlanBadge('Current plan', filled: false)
              else if (!free && trialAvailable)
                const PlanBadge('30-day free trial'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('\$$price', style: typography.display.xl3.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text(unit, style: typography.body.md.copyWith(color: colors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 6),
          Text(alt, style: typography.body.sm.copyWith(color: colors.mutedForeground)),
          const SizedBox(height: 14),
          if (spec.intro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(spec.intro!, style: typography.body.sm.copyWith(color: colors.mutedForeground)),
            ),
          for (final feature in spec.features) CheckLine(feature),
          if (!isCurrent) ...[
            const SizedBox(height: 14),
            FButton(
              variant: (!free && pro) ? .primary : .outline,
              onPress: disabled ? null : onChoose,
              child: busy ? const FCircularProgress(size: .xs) : Text(buttonLabel),
            ),
            if (!free && trialAvailable) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'No card needed to start',
                  style: typography.body.xs.copyWith(color: colors.mutedForeground),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
