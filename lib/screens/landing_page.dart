import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'join_workspace_page.dart';
import 'login_page.dart';
import 'setup_workspace_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

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
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryForeground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('MK Roster', style: context.theme.typography.display.xl3),
                  const SizedBox(height: 12),
                  Text(
                    'Crew schedules and timesheets,\nin one place.',
                    textAlign: TextAlign.center,
                    style: context.theme.typography.body.sm.copyWith(color: colors.mutedForeground),
                  ),
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
