import 'package:flutter/material.dart';

import 'package:mk_app/api/api_client.dart';

/// A circular avatar that shows the person's photo when they have one,
/// falling back to their initials on a solid color otherwise. Used anywhere
/// a crew member, lead, or the signed-in user needs to be represented.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fullName;
  final double size;
  final Color? color;
  final Color? borderColor;
  final Color textColor;

  const UserAvatar({
    required this.fullName,
    this.photoUrl,
    this.size = 24,
    this.color,
    this.borderColor,
    this.textColor = Colors.white,
    super.key,
  });

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  static const _palette = [
    Color(0xFF3F6B46),
    Color(0xFF2E4E72),
    Color(0xFFB5651D),
    Color(0xFFA23327),
    Color(0xFF2E609A),
    Color(0xFF6E4E9A),
  ];

  static Color colorFor(String seed) {
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? colorFor(fullName),
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 2),
        image: hasPhoto ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              initialsOf(fullName),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
    );
  }
}

/// A row of overlapping [UserAvatar]s (e.g. a job's crew) followed by a label.
class AvatarGroup extends StatelessWidget {
  final List<Employee> people;
  final Widget label;
  final double size;
  final double overlap;

  const AvatarGroup({
    required this.people,
    required this.label,
    this.size = 24,
    this.overlap = 14,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: size + overlap * (people.length - 1),
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < people.length; i++)
              Positioned(
                left: overlap * i,
                child: UserAvatar(
                  fullName: people[i].fullName,
                  photoUrl: people[i].photoUrl,
                  size: size,
                  borderColor: const Color(0xFF222A31),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Flexible(child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 13), child: label)),
    ],
  );
}
