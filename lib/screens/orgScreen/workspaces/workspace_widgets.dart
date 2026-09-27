import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_parts.dart';

/// The rounded square with a workspace's first two letters, in one of three rotating colours.
class WorkspaceMark extends StatelessWidget {
  final String name;
  final int index;
  final double size;
  const WorkspaceMark({required this.name, required this.index, this.size = 36, super.key});

  static const _palette = [kPlanBlue, kPlanGreen, kPlanAmber];

  String get _letters {
    final compact = name.replaceAll(RegExp(r'\s'), '');
    return compact.isEmpty ? '?' : compact.substring(0, compact.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: _palette[index % _palette.length], borderRadius: BorderRadius.circular(9)),
    child: Text(
      _letters,
      style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w900, color: kPlanInk),
    ),
  );
}

/// One workspace as a tappable row: mark, name, "City · N people" and a trailing widget.
class WorkspaceRow extends StatelessWidget {
  final WorkspaceSummary workspace;
  final int index;

  /// The workspace the admin has open right now — outlined in the accent colour.
  final bool current;

  /// Replaces the default subtitle (city and people count).
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const WorkspaceRow({
    required this.workspace,
    required this.index,
    this.current = false,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final city = workspace.city;
    final people = '${workspace.peopleCount} ${workspace.peopleCount == 1 ? 'person' : 'people'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: current ? kPlanBlue.withValues(alpha: 0.1) : colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: current ? kPlanBlue.withValues(alpha: 0.7) : colors.border,
              width: current ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              WorkspaceMark(name: workspace.businessName, index: index),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workspace.businessName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.md.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? (city.isEmpty ? people : '$city · $people'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill: the accent one for "Active" / "Current", a tinted one for warnings.
class WorkspacePill extends StatelessWidget {
  final String text;
  final Color? tint;
  const WorkspacePill(this.text, {this.tint, super.key});

  @override
  Widget build(BuildContext context) {
    final color = tint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color == null ? kPlanBlue : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: context.theme.typography.body.xs.copyWith(
          color: color ?? kPlanInk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// What needs attention in a workspace this pay period, as a single pill (or "All clear").
class WorkspaceAttentionPill extends StatelessWidget {
  final WorkspaceSummary workspace;
  const WorkspaceAttentionPill(this.workspace, {super.key});

  @override
  Widget build(BuildContext context) {
    final unpaid = workspace.unpaidCount;
    final missing = workspace.missingLogCount;
    if (unpaid == null || missing == null) return const SizedBox.shrink();
    if (unpaid > 0) return WorkspacePill('$unpaid unpaid', tint: const Color(0xFFE08277));
    if (missing > 0) {
      return WorkspacePill('$missing missing ${missing == 1 ? 'log' : 'logs'}', tint: const Color(0xFFE08277));
    }
    return const WorkspacePill('All clear', tint: kPlanGreen);
  }
}
