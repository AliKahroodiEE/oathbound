/// Build-time configuration passed with `--dart-define`.
///
/// Without a backend the app runs fully local (guest/demo mode, ADR-003).
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');

  /// Supabase publishable (client-safe) key. `SUPABASE_ANON_KEY` is still
  /// accepted for projects created before publishable keys existed.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
