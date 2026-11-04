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
}
