import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'screens/landing_page.dart';
import 'theme/theme.dart';
import 'theme/theme_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, dark, _) {
        final foruiTheme = dark ? darkTheme : lightTheme;
        return MaterialApp(
          title: 'MK Roster',
          debugShowCheckedModeBanner: false,
          theme: foruiTheme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(
            data: foruiTheme,
            child: child!,
          ),
          home: const LandingPage(),
        );
      },
    );
  }
}
