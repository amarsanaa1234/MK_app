import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet with the workspace's organization ID — the only thing a new
/// hire needs to join — plus a way to copy it or hand it off by text message.
Future<void> openInviteCrewSheet(
  BuildContext context, {
  required String organizationId,
  required String businessName,
  required List<EmployeeOverview> joinedThisWeek,
}) {
  return showFSheet(
    context: context,
    side: .btt,
    mainAxisMaxRatio: 0.9,
    builder: (context) => InviteCrewSheet(
      organizationId: organizationId,
      businessName: businessName,
      joinedThisWeek: joinedThisWeek,
    ),
  );
}

class InviteCrewSheet extends StatefulWidget {
  final String organizationId;
  final String businessName;
  final List<EmployeeOverview> joinedThisWeek;

  const InviteCrewSheet({
    required this.organizationId,
    required this.businessName,
    required this.joinedThisWeek,
    super.key,
  });

  @override
  State<InviteCrewSheet> createState() => _InviteCrewSheetState();
}

class _InviteCrewSheetState extends State<InviteCrewSheet> {
  bool _copied = false;

  String get _message =>
      'Join ${widget.businessName} on MK Roster: tap "Create an account" and enter the organization ID '
      '${widget.organizationId}.';

  // Browsers can refuse clipboard access outright, so a failed copy is reported
  // instead of left as an unhandled error.
  Future<bool> _writeClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _writeClipboard(widget.organizationId);
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't copy — select the code and copy it manually")));
      return;
    }
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final sms = Uri(scheme: 'sms', queryParameters: {'body': _message});
    var opened = false;
    try {
      opened = await launchUrl(sms);
    } catch (_) {}
    if (opened) return;

    final copied = await _writeClipboard(_message);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          copied ? 'Invite message copied — paste it into a chat' : "Couldn't share — send them the code above",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    Widget step(int number, Widget text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Text('$number', style: typography.body.xs.copyWith(color: colors.mutedForeground)),
          ),
          const SizedBox(width: 12),
          Expanded(child: text),
        ],
      ),
    );

    final bodyStyle = typography.body.sm.copyWith(color: colors.foreground);
    final boldStyle = bodyStyle.copyWith(fontWeight: FontWeight.w800);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Invite crew', style: typography.display.xl.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Anyone with this code can join ${widget.businessName} as crew.',
                style: typography.body.sm.copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORGANIZATION ID',
                            style: typography.body.xs2.copyWith(
                              color: colors.mutedForeground,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.organizationId,
                              style: typography.display.xl2.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FButton(
                      variant: .outline,
                      size: .sm,
                      onPress: _copy,
                      child: Text(_copied ? 'Copied' : 'Copy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              step(1, Text('Send them the code — text, WhatsApp or in person.', style: bodyStyle)),
              step(
                2,
                Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      const TextSpan(text: 'They choose '),
                      TextSpan(text: 'Create an account', style: boldStyle),
                      const TextSpan(text: ' in the app and enter it.'),
                    ],
                  ),
                ),
              ),
              step(
                3,
                Text(
                  "They appear in Employees. Set their pay rate once and they're ready to roster.",
                  style: bodyStyle,
                ),
              ),
              const SizedBox(height: 16),
              FButton(onPress: _share, child: const Text('Share invite')),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.joinedThisWeek.isNotEmpty) ...[
                    SizedBox(
                      width: 28 + 18.0 * (widget.joinedThisWeek.take(3).length - 1),
                      height: 28,
                      child: Stack(
                        children: [
                          for (var i = 0; i < widget.joinedThisWeek.take(3).length; i++)
                            Positioned(
                              left: 18.0 * i,
                              child: UserAvatar(
                                fullName: widget.joinedThisWeek[i].fullName,
                                photoUrl: widget.joinedThisWeek[i].photoUrl,
                                size: 28,
                                borderColor: colors.background,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.joinedThisWeek.isEmpty
                          ? 'No one has joined with this code this week yet.'
                          : '${widget.joinedThisWeek.length} crew joined with this code this week',
                      style: typography.body.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
