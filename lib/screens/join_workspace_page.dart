import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import 'login_page.dart';

class JoinWorkspacePage extends StatefulWidget {
  const JoinWorkspacePage({super.key});

  @override
  State<JoinWorkspacePage> createState() => _JoinWorkspacePageState();
}

class _JoinWorkspacePageState extends State<JoinWorkspacePage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgIdController = TextEditingController();

  Timer? _debounce;
  WorkspaceInfo? _workspace;
  bool _lookingUp = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orgIdController.addListener(_onOrgIdChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _orgIdController.removeListener(_onOrgIdChanged);
    super.dispose();
  }

  void _onOrgIdChanged() {
    _debounce?.cancel();
    setState(() => _workspace = null);
    final value = _orgIdController.text.trim();
    if (value.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _lookingUp = true);
      final result = await ApiClient.lookupWorkspace(value);
      if (!mounted) return;
      setState(() {
        _workspace = result;
        _lookingUp = false;
      });
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await ApiClient.registerEmployee(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        organizationId: _orgIdController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(session: session)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "You'll join your team's workspace with a code from the office.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  const Text('Full name', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: _fullNameController),
                  const SizedBox(height: 16),
                  const Text('Email', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  const Text('Password', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: _passwordController, obscureText: true),
                  const SizedBox(height: 20),
                  const Text(
                    'WORKSPACE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  const Text('Organization ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _orgIdController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      suffixIcon: _lookingUp
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (_workspace != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Joining ${_workspace!.businessName}'
                              '${_workspace!.address != null ? ' — ${_workspace!.address}' : ''}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
