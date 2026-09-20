import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

/// The organization's own card — business details, org ID, and crew/admin
/// counts. Separate from the signed-in user's personal profile.
class OrgProfile extends StatefulWidget {
  final AuthResult session;
  const OrgProfile({super.key, required this.session});

  @override
  State<OrgProfile> createState() => _OrgProfileState();
}

class _OrgProfileState extends State<OrgProfile> {
  late Future<WorkspaceProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.getMyWorkspace(widget.session.token);
  }

  Future<void> _refresh() {
    final future = ApiClient.getMyWorkspace(widget.session.token);
    setState(() => _future = future);
    return future;
  }

  void _copy(BuildContext context, String text, {String message = 'Copied'}) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _editComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing business details is coming soon')),
    );
  }

  Widget _pill(BuildContext context, String text, {bool mono = false, VoidCallback? onTap}) {
    final colors = context.theme.colors;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.copy, size: 12, color: colors.mutedForeground),
          ],
        ],
      ),
    );

    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }

  Widget _detailRow(BuildContext context, String label, String? value) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final labelStyle = typography.body.xs.copyWith(
      color: colors.mutedForeground,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: labelStyle),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? '—' : value,
              textAlign: TextAlign.end,
              style: typography.body.sm.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: FutureBuilder<WorkspaceProfile>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: FCircularProgress(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: typography.body.sm.copyWith(color: colors.error),
                    ),
                    const SizedBox(height: 8),
                    FButton(variant: .outline, size: .sm, onPress: _refresh, child: const Text('Retry')),
                  ],
                ),
              );
            }

            final profile = snapshot.data!;
            final subtitle = [
              if (profile.address != null && profile.address!.isNotEmpty) profile.address,
              if (profile.industry != null && profile.industry!.isNotEmpty) profile.industry,
            ].join(' · ');

            return Column(
              mainAxisSize: MainAxisSize.min,
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
                    profile.businessName.isEmpty ? '?' : profile.businessName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryForeground,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(profile.businessName, textAlign: TextAlign.center, style: typography.display.lg),
                const SizedBox(height: 6),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(
                      context,
                      profile.organizationId,
                      mono: true,
                      onTap: () => _copy(context, profile.organizationId),
                    ),
                    _pill(context, '${profile.crewCount} crew · ${profile.adminCount} admins'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'BUSINESS DETAILS',
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: FDivider(style: .delta(color: colors.border))),
                  ],
                ),
                const SizedBox(height: 8),
                _detailRow(context, 'ABN', profile.abn),
                FDivider(style: .delta(color: colors.border)),
                _detailRow(context, 'Address', profile.address),
                FDivider(style: .delta(color: colors.border)),
                _detailRow(context, 'Phone', profile.phone),
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  child: FButton(
                    variant: .outline,
                    onPress: () => _editComingSoon(context),
                    child: const Text('Edit business details'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 280,
                  child: FButton(
                    onPress: () => _copy(
                      context,
                      profile.organizationId,
                      message: 'Org ID copied — share it with new hires',
                    ),
                    child: const Text('Invite crew · share Org ID'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
