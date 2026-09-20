import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_dialog.dart';

/// Asks for a person's hourly pay rate. Resolves to the new rate, or null when
/// cancelled or the text isn't a number.
///
/// The text field's controller lives inside the dialog's own State: disposing it
/// from the caller as soon as the dialog closes would pull it out from under the
/// field while the dialog is still animating away, which crashes the whole app.
Future<double?> showPayRateDialog({
  required BuildContext context,
  required String name,
  double? currentRate,
}) {
  return showFAppDialog<double>(
    context: context,
    title: '$name · pay rate',
    body: _PayRateForm(initial: currentRate),
    actions: const [],
  );
}

class _PayRateForm extends StatefulWidget {
  final double? initial;
  const _PayRateForm({this.initial});

  @override
  State<_PayRateForm> createState() => _PayRateFormState();
}

class _PayRateFormState extends State<_PayRateForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == null ? '' : widget.initial!.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: r'$', suffixText: '/h'),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FButton(variant: .ghost, onPress: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            const SizedBox(width: 8),
            FButton(
              onPress: () => Navigator.of(context).pop(double.tryParse(_controller.text.trim())),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
