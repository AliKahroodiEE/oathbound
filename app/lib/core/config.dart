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

/// Sign-in options. The OAuth clients' IDs and secrets live only in the
/// Supabase project (backend/supabase/config.toml).
abstract final class AuthConfig {
  /// Shows "Continue with Google" (`--dart-define=WYRD_AUTH_GOOGLE=true`),
  /// the same flag that switches the provider on in Supabase.
  static const googleEnabled = bool.fromEnvironment('WYRD_AUTH_GOOGLE');

  /// Shows "Continue with GitHub" (`--dart-define=WYRD_AUTH_GITHUB=true`).
  static const githubEnabled = bool.fromEnvironment('WYRD_AUTH_GITHUB');

  /// Custom URL scheme (the Android applicationId) that brings OAuth
  /// sign-ins back into the phone apps; registered in AndroidManifest.xml
  /// and Info.plist, allowed in `auth.additional_redirect_urls`.
  static const mobileScheme = 'app.wyrd';
  static const mobileCallbackHost = 'auth-callback';
  static const mobileRedirectUrl = '$mobileScheme://$mobileCallbackHost';
}
