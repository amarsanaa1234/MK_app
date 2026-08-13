import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/screens/header/header.dart';
import 'package:mk_app/screens/orgScreen/org_home_page/org_home_page.dart';

import '../api/api_client.dart';
import 'landing_page.dart';

class HomePage extends StatelessWidget {
  final AuthResult session;

  const HomePage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    print('sda-giin data =>>>>>>>> ${session.userType}');

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
                        OrgHomePage(session: session),
                        // const SizedBox(height: 8),
                        // Text(
                        //   '${session.userType} · ${session.organizationId}',
                        //   style: typography.body.sm.copyWith(color: colors.mutedForeground),
                        // ),
                        // const SizedBox(height: 32),
                        // FButton(
                        //   variant: .outline,
                        //   onPress: () => Navigator.of(context).pushAndRemoveUntil(
                        //     MaterialPageRoute(builder: (_) => const LandingPage()),
                        //     (route) => false,
                        //   ),
                        //   child: const Text('Log out'),
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
