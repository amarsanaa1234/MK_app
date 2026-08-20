import 'package:flutter/material.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/theme/app_theme.dart';

/// Profile body content. Rendered inside the persistent app shell's body
/// area (see HomePage) — it has no Scaffold/Header of its own.
class OrgProfile extends StatelessWidget {
  final AuthResult session;
  const OrgProfile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            Text('MK Roster', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Crew schedules and timesheets,\nin one place.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
