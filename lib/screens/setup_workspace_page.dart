import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Set up your workspace')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: _created != null ? _buildSuccess(_created!) : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'For businesses new to MK Roster',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 24),
        const Text('Business name', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _businessNameController),
        const SizedBox(height: 16),
        const Text('ABN', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _abnController),
        const SizedBox(height: 16),
        const Text('Industry', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _industryController),
        const SizedBox(height: 16),
        const Text('Address', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _addressController),
        const SizedBox(height: 20),
        const Text(
          'YOUR ADMIN ACCOUNT',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const Divider(color: AppColors.border, height: 20),
        const Text('Your name', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _adminNameController),
        const SizedBox(height: 16),
        const Text('Email', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _adminEmailController, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        const Text('Password', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(controller: _adminPasswordController, obscureText: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR WORKSPACE ID',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'appears here once created — share it with your crew',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
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
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error)),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentText),
                )
              : const Text('Create workspace'),
        ),
      ],
    );
  }

  Widget _buildSuccess(AuthResult session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        const SizedBox(height: 20),
        Text(
          'Workspace created',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'YOUR WORKSPACE ID',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.organizationId,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'share it with your crew',
                style: TextStyle(color: AppColors.success, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(session: session)),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
