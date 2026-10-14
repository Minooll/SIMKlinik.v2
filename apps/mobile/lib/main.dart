import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for dates
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase only if live credentials are provided via dart-define
  if (AppConfig.isLiveConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[SIMKlinik] Gagal inisialisasi Supabase live: $e');
    }
  }

  AppConfig.printEnvironmentStatus();

  runApp(const ProviderScope(child: SIMKlinikApp()));
}

class SIMKlinikApp extends StatelessWidget {
  const SIMKlinikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      builder: (context, child) {
        // Enforce accessible text scaling limits (prevents layout break while supporting accessibility)
        final mediaQueryData = MediaQuery.of(context);
        final constrainedScale = mediaQueryData.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.35,
        );

        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: constrainedScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
