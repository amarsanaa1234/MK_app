import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../widgets/brand_logo.dart';
import 'join_workspace_page.dart';
import 'login_page.dart';
import 'setup_workspace_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

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
                  const BrandLogo(height: 72),
                  const SizedBox(height: 20),
                  const SizedBox(height: 40),
                  FButton(
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text('Log in'),
                  ),
                  const SizedBox(height: 12),
                  FButton(
                    variant: .outline,
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JoinWorkspacePage()),
                    ),
                    child: const Text('Create an account'),
                  ),
                  const SizedBox(height: 24),
                  FButton(
                    variant: .ghost,
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SetupWorkspacePage()),
                    ),
                    child: const Flexible(
                      child: Text(
                        'Registering a business? Set up a workspace',
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
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
