import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/home_page.dart';
import 'package:mk_app/screens/orgScreen/workspaces/workspace_widgets.dart';
import 'package:mk_app/utils/pay_period.dart';
import 'package:mk_app/utils/workspace_prefs.dart';
import 'package:mk_app/widgets/brand_logo.dart';

/// Shown right after signing in when an admin runs several workspaces and the app can't just
/// reopen the last one: the first sign-in on a phone, or when "ask every time" is on. Each row
/// says what needs attention this pay period, so the choice is informed before tapping in.
class ChooseWorkspacePage extends StatefulWidget {
  final AuthResult session;
  const ChooseWorkspacePage({required this.session, super.key});

  @override
  State<ChooseWorkspacePage> createState() => _ChooseWorkspacePageState();
}

class _ChooseWorkspacePageState extends State<ChooseWorkspacePage> {
  late Future<List<WorkspaceSummary>> _workspaces;
  bool _reopenLastUsed = true;
  String? _opening;
  String? _error;

  @override
  void initState() {
    super.initState();
    final period = PayPeriod.current();
    _workspaces = ApiClient.getMyWorkspaces(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: period.start,
      to: period.end,
    );
    WorkspacePrefs.askEveryTime().then((ask) {
      if (mounted) setState(() => _reopenLastUsed = !ask);
    });
  }

  Future<void> _pick(WorkspaceSummary workspace) async {
    if (_opening != null) return;
    setState(() {
      _opening = workspace.organizationId;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      final session = workspace.active
          ? widget.session
          : await ApiClient.switchWorkspace(
              token: widget.session.token,
              adminId: widget.session.userId,
              organizationId: workspace.organizationId,
            );
      await WorkspacePrefs.markChosen(widget.session.userId);
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => HomePage(session: session)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _opening = null;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                const Align(alignment: Alignment.centerLeft, child: BrandLogo(height: 32)),
                const SizedBox(height: 24),
                Text('Choose a workspace', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Signed in as ${widget.session.fullName}',
                  style: typography.body.sm.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<WorkspaceSummary>>(
                  future: _workspaces,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: FCircularProgress());
                    }
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString(), style: TextStyle(color: colors.error));
                    }
                    final items = snapshot.data!;
                    return Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          WorkspaceRow(
                            workspace: items[i],
                            index: i,
                            current: items[i].active,
                            subtitle: '${items[i].city.isEmpty ? 'Workspace' : items[i].city}'
                                '${items[i].active ? ' · last used' : ''}',
                            onTap: () => _pick(items[i]),
                            trailing: _opening == items[i].organizationId
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : WorkspaceAttentionPill(items[i]),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: typography.body.sm.copyWith(color: colors.error)),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Open the last used workspace next time', style: typography.body.sm),
                            const SizedBox(height: 2),
                            Text(
                              'Switch anytime from the header.',
                              style: typography.body.xs.copyWith(color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FSwitch(
                        value: _reopenLastUsed,
                        onChange: (value) {
                          setState(() => _reopenLastUsed = value);
                          WorkspacePrefs.setAskEveryTime(!value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
