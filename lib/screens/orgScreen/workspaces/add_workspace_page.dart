import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/screens/orgScreen/billing/plan_parts.dart';
import 'package:mk_app/widgets/copy_text.dart';

/// What [AddWorkspacePage] hands back once a workspace exists.
class AddWorkspaceResult {
  final WorkspaceSummary created;

  /// Set when the admin chose "Open it" — the refreshed session for the new workspace.
  final AuthResult? switchedSession;
  const AddWorkspaceResult(this.created, this.switchedSession);
}

/// Business admins: add another workspace under the same plan. It gets its own Org ID, so its
/// crew, jobs and payroll stay separate from the admin's other workspaces.
class AddWorkspacePage extends StatefulWidget {
  final AuthResult session;
  const AddWorkspacePage({required this.session, super.key});

  @override
  State<AddWorkspacePage> createState() => _AddWorkspacePageState();
}

class _AddWorkspacePageState extends State<AddWorkspacePage> {
  final _nameController = TextEditingController();
  final _abnController = TextEditingController();
  late final _industryController = TextEditingController(text: widget.session.industry);
  final _addressController = TextEditingController();

  late final Future<PlanInfo> _plan;
  bool _submitting = false;
  bool _opening = false;
  String? _error;
  WorkspaceSummary? _created;

  @override
  void initState() {
    super.initState();
    _plan = ApiClient.getPlan(token: widget.session.token, adminId: widget.session.userId);
    for (final c in [_nameController, _abnController, _industryController, _addressController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abnController.dispose();
    _industryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _abnController.text.trim().isNotEmpty &&
      _industryController.text.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await ApiClient.addWorkspace(
        token: widget.session.token,
        adminId: widget.session.userId,
        businessName: _nameController.text.trim(),
        abn: _abnController.text.trim(),
        industry: _industryController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _created = created);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _open(WorkspaceSummary created) async {
    setState(() {
      _opening = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      final session = await ApiClient.switchWorkspace(
        token: widget.session.token,
        adminId: widget.session.userId,
        organizationId: created.organizationId,
      );
      navigator.pop(AddWorkspaceResult(created, session));
    } catch (e) {
      if (mounted) {
        setState(() {
          _opening = false;
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).pop(
                      _created == null ? null : AddWorkspaceResult(_created!, null),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, size: 22, color: kPlanBlue),
                          Text(
                            'Back',
                            style: typography.body.md.copyWith(color: kPlanBlue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_created == null) ..._form(context) else ..._success(context, _created!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _form(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return [
      Text('Add a workspace', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      FutureBuilder<PlanInfo>(
        future: _plan,
        builder: (context, snapshot) {
          final plan = snapshot.data;
          final text = plan == null
              ? 'Add another business to your plan'
              : 'Uses 1 of your ${plan.maxWorkspaces - plan.workspacesUsed} remaining workspaces · '
                    '${plan.workspacesUsed} of ${plan.maxWorkspaces} on ${planSpecOf(plan.plan).name}';
          return Text(text, style: typography.body.sm.copyWith(color: colors.mutedForeground));
        },
      ),
      const SizedBox(height: 20),
      FTextField(
        control: FTextFieldControl.managed(controller: _nameController),
        label: const Text('Business name'),
        hint: 'e.g. MK Removals — Perth',
      ),
      const SizedBox(height: 16),
      FTextField(control: FTextFieldControl.managed(controller: _abnController), label: const Text('ABN')),
      const SizedBox(height: 16),
      FTextField(
        control: FTextFieldControl.managed(controller: _industryController),
        label: const Text('Industry'),
        hint: widget.session.industry,
      ),
      const SizedBox(height: 16),
      FTextField(
        control: FTextFieldControl.managed(controller: _addressController),
        label: const Text('Address'),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          "You'll be the admin of this workspace. Its people, jobs and payroll stay separate from your other "
          'workspaces, and it gets its own Org ID for crew to join.',
          style: typography.body.sm.copyWith(height: 1.45),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_error!, style: TextStyle(color: colors.error)),
        ),
      ],
      const SizedBox(height: 24),
      FButton(
        onPress: _submitting || !_canSubmit ? null : _submit,
        child: _submitting ? const FCircularProgress(size: .sm) : const Text('Create workspace'),
      ),
      const SizedBox(height: 8),
      FButton(variant: .outline, onPress: () => Navigator.of(context).pop(), child: const Text('Cancel')),
    ];
  }

  List<Widget> _success(BuildContext context, WorkspaceSummary created) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return [
      const SizedBox(height: 12),
      const Icon(Icons.check_circle, color: kPlanGreen, size: 52),
      const SizedBox(height: 16),
      Text(
        'Workspace created',
        textAlign: TextAlign.center,
        style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        created.businessName,
        textAlign: TextAlign.center,
        style: typography.body.md.copyWith(color: colors.mutedForeground),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPlanGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'ITS ORGANIZATION ID',
              style: typography.body.xs2.copyWith(
                color: kPlanGreen,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            CopyableText(
              text: created.organizationId,
              alignment: MainAxisAlignment.center,
              style: typography.display.xl.copyWith(
                color: kPlanGreen,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Share it with this workspace's crew so they can join.",
              textAlign: TextAlign.center,
              style: typography.body.xs.copyWith(color: kPlanGreen),
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(_error!, style: typography.body.sm.copyWith(color: colors.error)),
      ],
      const SizedBox(height: 24),
      FButton(
        onPress: _opening ? null : () => _open(created),
        child: _opening ? const FCircularProgress(size: .sm) : Text('Open ${created.businessName}'),
      ),
      const SizedBox(height: 8),
      FButton(
        variant: .outline,
        onPress: () => Navigator.of(context).pop(AddWorkspaceResult(created, null)),
        child: const Text('Done'),
      ),
    ];
  }
}
