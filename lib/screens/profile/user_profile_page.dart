import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/landing_page.dart';
import 'package:mk_app/widgets/user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user's own profile — works for both Admin and Employee.
/// Separate from [OrgProfile], which is the business's own card.
class UserProfilePage extends StatefulWidget {
  final AuthResult session;
  const UserProfilePage({required this.session, super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.getMyProfile(widget.session.token);
  }

  Future<void> _refresh() {
    final future = ApiClient.getMyProfile(widget.session.token);
    setState(() => _future = future);
    return future;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  void _editComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing your profile is coming soon')),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: typography.body.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: FDivider(style: .delta(color: colors.border))),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String? value) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
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
        child: FutureBuilder<UserProfile>(
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
            final roleLabel = profile.userType == 'Admin' ? 'Admin' : 'Crew';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(fullName: profile.fullName, photoUrl: profile.photoUrl, size: 84),
                const SizedBox(height: 20),
                Text(profile.fullName, textAlign: TextAlign.center, style: typography.display.lg),
                const SizedBox(height: 6),
                Text(
                  roleLabel,
                  textAlign: TextAlign.center,
                  style: typography.body.sm.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: 24),
                _sectionLabel(context, 'Contact'),
                const SizedBox(height: 8),
                _detailRow(context, 'Email', profile.username),
                FDivider(style: .delta(color: colors.border)),
                _detailRow(context, 'Phone', profile.phone),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Employment'),
                const SizedBox(height: 8),
                _detailRow(
                  context,
                  'Started',
                  profile.createdAt == null ? null : DateFormat('d MMM yyyy').format(profile.createdAt!),
                ),
                if (profile.userType != 'Admin') ...[
                  FDivider(style: .delta(color: colors.border)),
                  _detailRow(
                    context,
                    'Pay rate',
                    profile.payRate == null ? 'Not set' : '\$${profile.payRate!.toStringAsFixed(2)}/h',
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  child: FButton(
                    variant: .outline,
                    onPress: () => _editComingSoon(context),
                    child: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 280,
                  child: FButton(
                    variant: .destructive,
                    onPress: () => _logout(context),
                    child: const Text('Log out'),
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
