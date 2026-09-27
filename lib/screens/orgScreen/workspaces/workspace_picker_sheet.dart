import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/workspaces/add_workspace_page.dart';
import 'package:mk_app/screens/orgScreen/workspaces/workspace_widgets.dart';

/// "Which organization?" — lists the workspaces an admin runs. Picking one makes it the open
/// workspace and resolves to the refreshed session; picking the current one resolves to
/// [session] unchanged; dismissing resolves to null.
Future<AuthResult?> openWorkspacePicker(
  BuildContext context, {
  required AuthResult session,
  String title = 'Which organization?',
  String subtitle = 'Opens its profile and switches the app to it.',
}) {
  return showFSheet<AuthResult>(
    context: context,
    side: .btt,
    mainAxisMaxRatio: 0.9,
    builder: (sheetContext) => _WorkspacePickerSheet(session: session, title: title, subtitle: subtitle),
  );
}

class _WorkspacePickerSheet extends StatefulWidget {
  final AuthResult session;
  final String title;
  final String subtitle;
  const _WorkspacePickerSheet({required this.session, required this.title, required this.subtitle});

  @override
  State<_WorkspacePickerSheet> createState() => _WorkspacePickerSheetState();
}

class _WorkspacePickerSheetState extends State<_WorkspacePickerSheet> {
  late Future<List<WorkspaceSummary>> _workspaces;
  late Future<PlanInfo> _plan;
  String? _switching;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _workspaces = ApiClient.getMyWorkspaces(token: widget.session.token, adminId: widget.session.userId);
    _plan = ApiClient.getPlan(token: widget.session.token, adminId: widget.session.userId);
  }

  Future<void> _pick(WorkspaceSummary workspace) async {
    if (_switching != null) return;
    final navigator = Navigator.of(context);
    if (workspace.active) {
      navigator.pop(widget.session);
      return;
    }
    setState(() {
      _switching = workspace.organizationId;
      _error = null;
    });
    try {
      final next = await ApiClient.switchWorkspace(
        token: widget.session.token,
        adminId: widget.session.userId,
        organizationId: workspace.organizationId,
      );
      navigator.pop(next);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _switching = null;
        _error = e.toString();
      });
    }
  }

  Future<void> _add() async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<AddWorkspaceResult>(
      MaterialPageRoute(builder: (_) => AddWorkspacePage(session: widget.session)),
    );
    if (result == null || !mounted) return;
    final switched = result.switchedSession;
    if (switched != null) {
      navigator.pop(switched);
      return;
    }
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

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
              Text(widget.title, style: typography.display.xl.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(widget.subtitle, style: typography.body.sm.copyWith(color: colors.mutedForeground)),
              const SizedBox(height: 16),
              FutureBuilder<List<WorkspaceSummary>>(
                future: _workspaces,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: FCircularProgress());
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
                          onTap: () => _pick(items[i]),
                          trailing: _switching == items[i].organizationId
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : items[i].active
                              ? const WorkspacePill('Current')
                              : Icon(FLucideIcons.chevronRight, size: 18, color: colors.mutedForeground),
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
              FutureBuilder<PlanInfo>(
                future: _plan,
                builder: (context, snapshot) {
                  final plan = snapshot.data;
                  if (plan == null || !plan.canAddWorkspace) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FButton(variant: .ghost, onPress: _add, child: const Text('+ Add workspace')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
