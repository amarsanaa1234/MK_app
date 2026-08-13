import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../api/api_client.dart';
import 'home_page.dart';

class SetupWorkspacePage extends StatefulWidget {
  const SetupWorkspacePage({super.key});

  @override
  State<SetupWorkspacePage> createState() => _SetupWorkspacePageState();
}

class _SetupWorkspacePageState extends State<SetupWorkspacePage> {
  final _businessNameController = TextEditingController();
  final _abnController = TextEditingController();
  final _industryController = TextEditingController();
  final _addressController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  bool _submitting = false;
  String? _error;
  AuthResult? _created;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await ApiClient.createWorkspace(
        businessName: _businessNameController.text.trim(),
        abn: _abnController.text.trim(),
        industry: _industryController.text.trim(),
        address: _addressController.text.trim(),
        adminName: _adminNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
        adminPassword: _adminPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _created = session);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader(title: const Text('Set up your workspace')),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: _created != null ? _buildSuccess(context, _created!) : _buildForm(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'For businesses new to MK Roster',
          style: typography.body.sm.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: 24),
        FTextField(
          control: FTextFieldControl.managed(controller: _businessNameController),
          label: const Text('Business name'),
        ),
        const SizedBox(height: 16),
        FTextField(
          control: FTextFieldControl.managed(controller: _abnController),
          label: const Text('ABN'),
        ),
        const SizedBox(height: 16),
        FTextField(
          control: FTextFieldControl.managed(controller: _industryController),
          label: const Text('Industry'),
        ),
        const SizedBox(height: 16),
        FTextField(
          control: FTextFieldControl.managed(controller: _addressController),
          label: const Text('Address'),
        ),
        const SizedBox(height: 20),
        Text(
          'YOUR ADMIN ACCOUNT',
          style: typography.body.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        FDivider(style: .delta(color: colors.border)),
        const SizedBox(height: 4),
        FTextField(
          control: FTextFieldControl.managed(controller: _adminNameController),
          label: const Text('Your name'),
        ),
        const SizedBox(height: 16),
        FTextField(
          control: FTextFieldControl.managed(controller: _adminEmailController),
          label: const Text('Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        FTextField(
          control: FTextFieldControl.managed(controller: _adminPasswordController),
          label: const Text('Password'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR WORKSPACE ID',
                style: typography.body.xs2.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'appears here once created — share it with your crew',
                style: typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                  fontFamily: 'monospace',
                ),
              ),
            ],
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
          onPress: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create workspace'),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, AuthResult session) {
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: 20),
        Text(
          'Workspace created',
          textAlign: TextAlign.center,
          style: typography.display.xl,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'YOUR WORKSPACE ID',
                style: typography.body.xs2.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.organizationId,
                style: typography.display.xl.copyWith(
                  color: Colors.green.shade700,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'share it with your crew',
                style: typography.body.xs.copyWith(color: Colors.green.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FButton(
          onPress: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(session: session)),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
