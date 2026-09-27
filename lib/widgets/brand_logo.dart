import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

/// The muster wordmark logo, in the light or dark variant to match the app theme.
class BrandLogo extends StatelessWidget {
  final double height;
  const BrandLogo({this.height = 64, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, dark, _) => Image.asset(
        dark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'muster',
      ),
    );
  }
}
