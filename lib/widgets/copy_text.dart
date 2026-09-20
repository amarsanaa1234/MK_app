import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// Puts [text] on the clipboard. Browsers can refuse clipboard access, so a
/// failure is reported back instead of thrown.
Future<bool> copyToClipboard(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (_) {
    return false;
  }
}

/// Tap-to-copy text: shows a small copy icon and, after a tap, briefly
/// confirms with a check (or says the copy didn't work). Feedback is inline so
/// it also works inside dialogs, where a snackbar would sit behind the barrier.
class CopyableText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Where the text sits when the widget is given more room than it needs.
  final MainAxisAlignment alignment;

  const CopyableText({required this.text, this.style, this.alignment = MainAxisAlignment.start, super.key});

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

enum _CopyState { idle, copied, failed }

class _CopyableTextState extends State<CopyableText> {
  _CopyState _state = _CopyState.idle;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final ok = await copyToClipboard(widget.text);
    if (!mounted) return;
    setState(() => _state = ok ? _CopyState.copied : _CopyState.failed);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _state = _CopyState.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final icon = switch (_state) {
      _CopyState.idle => FLucideIcons.copy,
      _CopyState.copied => FLucideIcons.check,
      _CopyState.failed => FLucideIcons.x,
    };
    final iconColor = switch (_state) {
      _CopyState.idle => colors.mutedForeground,
      _CopyState.copied => const Color(0xFF3FB27F),
      _CopyState.failed => colors.destructive,
    };

    return Tooltip(
      message: 'Copy',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _copy,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.alignment,
          children: [
            Flexible(
              child: Text(widget.text, overflow: TextOverflow.ellipsis, style: widget.style),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 14, color: iconColor),
            if (_state != _CopyState.idle) ...[
              const SizedBox(width: 4),
              Text(
                _state == _CopyState.copied ? 'Copied' : "Can't copy",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: iconColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
