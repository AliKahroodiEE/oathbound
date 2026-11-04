/**
 * Deterministic chronicle used whenever AI is unavailable or declined
 * (generate-chronicle). Built only from the SQL facts object, in English or
 * Persian, with locale digits and the user's calendar for dates. Like the AI
 * chronicle it states facts without judgement or generic motivation.
 */
import { formatDate, resolveLocale, t } from './i18n.ts';

export type Period = 'week' | 'month' | 'year';

export interface Totals {
  completions: number;
  deeds: number;
  minutes: number;
  hours: number;
  xp: number;
  activeDays: number;
  restDays?: number;
}

export interface ChronicleFacts {
  period: Period;
  periodStart: string;
  periodEnd: string;
  days?: number;
  totals: Totals;
  previous: Totals;
  xpByAttribute: Record<string, number>;
  attributeDeltas: Record<string, number>;
  topActivities: Array<{ key: string; category: string | null; completions: number; minutes: number; hours: number; xp: number }>;
  records: { bestDay?: { date: string; xp: number; minutes: number }; longestSession?: { minutes: number; hours: number; key: string } };
  achievementsUnlocked: string[];
  level: { start: number; end: number };
  [key: string]: unknown;
}

function activityLabel(locale: string, activity: ChronicleFacts['topActivities'][number]): string {
  const category = activity.category ?? activity.key.split('.')[0] ?? 'other';
  const label = t(locale, `categories.${category}`);
  const topic = activity.key.includes('.') ? activity.key.split('.').slice(1).join('.').replace(/-/g, ' ') : '';
  // Persian prose keeps to the localized category; English adds the topic.
  return locale === 'en' && topic !== '' && topic !== category ? `${label} (${topic})` : label;
}

export function templateChronicle(facts: ChronicleFacts, requestedLocale: string, calendar: string | null): string {
  const locale = resolveLocale(requestedLocale);
  const period = t(locale, `chronicle.periodNoun.${facts.period}`);
  const totals = facts.totals;
  if (totals.completions === 0) return t(locale, 'chronicle.quiet', { period });

  const deeds = totals.deeds > 0 ? totals.deeds : totals.completions;
  const sentences: string[] = [
    t(locale, 'chronicle.opening', { period, count: deeds, deeds, activeDays: totals.activeDays, hours: totals.hours }),
  ];

  const [topAttribute, topXp] = Object.entries(facts.xpByAttribute)
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))[0] ?? ['', 0];
  if (topAttribute !== '' && topXp > 0) {
    sentences.push(t(locale, 'chronicle.growth', {
      attribute: t(locale, `attributes.${topAttribute}`),
      attributeXp: topXp,
      xp: totals.xp,
    }));
  }

  const top = facts.topActivities[0];
  if (top && top.minutes > 0) {
    sentences.push(t(locale, 'chronicle.topActivity', {
      activity: activityLabel(locale, top),
      activityHours: top.hours,
      activityCount: top.completions,
    }));
  }

  if (facts.previous.completions > 0) {
    sentences.push(t(locale, 'chronicle.comparison', { period, previousHours: facts.previous.hours, hours: totals.hours }));
  }

  const bestDay = facts.records.bestDay;
  if (bestDay && bestDay.xp > 0) {
    sentences.push(t(locale, 'chronicle.bestDay', {
      bestDay: formatDate(locale, bestDay.date, calendar),
      bestDayXp: bestDay.xp,
    }));
  }

  sentences.push(facts.level.end > facts.level.start
    ? t(locale, 'chronicle.levelUp', { levelStart: facts.level.start, levelEnd: facts.level.end })
    : t(locale, 'chronicle.level', { levelEnd: facts.level.end }));

  if (facts.achievementsUnlocked.length > 0) {
    sentences.push(t(locale, 'chronicle.achievements', { count: facts.achievementsUnlocked.length }));
  }
  if ((totals.restDays ?? 0) > 0) {
    sentences.push(t(locale, 'chronicle.restDays', { count: totals.restDays as number }));
  }
  return sentences.join(' ');
}
