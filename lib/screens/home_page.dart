import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import 'landing_page.dart';

class HomePage extends StatelessWidget {
  final AuthResult session;

  const HomePage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome, ${session.fullName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${session.userType} · ${session.organizationId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LandingPage()),
                      (route) => false,
                    ),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
