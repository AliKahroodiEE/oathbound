import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:wyrd/features/guilds/guild_hall_screen.dart';
import 'package:wyrd/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('a rate-limited reaction or comment asks for a minute', () {
    const limited = PostgrestException(message: 'too many reaction changes', code: '54000', hint: 'rate_limited');
    expect(guildErrorMessage(en, limited), en.actionRateLimited);
  });

  test('other refusals, such as a full guild, get the general message', () {
    const full = PostgrestException(message: 'this guild is full', code: '54000', hint: 'guild_full');
    expect(guildErrorMessage(en, full), en.errorGeneric);
    expect(guildErrorMessage(en, StateError('offline')), en.errorGeneric);
  });
}
