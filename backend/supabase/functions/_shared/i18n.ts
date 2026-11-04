/**
 * Server-side localisation (docs/localization.md §1 "Server text").
 *
 * Catalogs live in `_shared/i18n/<locale>.json` with keyed templates and
 * `{placeholder}` parameters. Plural forms use `<key>_one` / `<key>_other`
 * selected by the `count` parameter (Persian only needs `_other`).
 * Numbers are formatted for the locale (Persian digits for `fa`). Parameters
 * that carry user-authored text are inserted verbatim (FR-10).
 */
import en from './i18n/en.json' with { type: 'json' };
import fa from './i18n/fa.json' with { type: 'json' };

type Catalog = { [key: string]: string | Catalog };

const CATALOGS: Record<string, Catalog> = {
  en: en as unknown as Catalog,
  fa: fa as unknown as Catalog,
};

export const SUPPORTED_LOCALES = Object.keys(CATALOGS);

export type Params = Record<string, string | number>;

/** Best supported locale for a BCP-47 tag ("fa-IR" → "fa"), English otherwise. */
export function resolveLocale(tag: string | null | undefined): string {
  if (!tag) return 'en';
  const lower = tag.toLowerCase();
  if (CATALOGS[lower]) return lower;
  const language = lower.split(/[-_]/)[0] ?? '';
  return CATALOGS[language] ? language : 'en';
}

function lookup(catalog: Catalog, key: string): string | undefined {
  let node: string | Catalog | undefined = catalog;
  for (const part of key.split('.')) {
    if (typeof node !== 'object' || node === null) return undefined;
    node = node[part];
  }
  return typeof node === 'string' ? node : undefined;
}

export function hasTemplate(locale: string, key: string): boolean {
  const catalog = CATALOGS[resolveLocale(locale)] as Catalog;
  return lookup(catalog, key) !== undefined || lookup(catalog, `${key}_other`) !== undefined ||
    lookup(CATALOGS.en as Catalog, key) !== undefined || lookup(CATALOGS.en as Catalog, `${key}_other`) !== undefined;
}

export function formatNumber(locale: string, value: number, maximumFractionDigits = 1): string {
  const tag = resolveLocale(locale) === 'fa' ? 'fa-IR' : resolveLocale(locale);
  return new Intl.NumberFormat(tag, { maximumFractionDigits }).format(value);
}

/** Formats a calendar date (YYYY-MM-DD) in the user's language and calendar. */
export function formatDate(locale: string, isoDate: string, calendar: string | null): string {
  const resolved = resolveLocale(locale);
  const base = resolved === 'fa' ? 'fa-IR' : resolved;
  const tag = calendar === 'jalali' ? `${base}-u-ca-persian` : `${base}-u-ca-gregory`;
  const date = new Date(`${isoDate}T12:00:00Z`);
  return new Intl.DateTimeFormat(tag, {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    timeZone: 'UTC',
  }).format(date);
}

/**
 * Renders `key` for `locale`, falling back to English for missing keys.
 * Numeric parameters are locale-formatted; strings are inserted as-is.
 */
export function t(locale: string, key: string, params: Params = {}): string {
  const resolved = resolveLocale(locale);
  const catalogs = [CATALOGS[resolved] as Catalog, CATALOGS.en as Catalog];
  const count = typeof params['count'] === 'number' ? (params['count'] as number) : undefined;
  let template: string | undefined;
  for (const catalog of catalogs) {
    if (count !== undefined) {
      template = (count === 1 ? lookup(catalog, `${key}_one`) : undefined) ?? lookup(catalog, `${key}_other`);
    }
    template ??= lookup(catalog, key);
    if (template !== undefined) break;
  }
  if (template === undefined) throw new Error(`Missing i18n key ${key}`);
  return template.replace(/\{(\w+)\}/g, (whole, name: string) => {
    const value = params[name];
    if (value === undefined) return whole;
    return typeof value === 'number' ? formatNumber(resolved, value) : value;
  });
}
