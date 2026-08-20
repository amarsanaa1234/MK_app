import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/header/header.dart';
import 'package:mk_app/theme/app_theme.dart';

class OrgProfile extends StatelessWidget {
  final AuthResult session;
  const OrgProfile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(session: session),
            Expanded(
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
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'M',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'MK Roster',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crew schedules and timesheets,\nin one place.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                        ),
                        // const SizedBox(height: 40),
                        // FilledButton(
                        //   onPressed: () => Navigator.of(context).push(
                        //     MaterialPageRoute(builder: (_) => const LoginPage()),
                        //   ),
                        //   child: const Text('Log in'),
                        // ),
                        const SizedBox(height: 12),
                        // OutlinedButton(
                        //   onPressed: () => Navigator.of(context).push(
                        //     MaterialPageRoute(builder: (_) => const JoinWorkspacePage()),
                        //   ),
                        //   child: const Text('Create an account'),
                        // ),
                        const SizedBox(height: 24),
                        // TextButton(
                        //   onPressed: () => Navigator.of(context).push(
                        //     MaterialPageRoute(builder: (_) => const SetupWorkspacePage()),
                        //   ),
                        //   child: const Text(
                        //     'Registering a business? Set up a workspace',
                        //     textAlign: TextAlign.center,
                        //     style: TextStyle(fontWeight: FontWeight.w600),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
