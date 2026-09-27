import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../api/api_client.dart';
import '../utils/workspace_prefs.dart';
import 'home_page.dart';
import 'orgScreen/workspaces/choose_workspace_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  /// Which workspace opens after sign-in — the first rule that matches wins:
  /// one workspace → go straight in; "ask every time" is on → choose; this phone has already had
  /// the admin choose once → reopen the last used one (the server remembers it); otherwise choose.
  Future<bool> _shouldChooseWorkspace(AuthResult session) async {
    if (session.userType != 'Admin' || session.workspaceCount <= 1) return false;
    if (await WorkspacePrefs.askEveryTime()) return true;
    return !await WorkspacePrefs.hasChosen(session.userId);
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await ApiClient.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final chooseFirst = await _shouldChooseWorkspace(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => chooseFirst ? ChooseWorkspacePage(session: session) : HomePage(session: session),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FHeader(title: const Text('Log in')),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Welcome back', style: context.theme.typography.display.xl),
                        const SizedBox(height: 24),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _usernameController),
                          label: const Text('Email'),
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(controller: _passwordController),
                          label: const Text('Password'),
                          obscureText: true,
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
                          onPress: _loading ? null : _login,
                          child: _loading ? const FCircularProgress(size: .sm) : const Text('Log in'),
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
