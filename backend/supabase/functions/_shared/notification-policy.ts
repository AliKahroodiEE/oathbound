/**
 * Pure notification rules (ADR-007, requirements N1–N3). Kept free of I/O
 * so they can be unit-tested under Node and reused by any sender.
 */

export const NOTIFICATION_CATEGORIES = [
  'reminders',
  'guild_reactions',
  'guild_comments',
  'challenge_milestones',
  'objectives',
  'weekly_summary',
  'briefing',
  're_engagement',
] as const;
export type NotificationCategory = (typeof NOTIFICATION_CATEGORIES)[number];

export function isNotificationCategory(value: unknown): value is NotificationCategory {
  return typeof value === 'string' && (NOTIFICATION_CATEGORIES as readonly string[]).includes(value);
}

/** Defaults mirror public.notification_prefs; briefing is opt-in. */
export const DEFAULT_CATEGORY_TOGGLES: Readonly<Record<NotificationCategory, boolean>> = {
  reminders: true,
  guild_reactions: true,
  guild_comments: true,
  challenge_milestones: true,
  objectives: true,
  weekly_summary: true,
  briefing: false,
  re_engagement: true,
};

export const DEFAULT_QUIET_START = '22:00';
export const DEFAULT_QUIET_END = '08:00';
export const DEFAULT_DAILY_CAP = 5;

/** Reminders are excluded from the daily cap (requirements N3). */
export const CAP_EXEMPT: ReadonlySet<NotificationCategory> = new Set(['reminders']);

/** At most one re-engagement notification per 7 days (ADR-007). */
export const RE_ENGAGEMENT_INTERVAL_MS = 7 * 24 * 3600 * 1000;

/** Reactions to the same deed within this window are batched into one push. */
export const BATCH_WINDOW_MS = 30 * 60 * 1000;

/**
 * Category toggle with defaults. Re-engagement has no toggle of its own in
 * the settings screen and follows the weekly-summary toggle unless set.
 */
export function categoryEnabled(categories: Record<string, unknown> | null | undefined, category: NotificationCategory): boolean {
  const toggles = categories ?? {};
  const own = toggles[category];
  if (typeof own === 'boolean') return own;
  if (category === 're_engagement') {
    const summary = toggles['weekly_summary'];
    if (typeof summary === 'boolean') return summary;
  }
  return DEFAULT_CATEGORY_TOGGLES[category];
}

/** "HH:MM" or "HH:MM:SS" → minutes after midnight. */
export function minutesOfDay(time: string): number {
  const match = /^(\d{1,2}):(\d{2})/.exec(time.trim());
  if (!match) throw new RangeError(`invalid time ${time}`);
  return Number(match[1]) * 60 + Number(match[2]);
}

/** Local date (YYYY-MM-DD) and minutes after midnight in an IANA time zone. */
export function localClock(timeZone: string, now: Date): { localDay: string; minutes: number } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(now);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '00';
  return {
    localDay: `${get('year')}-${get('month')}-${get('day')}`,
    minutes: Number(get('hour')) * 60 + Number(get('minute')),
  };
}

/** Quiet hours may wrap midnight (22:00–08:00). Equal bounds mean "off". */
export function inQuietHours(start: string, end: string, minutes: number): boolean {
  const s = minutesOfDay(start);
  const e = minutesOfDay(end);
  if (s === e) return false;
  return s < e ? minutes >= s && minutes < e : minutes >= s || minutes < e;
}

/** Short excerpt of user-authored text for a notification body (never rewritten). */
export function excerpt(text: string, maxLength = 80): string {
  const collapsed = text.replace(/\s+/g, ' ').trim();
  return collapsed.length <= maxLength ? collapsed : `${collapsed.slice(0, maxLength - 1).trimEnd()}…`;
}
