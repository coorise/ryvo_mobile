import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/auth/auth_form_shell.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/password_reset_session.dart';
import 'package:ryvo/services/auth_password_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _loading = false;
  var _ready = false;
  String? _error;
  PasswordResetSession? _session;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await getPasswordResetSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text;
    final confirm = _confirm.text;
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    final session = _session;
    final token = session?.resetToken;
    if (session == null || token == null || token.isEmpty) {
      setState(() => _error = 'Session expired. Verify your code first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authPasswordService.resetPassword(session.email, token, password);
      await clearPasswordResetSession();
      if (!mounted) return;
      context.go(Routes.authLogin);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const AuthFormShell(
        title: 'Loading…',
        description: 'Please wait…',
        child: SizedBox.shrink(),
      );
    }

    final session = _session;
    if (session == null ||
        session.email.isEmpty ||
        session.resetToken == null ||
        session.resetToken!.isEmpty) {
      return AuthFormShell(
        title: 'Session expired',
        description: 'Verify your code first.',
        child: ShadButton(
          onPressed: () => context.go(Routes.authForgotPassword),
          child: const Text('Start over'),
        ),
      );
    }

    return AuthFormShell(
      title: 'New password',
      description: 'Choose a strong password for your account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            controller: _password,
            placeholder: const Text('New password'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          ShadInput(
            controller: _confirm,
            placeholder: const Text('Confirm password'),
            obscureText: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          ShadButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Saving…' : 'Update password'),
          ),
        ],
      ),
    );
  }
}
