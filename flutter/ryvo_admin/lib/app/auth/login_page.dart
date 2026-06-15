import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ryvo_admin/components/ryvo/brand_logo.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/configs/env.dart';
import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/supabase/client.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'admin@ryvo-line.com');
  final _password = TextEditingController(text: Env.isDev ? 'Admin@123' : '');
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
        setState(() => _error = 'Please verify your email before signing in.');
        return;
      }
      final path = Abac.dashboardPathForUser(user);
      if (path == Routes.authLogin) {
        setState(() => _error = 'This account does not have admin access.');
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
        : 'Supabase is not configured. Run ./run_dev.sh or ./run_build.sh '
            '(loads ANON_KEY from server/supabase/.env).';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandLogo(),
              const SizedBox(height: 32),
              Text('Staff sign in', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Accounts are provisioned by your organization.'),
              if (configError != null) ...[
                const SizedBox(height: 16),
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
              ],
              const SizedBox(height: 24),
              ShadInput(
                controller: _email,
                placeholder: const Text('Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: _password,
                placeholder: const Text('Password'),
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              ShadButton(
                onPressed: configured && !_loading ? _submit : null,
                child: Text(_loading ? 'Signing in…' : 'Sign in'),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.go(Routes.landing), child: const Text('Back')),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => context.go(Routes.authForgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
