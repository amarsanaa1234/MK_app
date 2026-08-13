import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

class OrgHomePage extends StatelessWidget {
  final AuthResult session;
  const OrgHomePage({required this.session, super.key});

  @override
  Widget build(BuildContext _) =>
      Column(
        mainAxisAlignment: .center,
        children: [
          Padding(
            padding: const .all(16),
            child: FTabs(
              children: [
                .entry(
                  label: const Text('Dayly Work List'),
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        OrgCard(
                          session: session,
                          title: const Text('Notifications'),
                          subtitle: const Text('ene bol mon'),
                          child: FButton(onPress: () {}, child: const Text('ene bol mon')),
                        ),
                      ],
                    )
                  ),
                .entry(
                  label: const Text('Test'),
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    children: [
                      OrgCard(
                        session: session,
                        title: const Text('Notifications'),
                        subtitle: const Text('Test'),
                        child: FButton(onPress: () {}, child: const Text('Test as read')),
                      ),
                    ],
                  )
                ),
              ],
            ),
          ),
        ],
  );
}

class OrgCard extends StatelessWidget {
  final AuthResult session;
  final Widget title;
  final Widget subtitle;
  final Widget child;

  const OrgCard({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    required this.session
  });

  @override
  Widget build(BuildContext context) {
    final style = context.theme.cardStyle;
    return FCard(
      style: style,
      child: Padding(
        padding: style.padding,
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            DefaultTextStyle.merge(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: style.titleTextStyle,
              child: title,
            ),
            const SizedBox(height: 2),
            DefaultTextStyle.merge(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: style.subtitleTextStyle,
              child: subtitle,
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}