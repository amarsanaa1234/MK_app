import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Shows a forui-styled dialog with a title, optional body text/widget, and a
/// row of actions — used for notes and other one-off alerts/prompts so every
/// modal in the app shares the same look instead of mixing in Material's
/// stock [AlertDialog].
Future<T?> showFAppDialog<T>({
  required BuildContext context,
  required String title,
  String? bodyText,
  Widget? body,
  required List<Widget> actions,
}) {
  return showFDialog<T>(
    context: context,
    builder: (context, style, animation) => FDialog(
      animation: animation,
      // forui's dialog route doesn't sit under a Material ancestor, but plain
      // Material-dependent widgets (TextField, InkWell, ...) are used freely
      // inside dialog bodies throughout the app — `transparency` supplies that
      // ancestor without painting a surface of its own.
      builder: (context, dialogStyle) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: dialogStyle.titleTextStyle),
              if (bodyText != null) ...[
                const SizedBox(height: 12),
                Text(bodyText, style: dialogStyle.bodyTextStyle),
              ],
              if (body != null) ...[const SizedBox(height: 12), body],
              // A body that carries its own buttons passes no actions.
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
