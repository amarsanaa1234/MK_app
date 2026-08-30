
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

import 'org_sheet.dart';

class OrgHomePage extends StatelessWidget {
  final AuthResult session;
  const OrgHomePage({required this.session, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton(
      onPressed: () => openNewPostSheet(context, session),
      backgroundColor: context.theme.colors.primary,
      foregroundColor: context.theme.colors.primaryForeground,
      child: const Icon(Icons.add),
    ),
    body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: FTabs(
            expands: true,
            children: [
                  .entry(
                label: const Text('Dayly Work List'),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrgCard(
                        session: session,
                        date: const Text('Today · Mon 10 Aug'),
                        address: '10 Footbridge Bvd, Wentworth Point NSW 2127',
                        description: const Text("08:30 · Office relocation · you're leading"),
                        employees: const AvatarGroup(
                          initials: ['AP', 'DM'],
                          label: Text('with Alofa P., Deng M.'),
                        ),
                        status: true,
                      ),
                    ),
                  ],
                ),
              ),
                  .entry(
                label: const Text('Test'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrgCard(
                      session: session,
                      date: const Text('Today · Mon 10 Aug text'),
                      address: '220 George St, Sydney text',
                      description: const Text("08:30 · Office relocation · you're leading text"),
                      employees: const AvatarGroup(
                        initials: ['AP', 'DM'],
                        label: Text('with Alofa P., Deng M.'),
                      ),
                      status: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
    ),
  );
}

class OrgCard extends StatelessWidget {
  final AuthResult session;
  final Widget date;
  final String address;
  final Widget description;
  final Widget employees;
  final bool status;
  // final Widget child;

  const OrgCard({
    required this.date,
    required this.address,
    required this.description,
    required this.employees,
    required this.status,
    // required this.child,
    super.key,
    required this.session
  });

  Future<void> _openDirections(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final style = context.theme.cardStyle;
    return FCard(
      style: style,
      child: Padding(
        padding: style.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DefaultTextStyle.merge(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF8AA1C2),
                fontWeight: FontWeight.bold,
              ),
              child: date,
            ),
            const SizedBox(height: 2),
            DefaultTextStyle.merge(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              child: Text('${address}'),
            ),
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                color: const Color(0xFF5C6572),
              ),
              child: description,
            ),
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: style.subtitleTextStyle,
              child: employees,
            ),
            const SizedBox(height: 6),
            FButton(
              onPress: () => _openDirections(address),
              child: const Text('Get directions'),
            )
          ],
        ),
      ),
    );
  }
}

class AvatarGroup extends StatelessWidget {
  final List<String> initials;
  final Widget label;
  final double size;
  final double overlap;

  const AvatarGroup({
    required this.initials,
    required this.label,
    this.size = 24,
    this.overlap = 14,
    super.key,
  });

  static const _colors = [
    Color(0xFF3F6B46),
    Color(0xFF2E4E72),
    Color(0xFFB5651D),
    Color(0xFFA23327),
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: size + overlap * (initials.length - 1),
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < initials.length; i++)
              Positioned(
                left: overlap * i,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _colors[i % _colors.length],
                    border: Border.all(color: const Color(0xFF181C22), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials[i],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      DefaultTextStyle.merge(style: const TextStyle(fontSize: 13), child: label),
    ],
  );
}