import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/generated/app_localizations.dart';

/// Auth error codes (https://supabase.com/docs/guides/auth/debugging/error-codes)
/// the sign-in flow explains in its own words.
abstract final class AuthCodes {
  static const invalidCredentials = 'invalid_credentials';
  static const emailNotConfirmed = 'email_not_confirmed';
  static const otpExpired = 'otp_expired';
  static const weakPassword = 'weak_password';
  static const samePassword = 'same_password';
  static const userExists = 'user_already_exists';
  static const emailExists = 'email_exists';
  static const badEmail = {'validation_failed', 'email_address_invalid'};
  static const rateLimits = {'over_email_send_rate_limit', 'over_request_rate_limit', 'over_sms_send_rate_limit'};
  static const timeouts = {'request_timeout'};
  static const unavailable = {
    'provider_disabled',
    'email_provider_disabled',
    // Supabase's built-in mailer only reaches the project's team.
    'email_address_not_authorized',
    'oauth_provider_not_supported',
    'signup_disabled',
    'bad_oauth_state',
    'bad_oauth_callback',
  };
}

/// Whether [error] is Auth reporting [code].
bool isAuthCode(Object error, String code) => error is AuthException && error.code == code;

/// A message for [error] in the reader's language.
String authErrorMessage(AppLocalizations l10n, Object error) {
  // No connection: Auth retries later; database calls fail in the HTTP client.
  if (error is AuthRetryableFetchException || error is ClientException) return l10n.authErrNetwork;
  if (error is AuthWeakPasswordException) return l10n.authErrWeakPassword;
  if (error is AuthException) {
    final code = error.code;
    if (code == AuthCodes.invalidCredentials) return l10n.authInvalid;
    if (code == AuthCodes.emailNotConfirmed) return l10n.authErrNotConfirmed;
    if (code == AuthCodes.otpExpired) return l10n.authErrCode;
    if (code == AuthCodes.weakPassword) return l10n.authErrWeakPassword;
    if (code == AuthCodes.samePassword) return l10n.authErrSamePassword;
    if (code == AuthCodes.userExists || code == AuthCodes.emailExists) return l10n.authErrAccountExists;
    if (AuthCodes.badEmail.contains(code)) return l10n.authErrEmail;
    if (AuthCodes.rateLimits.contains(code) || error.statusCode == '429') return l10n.authErrRateLimit;
    if (AuthCodes.timeouts.contains(code)) return l10n.authErrNetwork;
    if (AuthCodes.unavailable.contains(code)) return l10n.authErrProvider;
  }
  return l10n.errorGeneric;
}
