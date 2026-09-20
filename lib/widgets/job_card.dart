import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mk_app/api/api_client.dart';
import 'app_dialog.dart';
import 'user_avatar.dart';

const jobStatusLabels = {
  'DRAFT': 'Draft',
  'OPEN': 'Open',
  'CLOSED': 'Closed',
  'CANCELLED': 'Cancelled',
};

Color jobStatusColor(BuildContext context, String status) {
  final colors = context.theme.colors;
  return switch (status) {
    'DRAFT' => colors.mutedForeground,
    'CANCELLED' => colors.destructive,
    _ => colors.primary,
  };
}

/// One job post, shown the same way whether it's on the admin dashboard or a
/// crew member's home feed — only the overline (a date vs. a "posted" label)
/// and the admin-only actions (edit, enter hours) differ between the two.
class JobCard extends StatelessWidget {
  final Widget overline;
  final String status;
  final String? addressLine;
  final String descriptionText;
  final List<Employee> avatarPeople;
  final Widget? avatarLabel;
  final String? notes;
  final Employee? leader;
  final List<Employee> crew;
  final VoidCallback? onEdit;
  final VoidCallback? onEnterHours;

  const JobCard({
    required this.overline,
    required this.status,
    required this.descriptionText,
    this.addressLine,
    this.avatarPeople = const [],
    this.avatarLabel,
    this.notes,
    this.leader,
    this.crew = const [],
    this.onEdit,
    this.onEnterHours,
    super.key,
  });

  Future<void> _openDirections(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showNotes(BuildContext context) {
    showFAppDialog<void>(
      context: context,
      title: 'Notes',
      bodyText: notes ?? '',
      actions: [
        FButton(
          variant: .ghost,
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showCrew(BuildContext context) {
    showFAppDialog<void>(
      context: context,
      title: 'Who\'s on this job',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leader != null) _CrewRow(person: leader!, roleLabel: 'Lead'),
          for (final person in crew)
            _CrewRow(person: person, roleLabel: 'Crew'),
        ],
      ),
      actions: [
        FButton(
          variant: .ghost,
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.theme.cardStyle;
    final colors = context.theme.colors;
    final hasNotes = notes != null && notes!.trim().isNotEmpty;

    return FCard(
      style: style,
      child: Padding(
        padding: style.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF8AA1C2),
                      fontWeight: FontWeight.bold,
                    ),
                    child: overline,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: jobStatusColor(context, status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    jobStatusLabels[status] ?? status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: jobStatusColor(context, status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              addressLine ?? 'No address set',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              descriptionText,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 14, color: const Color(0xFF5C6572)),
            ),
            if (avatarPeople.isNotEmpty) ...[
              const SizedBox(height: 6),
              DefaultTextStyle.merge(
                style: style.subtitleTextStyle,
                child: AvatarGroup(people: avatarPeople, label: avatarLabel ?? const SizedBox.shrink()),
              ),
            ],
            const SizedBox(height: 6),
            FButton(
              onPress: addressLine == null ? null : () => _openDirections(addressLine!),
              child: const Text('Get directions'),
            ),
            if (leader != null || crew.isNotEmpty || hasNotes || onEnterHours != null || onEdit != null) ...[
              const SizedBox(height: 8),
              // A second row for the icon-only actions — keeping "Get directions" on its
              // own full-width row means this can never overflow, no matter how many
              // actions end up here or how narrow the screen is.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (leader != null || crew.isNotEmpty)
                    _IconAction(
                      icon: FLucideIcons.users,
                      tooltip: 'View crew',
                      color: colors.mutedForeground,
                      onPressed: () => _showCrew(context),
                    ),
                  if (hasNotes) ...[
                    const SizedBox(width: 8),
                    _IconAction(
                      icon: FLucideIcons.stickyNote,
                      tooltip: 'View notes',
                      color: colors.mutedForeground,
                      onPressed: () => _showNotes(context),
                    ),
                  ],
                  if (onEnterHours != null) ...[
                    const SizedBox(width: 8),
                    _IconAction(
                      icon: FLucideIcons.clock,
                      tooltip: 'Enter hours',
                      color: colors.mutedForeground,
                      onPressed: onEnterHours!,
                    ),
                  ],
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    _IconAction(
                      icon: FLucideIcons.pencil,
                      tooltip: 'Edit job',
                      color: colors.mutedForeground,
                      onPressed: onEdit!,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One person's row in the "Who's on this job" dialog — avatar, name, role.
class _CrewRow extends StatelessWidget {
  final Employee person;
  final String roleLabel;
  const _CrewRow({required this.person, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          UserAvatar(fullName: person.fullName, photoUrl: person.photoUrl, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(person.fullName, style: TextStyle(color: colors.foreground)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _IconAction({required this.icon, required this.tooltip, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
