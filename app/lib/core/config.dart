/// Build-time configuration passed with `--dart-define`.
///
/// Without a backend the app runs fully local (guest/demo mode, ADR-003).
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
