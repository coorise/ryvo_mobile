import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ryvo/components/auth/auth_form_shell.dart';
import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/env.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/supabase/client.dart';
import 'package:ryvo/types/interfaces/schemas/auth_schema.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _role = 'client';
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = RegisterInput(
      email: _email.text.trim(),
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      fullName: _fullName.text.trim(),
      role: _role,
    );
    final validationError = validateRegisterInput(input);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await useAuth(ref).signUp(input);
      if (!mounted) return;
      context.go(Routes.authVerifyEmail);
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
      title: T.nav('auth.register.title'),
      description: T.nav('auth.register.description'),
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
          Text(T.nav('auth.register.fullName'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ShadInput(controller: _fullName, placeholder: Text(T.nav('auth.register.fullName'))),
          const SizedBox(height: 16),
          Text(T.nav('auth.register.email'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ShadInput(
            controller: _email,
            placeholder: Text(T.nav('auth.register.email')),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RyvoButton(
                  intent: _role == 'client' ? RyvoButtonIntent.cta : RyvoButtonIntent.outline,
                  fullWidth: true,
                  onPressed: () => setState(() => _role = 'client'),
                  child: Text(T.nav('auth.register.rider')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RyvoButton(
                  intent: _role == 'driver' ? RyvoButtonIntent.cta : RyvoButtonIntent.outline,
                  fullWidth: true,
                  onPressed: () => setState(() => _role = 'driver'),
                  child: Text(T.nav('auth.register.driver')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(T.nav('auth.register.password'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ShadInput(
            controller: _password,
            placeholder: Text(T.nav('auth.register.password')),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Text(T.nav('auth.register.confirmPassword'), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          ShadInput(
            controller: _confirmPassword,
            placeholder: Text(T.nav('auth.register.confirmPassword')),
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
            child: Text(_loading ? T.nav('auth.register.creating') : T.nav('auth.register.submit')),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () => context.go(Routes.landing), child: Text(T.nav('auth.back'))),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.authLogin),
              child: Text(T.nav('auth.register.haveAccount')),
            ),
          ),
        ],
      ),
    );
  }
}
