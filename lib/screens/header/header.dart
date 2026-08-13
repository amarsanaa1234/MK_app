import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

class Header extends StatelessWidget {
  final AuthResult session;
  const Header({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;

    return FHeader(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hi ${session.fullName}',
            style: context.theme.typography.display.lg,
          ),
          Text(
            // fixing 1 there is seeing emp & Org location
            'MK Removals · Sydney',
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
      suffixes: [
        // ValueListenableBuilder<bool>(
        //   valueListenable: isDarkModeNotifier,
        //   builder: (context, dark, _) => FSwitch(
        //     value: dark,
        //     onChange: (value) => isDarkModeNotifier.value = value,
        //   ),
        // ),
        FHeaderAction(
          icon: FAvatar.raw(
            style: const .delta(backgroundColor: Color(0xFF2E609A)),
            child: const Text('MN'),
          ),
          onPress: () {},
        ),
      ],
    );
  }
}