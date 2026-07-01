import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ryvo/components/auth/auth_form_shell.dart';
import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/env.dart';
import 'package:ryvo/guards/abac.dart';
import 'package:ryvo/guards/internal_user.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/supabase/client.dart';
import 'package:ryvo/stores/auth_store.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await useAuth(ref).signIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      final user = ref.read(authProvider).user;
      if (user != null && !user.emailVerified) {
        context.go(Routes.authVerifyEmail);
        return;
      }
      if (user != null && isInternalPortalUser(user)) {
        setState(() => _error = T.nav('auth.login.staffBlocked'));
        await ref.read(authProvider.notifier).signOut();
        return;
      }
      final path = Abac.portalDashboardPathForUser(user);
      if (path == Routes.authLogin) {
        setState(() => _error = T.nav('auth.login.noPortalAccess'));
        await ref.read(authProvider.notifier).signOut();
        return;
      }
      context.go(path);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = supabaseIsReady && Env.supabaseAnonKey.isNotEmpty;
    final configError = configured
        ? null
        : 'Supabase is not configured. Run ./run_dev_android.sh, ./run_dev_ios.sh, or ./run_build_android.sh.';

    return AuthFormShell(
      title: T.nav('auth.login.title'),
      description: T.nav('auth.login.description'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (configError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                configError,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(T.nav('auth.login.email'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ShadInput(
            controller: _email,
            placeholder: Text(T.nav('auth.login.emailPlaceholder')),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Text(T.nav('auth.login.password'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ShadInput(
            controller: _password,
            placeholder: Text(T.nav('auth.login.passwordPlaceholder')),
            obscureText: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          RyvoButton(
            fullWidth: true,
            onPressed: configured && !_loading ? _submit : null,
            child: Text(_loading ? T.nav('auth.login.signingIn') : T.nav('common.signIn')),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () => context.go(Routes.landing), child: Text(T.nav('auth.back'))),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => context.go(Routes.authForgotPassword),
              child: Text(T.nav('auth.login.forgotPassword')),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.authRegister),
              child: Text(T.nav('auth.login.noAccount')),
            ),
          ),
        ],
      ),
    );
  }
}
