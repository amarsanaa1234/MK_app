import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

const kPlanAmber = Color(0xFFE0964F);
const kPlanGreen = Color(0xFF3FB27F);
const kPlanBlue = Color(0xFF7FA1CC);
const kPlanInk = Color(0xFF1B2127);

/// What a plan looks like on the pricing screens. The limits themselves are
/// enforced by the backend (`PlanTier`); this is the copy shown to people.
class PlanSpec {
  final String code;
  final String name;
  final int monthly;
  final int yearly;
  final int maxPeople;
  final String? intro;
  final List<String> features;

  /// A tighter version of [features] for the "upgrade adds" list, when it reads better merged.
  final List<String>? upgradeFeatures;

  const PlanSpec({
    required this.code,
    required this.name,
    required this.monthly,
    required this.yearly,
    required this.maxPeople,
    this.intro,
    required this.features,
    this.upgradeFeatures,
  });

  /// What upgrading to this plan adds over the one below it.
  List<String> get additions => ['Up to $maxPeople people', ...(upgradeFeatures ?? features)];
}

const kPlanSpecs = [
  PlanSpec(
    code: 'FREE',
    name: 'Free',
    monthly: 0,
    yearly: 0,
    maxPeople: 10,
    features: ['1 workspace', 'Roster', 'Timesheets'],
  ),
  PlanSpec(
    code: 'PRO',
    name: 'Pro',
    monthly: 19,
    yearly: 190,
    maxPeople: 30,
    intro: 'Everything in Free, plus',
    features: ['Payroll calculator', 'Export', 'Notifications', 'Multiple admins'],
    upgradeFeatures: ['Payroll calculator & export', 'Notifications', 'Multiple admins'],
  ),
  PlanSpec(
    code: 'BUSINESS',
    name: 'Business',
    monthly: 49,
    yearly: 490,
    maxPeople: 100,
    intro: 'Everything in Pro, plus',
    features: ['Up to 5 workspaces', 'Priority support'],
  ),
];

PlanSpec planSpecOf(String code) => kPlanSpecs.firstWhere((p) => p.code == code, orElse: () => kPlanSpecs.first);

/// The next plan up from [code], or null when it is already the top one.
PlanSpec? nextPlanAfter(String code) {
  final index = kPlanSpecs.indexWhere((p) => p.code == code);
  return index >= 0 && index < kPlanSpecs.length - 1 ? kPlanSpecs[index + 1] : null;
}

/// A slim usage bar — turns amber once the limit is reached.
class UsageBar extends StatelessWidget {
  final num value;
  final num max;
  const UsageBar({required this.value, required this.max, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    final full = max > 0 && value >= max;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        children: [
          Container(height: 6, color: colors.secondary),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(height: 6, color: full ? kPlanAmber : kPlanBlue),
          ),
        ],
      ),
    );
  }
}

/// An amber callout box for limits and warnings.
class NoticeBox extends StatelessWidget {
  final Widget child;
  const NoticeBox({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kPlanAmber.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kPlanAmber.withValues(alpha: 0.45)),
    ),
    child: DefaultTextStyle.merge(
      style: context.theme.typography.body.sm.copyWith(color: context.theme.colors.foreground, height: 1.4),
      child: child,
    ),
  );
}

/// A green check followed by a feature line.
class CheckLine extends StatelessWidget {
  final String text;
  const CheckLine(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(FLucideIcons.check, size: 16, color: kPlanGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.theme.typography.body.md)),
      ],
    ),
  );
}

/// Small filled pill used for "Current plan" / "30-day free trial" / "Trial · 23 days left".
class PlanBadge extends StatelessWidget {
  final String text;
  final bool filled;
  const PlanBadge(this.text, {this.filled = true, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? kPlanBlue : colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: context.theme.typography.body.xs.copyWith(
          color: filled ? kPlanInk : colors.mutedForeground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
