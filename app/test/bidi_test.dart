import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/core/format/bidi.dart';
import 'package:wyrd/core/format/formatters.dart';
import 'package:wyrd/core/locale/regional_settings.dart';
import 'package:wyrd/l10n/generated/app_localizations.dart';

void main() {
  test('first strong character decides direction', () {
    expect(userTextDirection('۳۰ دقیقه مطالعه'), TextDirection.rtl);
    expect(userTextDirection('30 min study'), TextDirection.ltr);
    expect(userTextDirection('Python تمرین'), TextDirection.ltr);
    expect(userTextDirection('مطالعه Python'), TextDirection.rtl);
    expect(userTextDirection('123 456'), isNull);
  });

  test('signed numbers keep their sign on the left in RTL text', () {
    final f = AppFormatters(
      RegionalSettings.defaultsFor(const Locale('fa')),
      lookupAppLocalizations(const Locale('fa')),
    );
    expect(f.signedNumber(12), '\u200E+۱۲');
    expect(f.signedNumber(-3).startsWith('\u200E'), isTrue);
    expect(f.signedPercent(-0.08).startsWith('\u200E'), isTrue);
    expect(f.signedPercent(0.08).startsWith('\u200E+'), isTrue);
  });
}
