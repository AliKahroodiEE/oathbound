import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wyrd/data/remote/backend.dart';
import 'package:wyrd/features/auth/auth_errors.dart';
import 'package:wyrd/features/auth/auth_widgets.dart';
import 'package:wyrd/l10n/generated/app_localizations.dart';
import 'package:wyrd/l10n/generated/app_localizations_en.dart';

void main() {
  group('extractCode', () {
    test('finds the code in a sentence', () => expect(extractCode('Your Wyrd code: 482913. Valid 60 min.'), '482913'));
    test('joins a spaced code', () => expect(extractCode('482 913'), '482913'));
    test('reads Persian and Arabic-Indic digits', () {
      expect(extractCode('کد: ۴۸۲۹۱۳'), '482913');
      expect(extractCode('٤٨٢٩١٣'), '482913');
    });
    test('ignores text without a code', () {
      expect(extractCode('no code here'), isNull);
      expect(extractCode('12345'), isNull);
      expect(extractCode(null), isNull);
    });
  });

  test('the code field keeps six ASCII digits and pulls codes out of pastes', () {
    const f = CodeInputFormatter();
    TextEditingValue edit(String old, String now) =>
        f.formatEditUpdate(TextEditingValue(text: old), TextEditingValue(text: now));
    expect(edit('12', '12a').text, '12');
    expect(edit('', '۷').text, '7');
    expect(edit('123456', '1234567').text, '123456');
    expect(edit('', 'Wyrd 2026: 482913').text, '482913');
  });

  test('email check', () {
    expect(isValidEmail('ash@example.com'), isTrue);
    expect(isValidEmail('ash@example'), isFalse);
    expect(isValidEmail('ash example.com'), isFalse);
  });

  test('new passwords follow auth.password_requirements = letters_digits', () {
    expect(isAcceptablePassword('emberglow42'), isTrue);
    expect(isAcceptablePassword('ember42'), isFalse, reason: 'shorter than 8');
    expect(isAcceptablePassword('emberglowing'), isFalse, reason: 'no digit');
    expect(isAcceptablePassword('20262026'), isFalse, reason: 'no letter');
    expect(isAcceptablePassword('گذرواژه۱۲۳۴'), isFalse, reason: 'Auth counts only Latin letters and 0-9');
  });

  test('only app.wyrd://auth-callback and web callbacks count as sign-in links', () {
    expect(isAuthCallbackUri(Uri.parse('app.wyrd://auth-callback?code=abc')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('app.wyrd://auth-callback?error=access_denied')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('app.wyrd://invite?code=abc')), isFalse);
    expect(isAuthCallbackUri(Uri.parse('https://wyrd-app.pages.dev/?code=abc')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('https://wyrd-app.pages.dev/?error=access_denied')), isTrue);
    expect(isAuthCallbackUri(Uri.parse('https://wyrd-app.pages.dev/#/character')), isFalse);
  });

  test('Auth errors are explained in the reader\'s words', () {
    final AppLocalizations l10n = AppLocalizationsEn();
    String message(Object e) => authErrorMessage(l10n, e);

    expect(message(const AuthException('x', code: 'invalid_credentials')), l10n.authInvalid);
    expect(message(const AuthException('x', code: 'email_not_confirmed')), l10n.authErrNotConfirmed);
    expect(message(const AuthException('x', code: 'otp_expired')), l10n.authErrCode);
    expect(message(const AuthException('x', code: 'over_email_send_rate_limit')), l10n.authErrRateLimit);
    expect(message(const AuthException('x', statusCode: '429')), l10n.authErrRateLimit);
    expect(message(const AuthException('x', code: 'weak_password')), l10n.authErrWeakPassword);
    expect(
      message(AuthWeakPasswordException(message: 'x', statusCode: '422', reasons: const ['length'])),
      l10n.authErrWeakPassword,
    );
    expect(message(const AuthException('x', code: 'user_already_exists')), l10n.authErrAccountExists);
    expect(message(const AuthException('x', code: 'email_address_invalid')), l10n.authErrEmail);
    expect(message(const AuthException('x', code: 'email_address_not_authorized')), l10n.authErrProvider);
    expect(message(const AuthException('x', code: 'provider_disabled')), l10n.authErrProvider);
    expect(message(AuthRetryableFetchException()), l10n.authErrNetwork);
    expect(message(ClientException('Failed host lookup')), l10n.authErrNetwork);
    expect(message(const AuthException('x', code: 'something_new')), l10n.errorGeneric);
    expect(message(StateError('boom')), l10n.errorGeneric);
  });

  group('a Google or GitHub sign-in that comes back with an error', () {
    final AppLocalizations l10n = AppLocalizationsEn();
    late GoTrueClient auth;

    setUp(() => auth = GoTrueClient(url: 'http://127.0.0.1:9/auth/v1', autoRefreshToken: false));
    tearDown(() => auth.dispose());

    /// What gotrue makes of the link a sign-in came back with; supabase_flutter
    /// reports it on Auth's event stream. [query] is what Auth appends.
    Future<Object> cameBackWith(String query) async {
      try {
        await auth.getSessionFromUrl(Uri.parse('app.wyrd://auth-callback$query'));
      } on Object catch (error) {
        return error;
      }
      fail('the link $query was taken for a session');
    }

    test('is explained by Auth\'s own code, which the link carries as error_code', () async {
      final cancelled = await cameBackWith(
        '?error=access_denied&error_description=The+user+has+denied+your+application+access.'
        '#error=access_denied&error_description=The+user+has+denied+your+application+access.',
      );
      final badState = await cameBackWith(
        '?error=invalid_request&error_code=bad_oauth_state&error_description=OAuth+callback+with+invalid+state',
      );
      final signupsOff = await cameBackWith(
        '?error=access_denied&error_code=signup_disabled&error_description=Signups+not+allowed+for+this+instance',
      );
      final noCode = await cameBackWith('');

      expect(authErrorMessage(l10n, cancelled), l10n.authErrCancelled);
      expect(authErrorMessage(l10n, badState), l10n.authErrProvider);
      expect(authErrorMessage(l10n, signupsOff), l10n.authErrProvider, reason: 'not cancelled by the reader');
      expect(authErrorMessage(l10n, noCode), l10n.errorGeneric);
      for (final error in [cancelled, badState, signupsOff, noCode]) {
        expect(isRedirectSignInError(error), isTrue, reason: '$error');
      }
    });

    test('is told apart from the other errors on Auth\'s event stream', () {
      expect(
        isRedirectSignInError(const AuthException('x', statusCode: 'bad_oauth_callback', code: 'invalid_request')),
        isTrue,
      );
      expect(
        isRedirectSignInError(const AuthException('x', statusCode: 'provider_disabled', code: 'invalid_request')),
        isTrue,
      );
      expect(isRedirectSignInError(const AuthException('x', code: 'oauth_provider_not_supported')), isTrue);
      for (final code in ['flow_state_not_found', 'flow_state_expired', 'bad_code_verifier']) {
        expect(
          isRedirectSignInError(AuthApiException('x', statusCode: '400', code: code)),
          isTrue,
          reason: code,
        );
      }
      expect(isRedirectSignInError(const AuthPKCEGrantCodeExchangeError('No code detected.')), isTrue);

      // Offline, or a token refresh or a stored session that failed.
      expect(isRedirectSignInError(AuthRetryableFetchException(message: 'Failed host lookup')), isFalse);
      expect(isRedirectSignInError(AuthRetryableFetchException(statusCode: '503')), isFalse);
      expect(
        isRedirectSignInError(const AuthException('Initial session is missing data.', code: 'session_missing')),
        isFalse,
      );
      expect(
        isRedirectSignInError(const AuthApiException('x', statusCode: '400', code: 'refresh_token_not_found')),
        isFalse,
      );
      expect(isRedirectSignInError(const FormatException('Unexpected end of input')), isFalse);
    });
  });
}
