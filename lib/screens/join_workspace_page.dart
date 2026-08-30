import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _abnController = TextEditingController();

  Timer? _debounce;
  WorkspaceInfo? _workspace;
  bool _lookingUp = false;
  bool _submitting = false;
  String? _error;

  XFile? _avatar;
  Uint8List? _avatarBytes;

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _avatar = picked;
      _avatarBytes = bytes;
    });
  }

  @override
  void initState() {
    super.initState();
    _orgIdController.addListener(_onOrgIdChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _orgIdController.removeListener(_onOrgIdChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _orgIdController.dispose();
    _abnController.dispose();
    _addressController.dispose();
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
    if (_workspace == null) {
      setState(() => _error = 'Байгууллагын ID зөв эсэхийг шалгана уу');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await ApiClient.registerEmployee(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        organizationId: _orgIdController.text.trim(),
        address: _addressController.text.trim(),
        abn: _abnController.text.trim(),
        photo: _avatar,
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
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader.nested(
              title: const Text('Create your account'),
              prefixes: [
                FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
              ],
            ),
            Expanded(
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
                          style: typography.body.sm.copyWith(color: colors.mutedForeground),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: colors.secondary,
                                  backgroundImage: _avatarBytes != null
                                      ? MemoryImage(_avatarBytes!)
                                      : null,
                                  child: _avatarBytes == null
                                      ? Icon(Icons.person, size: 40, color: colors.mutedForeground)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colors.background, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: colors.primaryForeground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _fullNameController),
                          label: const Text('Full name'),
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _emailController),
                          label: const Text('Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _phoneController),
                          label: const Text('Phone number'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _abnController),
                          label: const Text('ABN'),
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _addressController),
                          label: const Text('Address'),
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _passwordController),
                          label: const Text('Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'WORKSPACE',
                          style: typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        FDivider(style: .delta(color: colors.border)),
                        const SizedBox(height: 4),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _orgIdController),
                          label: const Text('Organization ID'),
                          textCapitalization: TextCapitalization.characters,
                          suffixBuilder: (context, style, _) => _lookingUp
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (_workspace != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Joining ${_workspace!.businessName}'
                                    '${_workspace!.address != null ? ' — ${_workspace!.address}' : ''}',
                                    style: typography.body.xs.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
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
                              : const Text('Create account'),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: FButton(
                            variant: .ghost,
                            onPress: () => Navigator.of(context).pushReplacement(
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
          ],
        ),
      ),
    );
  }
}
