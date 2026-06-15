import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/auth/auth_form_shell.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/lib/password_reset_session.dart';
import 'package:ryvo_admin/services/auth_password_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _code = TextEditingController();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit(PasswordResetSession session) async {
    final code = _code.text.replaceAll(RegExp(r'\D'), '');
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await authPasswordService.verifyOtp(session.email, code);
      final token = res['reset_token']?.toString();
      if (token == null || token.isEmpty) {
        setState(() => _error = 'Invalid verification response.');
        return;
      }
      await setPasswordResetSession(
        PasswordResetSession(email: session.email, resetToken: token),
      );
      if (!mounted) return;
      context.go(Routes.authResetPassword);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReset =
        GoRouterState.of(context).uri.queryParameters['flow'] == 'reset';

    return FutureBuilder<PasswordResetSession?>(
      future: getPasswordResetSession(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return const AuthFormShell(
            title: 'Loading…',
            description: 'Please wait…',
            child: SizedBox.shrink(),
          );
        }

        final session = snapshot.data;

        if (isReset && (session == null || session.email.isEmpty)) {
          return AuthFormShell(
            title: 'Session expired',
            description: 'Start the reset flow again.',
            child: ShadButton(
              onPressed: () => context.go(Routes.authForgotPassword),
              child: const Text('Forgot password'),
            ),
          );
        }

        return AuthFormShell(
          title: 'Enter verification code',
          description:
              'We sent a 6-digit code to ${session?.email ?? 'your email'}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadInput(
                controller: _code,
                placeholder: const Text('6-digit code'),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                onChanged: (v) {
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits != v) {
                    _code.value = TextEditingValue(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              ShadButton(
                onPressed: _loading || _code.text.length < 6 || session == null
                    ? null
                    : () => _submit(session),
                child: Text(_loading ? 'Verifying…' : 'Verify code'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(Routes.authForgotPassword),
                child: const Text('Resend code'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VerifyEmailPage extends ConsumerWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authProvider).user?.email;

    return AuthFormShell(
      title: 'Verify your email',
      description:
          'We sent a confirmation link. Open it to unlock booking and driving.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (email != null && email.isNotEmpty)
            Text(
              'Sent to $email',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          ShadButton(
            onPressed: () => context.go(Routes.authLogin),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
