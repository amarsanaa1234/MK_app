import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/theme/app_theme.dart';

class OrgProfile extends StatelessWidget {
  final AuthResult session;
  const OrgProfile({super.key, required this.session});

  String get _initials {
    final trimmed = session.fullName.trim();
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto = session.photoUrl != null && session.photoUrl!.isNotEmpty;

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
                color: AppColors.accent,
                image: hasPhoto
                    ? DecorationImage(image: NetworkImage(session.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              alignment: Alignment.center,
              child: hasPhoto
                  ? null
                  : Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentText,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              session.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.address} · ${session.industry}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.theme.colors.mutedForeground),
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
          ],
        ),
      ),
    );
  }
}