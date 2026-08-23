import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto = session.photoUrl != null && session.photoUrl!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.accent,
                image: hasPhoto ? DecorationImage(image: NetworkImage(session.photoUrl!), fit: BoxFit.cover,) : null,
              ),
              alignment: Alignment.center,
              child: hasPhoto ? null : Text(_initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accentText,),
              ),
            ),
            const SizedBox(height: 28),
            Text(session.fullName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              '${session?.address} - ${session.industry}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}