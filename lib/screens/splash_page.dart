import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import 'landing_page.dart';

/// Full-screen branded splash, in the light or dark artwork to match the app
/// theme, shown briefly before the landing page.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => const LandingPage(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, dark, _) => Scaffold(
        backgroundColor: dark ? const Color(0xFF1B1E23) : const Color(0xFFF4F4F2),
        body: SizedBox.expand(
          child: Image.asset(
            dark ? 'assets/images/splash_dark.png' : 'assets/images/splash_light.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
