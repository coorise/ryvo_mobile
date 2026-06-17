import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/app/router.dart';
import 'package:ryvo/components/providers/app_providers.dart';
import 'package:ryvo/components/update/update_check_host.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/i18n/app_i18n.dart';
import 'package:ryvo/services/supabase/client.dart';
import 'package:ryvo/stores/locale_store.dart';
import 'package:ryvo/stores/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeSupabase();
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString(AppConst.storageLanguage) ?? 'en';
  await AppI18n.instance.load(lang);

  runApp(
    AppProviders(
      prefs: prefs,
      child: const RyvoApp(),
    ),
  );
}

class RyvoApp extends ConsumerWidget {
  const RyvoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ShadApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConst.appName,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: UpdateCheckHost(child: child ?? const SizedBox.shrink()),
        );
      },
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadGreenColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadGreenColorScheme.dark(),
      ),
      routerConfig: router,
    );
  }
}
