import 'package:flutter/foundation.dart';

/// Konfigurasi runtime SIMKlinik Mobile.
/// Nilai kredensial diinjeksi via `--dart-define` saat build/run untuk keamanan maksimum.
///
/// Contoh:
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=ey...
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Status apakah aplikasi terhubung ke Supabase live atau berjalan dalam mode Demo.
  /// PRD & Master Prompt Rule: Jika credentials tidak disetel, mode Demo ditandai secara eksplisit di UI
  /// dan tidak mengarang status integrasi palsu.
  static bool get isLiveConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isDemoMode => !isLiveConfigured;

  static const String appName = 'SIMKlinik';
  static const String appVersion = '1.0.0 (MVP)';

  static void printEnvironmentStatus() {
    if (kDebugMode) {
      if (isLiveConfigured) {
        debugPrint('[SIMKlinik] Terhubung ke Supabase URL: $supabaseUrl');
      } else {
        debugPrint(
          '[SIMKlinik] Berjalan dalam Mode Demo / Mock Repository eksplisit (Kredensial dart-define belum disetel).',
        );
      }
    }
  }
}
