import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

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

  String get _initials {
    final trimmed = widget.session.fullName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : trimmed.length).toUpperCase();
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

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
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
    final session = widget.session;
    final hasPhoto = session.photoUrl != null && session.photoUrl!.isNotEmpty;
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              width: 84,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colors.primary,
                image: hasPhoto
                    ? DecorationImage(image: NetworkImage(session.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              alignment: Alignment.center,
              child: hasPhoto
                  ? null
                  : Text(
                      _initials,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryForeground,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              session.fullName,
              textAlign: TextAlign.center,
              style: typography.display.lg,
            ),
            const SizedBox(height: 6),
            Text(
              '${session.address} · ${session.industry}',
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
                  session.organizationId,
                  mono: true,
                  onTap: () => _copy(context, session.organizationId),
                ),
                _pill(context, session.userType),
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
            FutureBuilder<WorkspaceProfile>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: typography.body.sm.copyWith(color: colors.error),
                        ),
                        const SizedBox(height: 8),
                        FButton(
                          variant: .outline,
                          size: .sm,
                          onPress: _refresh,
                          child: const Text('Дахин оролдох'),
                        ),
                      ],
                    ),
                  );
                }

                final profile = snapshot.data!;
                return Column(
                  children: [
                    _detailRow(context, 'ABN', profile.abn),
                    FDivider(style: .delta(color: colors.border)),
                    _detailRow(context, 'Address', profile.address),
                    FDivider(style: .delta(color: colors.border)),
                    _detailRow(context, 'Phone', profile.phone),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
