import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/choose_plan_page.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_parts.dart';
import 'package:mk_app/widgets/app_dialog.dart';

/// Admin-only: the workspace's plan, how much of it is used, and payment.
/// A workspace on the Free plan has no plan card and nothing to pay, so those
/// parts are left out and the page is just usage plus a way to upgrade.
class PlanBillingPage extends StatefulWidget {
  final AuthResult session;
  const PlanBillingPage({required this.session, super.key});

  @override
  State<PlanBillingPage> createState() => _PlanBillingPageState();
}

class _PlanBillingPageState extends State<PlanBillingPage> {
  late Future<PlanInfo> _future;
  late final Future<WorkspaceProfile> _workspaceFuture;

  @override
  void initState() {
    super.initState();
    _workspaceFuture = ApiClient.getMyWorkspace(widget.session.token);
    _load();
  }

  void _load() {
    _future = ApiClient.getPlan(token: widget.session.token, adminId: widget.session.userId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _changePlan(PlanInfo plan) async {
    final updated = await Navigator.of(context).push<PlanInfo>(
      MaterialPageRoute(builder: (_) => ChoosePlanPage(session: widget.session, current: plan)),
    );
    if (updated != null && mounted) await _refresh();
  }

  Future<void> _addPaymentMethod() => showFAppDialog<void>(
    context: context,
    title: 'Add payment method',
    bodyText:
        'Card payments are not connected yet. For now a paid plan runs as a free trial, '
        'and the workspace returns to Free when it ends.',
    actions: [FButton(variant: .ghost, onPress: () => Navigator.of(context).pop(), child: const Text('Close'))],
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FutureBuilder<PlanInfo>(
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
        final plan = snapshot.data!;
        final spec = planSpecOf(plan.plan);

        Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(
            text,
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text('Plan & billing', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              FutureBuilder<WorkspaceProfile>(
                future: _workspaceFuture,
                builder: (context, ws) => Text(
                  '${ws.data?.businessName ?? ''}${plan.isFree ? ' · Free plan' : ''}',
                  style: typography.body.md.copyWith(color: colors.mutedForeground),
                ),
              ),
              const SizedBox(height: 16),

              if (!plan.isFree) _PlanCard(plan: plan, spec: spec),

              if (plan.lapsed) ...[
                const NoticeBox(
                  child: Text(
                    'Your trial ended without a payment method, so the workspace is back on Free. '
                    'Nobody was removed — new sign-ups pause until you are under the limit.',
                  ),
                ),
              ],

              sectionLabel('USAGE'),
              _UsageRow(label: 'People', value: '${plan.peopleCount} of ${plan.maxPeople}', bar: UsageBar(value: plan.peopleCount, max: plan.maxPeople)),
              _UsageRow(
                label: 'Workspaces',
                value: '${plan.workspacesUsed} of ${plan.maxWorkspaces}',
                bar: UsageBar(value: plan.workspacesUsed, max: plan.maxWorkspaces),
              ),
              _UsageRow(
                label: 'Admins',
                value: '${plan.adminCount} · multiple admins ${plan.multipleAdmins ? 'on' : 'off'}',
              ),

              if (!plan.isFree) ...[
                sectionLabel('PAYMENT'),
                _KeyValueRow(label: 'Payment method', value: plan.paymentMethodAdded ? 'On file' : 'Not added', boldValue: true),
                if (plan.onTrial && plan.trialEndsOn != null)
                  _KeyValueRow(
                    label: 'First charge',
                    value:
                        '\$${(plan.interval == 'YEARLY' ? plan.yearlyPrice : plan.monthlyPrice).toStringAsFixed(2)}'
                        ' on ${DateFormat('dd MMM').format(plan.trialEndsOn!)}',
                  ),
                if (plan.onTrial && plan.trialEndsOn != null) ...[
                  const SizedBox(height: 16),
                  NoticeBox(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'No card by ${DateFormat('dd MMM').format(plan.trialEndsOn!)}? '),
                          TextSpan(
                            text: 'The workspace returns to Free (${planSpecOf('FREE').maxPeople} people). ',
                          ),
                          const TextSpan(text: 'Nobody is removed', style: TextStyle(fontWeight: FontWeight.w800)),
                          const TextSpan(text: ' — new sign-ups pause until you\'re under the limit.'),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FButton(onPress: _addPaymentMethod, child: const Text('Add payment method')),
                const SizedBox(height: 10),
                FButton(variant: .outline, onPress: () => _changePlan(plan), child: const Text('Change plan')),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Secure checkout opens in your browser.',
                    style: typography.body.xs.copyWith(color: colors.mutedForeground),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                FButton(onPress: () => _changePlan(plan), child: const Text('See plans & upgrade')),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The top card: plan name, trial badge, price and how far through the trial we are.
class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final PlanSpec spec;
  const _PlanCard({required this.plan, required this.spec});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final yearly = plan.interval == 'YEARLY';
    final elapsed = plan.trialLengthDays - plan.trialDaysLeft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.name.toUpperCase(),
                  style: typography.body.lg.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
              ),
              if (plan.onTrial) PlanBadge('Trial · ${plan.trialDaysLeft} days left'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${yearly ? plan.yearlyPrice : plan.monthlyPrice}',
                style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${yearly ? '/year' : '/month'}${plan.onTrial ? ' after the trial' : ''}',
                  style: typography.body.md.copyWith(color: colors.mutedForeground),
                ),
              ),
            ],
          ),
          if (plan.onTrial && plan.trialEndsOn != null) ...[
            const SizedBox(height: 12),
            UsageBar(value: elapsed, max: plan.trialLengthDays),
            const SizedBox(height: 10),
            Text(
              'Trial ends ${DateFormat('dd MMM yyyy').format(plan.trialEndsOn!)} · cancel anytime',
              style: typography.body.sm.copyWith(color: colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? bar;
  const _UsageRow({required this.label, required this.value, this.bar});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: typography.body.md.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: typography.body.md.copyWith(color: colors.mutedForeground),
                ),
              ),
            ],
          ),
          if (bar != null) ...[const SizedBox(height: 10), bar!],
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;
  const _KeyValueRow({required this.label, required this.value, this.boldValue = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Text(label, style: typography.body.md.copyWith(color: colors.mutedForeground)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: typography.body.md.copyWith(fontWeight: boldValue ? FontWeight.w800 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
