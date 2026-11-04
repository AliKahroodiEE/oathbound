# Localization Guide

English (`en`) and Persian (`fa`) are launch languages. The system is built so that adding a
language is a content task.

## 1. Architecture

| Layer | Mechanism |
| --- | --- |
| UI strings | ARB files in `app/lib/l10n/arb/app_<locale>.arb`, compiled by Flutter gen-l10n into `AppLocalizations`. Keys are stable identifiers (`questEditorTitle`), never English text. ICU `plural` and `select` handle grammar. |
| Game content | Achievements, titles, classes, attribute names, adjustment explanations and notification templates are keyed (`achievement_first_oath_name`) in the same ARB files, so rules never contain prose. |
| Direction | Derived from the locale (`Directionality` via `GlobalWidgetsLocalizations`). Widgets use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `TextAlign.start/end`. Direction-implying icons use `Icon(..., textDirection)` or `matchTextDirection: true`. |
| Regional formatting | `LocaleSettings` holds `language`, `region`, `calendar` (gregorian / jalali), `timeZone`, `digits` (latin / native), `firstDayOfWeek`, `measurement`. These are independent of each other and of guild language. Formatting goes through `AppFormatters` only. |
| Fonts | `LocaleTypography` maps scripts to font families and fallback chains (`Latin → Inter`, `Arabic → Vazirmatn`) and to per-script line heights and letter-spacing rules. |
| AI language | `profiles.ai_locale` (defaults to UI language). Server prompts request output in that language; user text is never translated. |
| Server text | Notifications and emails are rendered server-side from keyed templates in `backend/supabase/functions/_shared/i18n/<locale>.json`. |

## 2. Adding a language (example: Arabic `ar`)

1. **Translations:** copy `app_en.arb` to `app_ar.arb`; translate every value. Keep
   placeholders and ICU syntax intact. Set `"@@locale": "ar"`.
2. **Register:** add `Locale('ar')` to `supportedLocales` in
   `app/lib/l10n/locale_registry.dart` with its metadata: native name, script, direction
   (`rtl`), default calendar, default digits, default first day of week.
3. **Direction:** nothing else to do — direction is derived from the registry and all
   layouts are logical.
4. **Fonts:** if the script is new, add the font files under `app/assets/fonts/`, declare
   them in `pubspec.yaml`, and map the script in `LocaleTypography`. Arabic reuses Vazirmatn.
5. **Regional formatting:** `intl` provides number/date symbols for most locales; add a
   calendar implementation only if the locale needs one beyond Gregorian/Jalali.
6. **Server templates:** add `backend/supabase/functions/_shared/i18n/ar.json`.
7. **Generate and verify:**
   ```bash
   cd app
   flutter gen-l10n
   flutter test test/l10n
   ```
   The l10n tests fail on missing keys, extra keys, placeholder mismatches, and untranslated
   values identical to English (allow-list for brand names).
8. **Layout testing:** run golden tests in the new locale
   (`flutter test --tags golden`), and manually check the pseudo-localised
   long-string build (`--dart-define=WYRD_PSEUDO_L10N=true`).
9. **Review:** a native speaker reviews strings in context before release. Machine
   translation may be used for drafts only.

## 3. Rules for developers

- Never concatenate translated fragments; use placeholders.
- Never hard-code `left`/`right`, `TextAlign.left`, `EdgeInsets.only(left: …)`,
  `Alignment.centerLeft`. A lint test greps for these in `lib/`.
- Never format numbers or dates with `toString()`; use `AppFormatters`.
- Wrap user-authored text that may contain mixed scripts with direction auto-detection
  (`Text(..., textDirection: null)` inside `Directionality` is fine; for mixed inline
  content use `BidiText`/Unicode isolates).
- Mirroring is not translation: charts with time on the x-axis run start → end in both
  directions; progress bars fill from the start edge.

## 4. Persian specifics

- Jalali calendar via `shamsi_date`; month names localised; week starts Saturday by default.
- Persian digits (۰–۹) on by default for `fa`, switchable; tabular alignment preserved.
- Use the Persian comma `،`, question mark `؟`, and ZWNJ (U+200C) where required
  (e.g. `می‌خواهم`); translators must preserve ZWNJ in ARB values.
- Line height ≥ 1.6 for body text; no letter-spacing on Arabic script.
