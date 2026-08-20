import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/landing_page.dart';
import 'package:mk_app/screens/orgScreen/org_home_page/org_home_page.dart';
import 'package:mk_app/screens/orgScreen/org_profile/org_profile.dart';
import 'package:mk_app/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Header extends StatelessWidget {
  final AuthResult session;
  const Header({super.key, required this.session});

  @override
  Widget build(BuildContext context) {

    Future<void> logout(BuildContext context) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!context.mounted) return;
      // Бүх өмнөх screen-ийг цэвэрлээд Landing page руу буцаах
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
            (route) => false,
      );
    }

    return FHeader(
        title: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi ${session.fullName}',
                style: context.theme.typography.display.lg,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF232830),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MK Removals · Sydney',
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      suffixes: [
        FHeaderAction(
          icon: FAvatar.raw(
            style: const .delta(backgroundColor: Color(0xFF2E609A)),
            child: const Text('MN'),
          ),
          onPress: () => showFSheet(
            context: context,
            side: .ltr,
            builder: (context) => DecoratedBox(
              decoration: BoxDecoration(color: context.theme.colors.background),
              child: FSidebar(
                style: const .delta(
                  constraints: BoxConstraints(minWidth: 300, maxWidth: 300),
                ),
                footer: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                  color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrgProfile(session: session)),
                        );
                      },
                      child: FCard(
                        child: Padding(
                          padding: const .symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            spacing: 10,
                            children: [
                              FAvatar.raw(
                                child: Icon(
                                  FLucideIcons.userRound,
                                  size: 18,
                                  color: context.theme.colors.mutedForeground,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: .start,
                                  spacing: 2,
                                  children: [
                                    Text(
                                      'Dash',
                                      style: context.theme.typography.body.sm.copyWith(
                                        fontWeight: .bold,
                                        color: context.theme.colors.foreground,
                                      ),
                                      overflow: .ellipsis,
                                    ),
                                    Text(
                                      'dash@forui.dev',
                                      style: context.theme.typography.body.xs.copyWith(
                                        color: context.theme.colors.mutedForeground,
                                      ),
                                      overflow: .ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                ),
                children: [
                  FSidebarGroup(
                    label: const Text('Home '),
                    children: [
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.school),
                        label: const Text('Getting Started'),
                        initiallyExpanded: true,
                        onPress: () {},
                        children: [
                          FSidebarItem(
                            label: const Text('Empoyees'),
                            onPress: () {},
                          ),
                          FSidebarItem(label: const Text('Payroll'), onPress: () {}),
                          FSidebarItem(
                            label: const Text('Timesheets'),
                            onPress: () {},
                          ),
                        ],
                      ),
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.box),
                        label: const Text('My roster'),
                        onPress: () {},
                      ),
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.code),
                        label: const Text('Pay rates'),
                        onPress: () {},
                      ),
                    ],
                  ),
                  FSidebarGroup(
                    label: const Text('Widgets'),
                    children: [
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.circleSlash),
                        label: const Text('Post a job'),
                        // selected: true,
                        onPress: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrgHomePage(session: session)),
                        ),
                      ),
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.scaling),
                        label: const Text('Organizations'),
                        onPress: () {},
                      ),
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.layoutDashboard),
                        label: const Text('Dashbourd'),
                        onPress: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(FLucideIcons.moon, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dark mode',
                                style: context.theme.typography.body.sm.copyWith(
                                  color: context.theme.colors.foreground,
                                ),
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: isDarkModeNotifier,
                              builder: (context, dark, _) => FSwitch(
                                value: dark,
                                onChange: (value) => isDarkModeNotifier.value = value,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FSidebarItem(
                        icon: const Icon(FLucideIcons.layoutDashboard),
                        label: const Text('Log out'),
                        onPress: () => logout(context)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}