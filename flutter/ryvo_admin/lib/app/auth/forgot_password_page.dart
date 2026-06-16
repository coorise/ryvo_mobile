import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/auth/auth_form_shell.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/lib/password_reset_session.dart';
import 'package:ryvo_admin/services/auth_password_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await authPasswordService.requestReset(email);
      if (res['sent'] != true) {
        setState(() => _error = res['message']?.toString() ?? 'Request failed.');
        return;
      }
      await setPasswordResetSession(PasswordResetSession(email: email));
      if (!mounted) return;
      context.go('${Routes.authOtp}?flow=reset');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: 'Forgot password?',
      description:
          'Enter your email. We will send a 6-digit code to reset your password.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            controller: _email,
            placeholder: const Text('Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          ShadButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Sending…' : 'Send reset code'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(Routes.authLogin),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
