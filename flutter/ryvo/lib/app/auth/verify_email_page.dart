import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo/components/auth/auth_form_shell.dart';
import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';

class VerifyEmailPage extends ConsumerWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useAuth(ref).user?.email;

    return AuthFormShell(
      title: T.nav('auth.verifyEmail.title'),
      description: T.nav('auth.verifyEmail.description'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (email != null && email.isNotEmpty)
            Text(
              '${T.nav('auth.verifyEmail.sentTo')} $email',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          const SizedBox(height: 24),
          RyvoButton(
            fullWidth: true,
            intent: RyvoButtonIntent.outline,
            onPressed: () => context.go(Routes.authLogin),
            child: Text(T.nav('auth.verifyEmail.backToSignIn')),
          ),
        ],
      ),
    );
  }
}
