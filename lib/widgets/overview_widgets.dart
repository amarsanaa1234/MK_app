import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// One figure in a [StatStrip] — a big value over a small caps label.
class StatItem {
  final String value;
  final String label;
  final Color? valueColor;
  final VoidCallback? onTap;

  const StatItem({required this.value, required this.label, this.valueColor, this.onTap});
}

/// A rounded strip of side-by-side figures separated by hairlines, used at
/// the top of the Employees list and an employee's detail page.
class StatStrip extends StatelessWidget {
  final List<StatItem> items;
  const StatStrip({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: colors.border),
              Expanded(
                child: InkWell(
                  onTap: items[i].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            items[i].value,
                            style: typography.display.xl.copyWith(
                              fontWeight: FontWeight.w800,
                              color: items[i].valueColor ?? colors.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          overflow: TextOverflow.ellipsis,
                          style: typography.body.xs2.copyWith(
                            color: colors.mutedForeground,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
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

/// A segmented pill toggle ("All · 16 / Crew · 14 / Admins · 2").
class SegmentedPills extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Relative widths of the segments (all equal when omitted).
  final List<int>? weights;

  const SegmentedPills({
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.weights,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: weights?[i] ?? 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == selected ? colors.background : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: i == selected ? colors.foreground : colors.mutedForeground,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
