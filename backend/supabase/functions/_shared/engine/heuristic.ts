/**
 * Deterministic, language-aware (English + Persian) evaluator used when AI is
 * offline, disabled, failing, rate-limited or not configured. It never
 * invents attribute weights beyond the category defaults.
 *
 * Twin of `packages/wyrd_engine/lib/src/heuristic.dart`; keyword lists
 * and thresholds must stay identical so the client's provisional result and
 * the server's fallback result agree.
 */
import {
  categoryIndex,
  clamp,
  defaultWeightEntries,
  type EvaluationProposal,
  normaliseSimilarityKey,
  type QuestCategory,
  type QuestTier,
  roundHalfAwayFromZero,
} from './model.ts';

/** Inputs available to the offline/fallback evaluator. */
export interface HeuristicInput {
  title: string;
  notes?: string;
  tier?: QuestTier;
  /** A category the user picked explicitly; always wins over keywords. */
  categoryHint?: QuestCategory | null;
  declaredMinutes?: number | null;
  estimatedMinutes?: number | null;
}

export function evaluateHeuristic(input: HeuristicInput): EvaluationProposal {
  const tier: QuestTier = input.tier ?? 'daily';
  const text = normaliseText(`${input.title} ${input.notes ?? ''}`);
  const scores = new Map<QuestCategory, number>();
  for (const [category, keywords] of KEYWORD_ENTRIES) {
    let score = 0;
    for (const keyword of keywords) {
      if (matches(text, keyword)) score++;
    }
    if (score > 0) scores.set(category, score);
  }

  let category: QuestCategory;
  if (input.categoryHint !== undefined && input.categoryHint !== null) {
    category = input.categoryHint;
  } else if (scores.size === 0) {
    category = 'other';
  } else {
    const ranked = [...scores.entries()].sort((a, b) => {
      const byScore = b[1] - a[1];
      return byScore !== 0 ? byScore : categoryIndex(a[0]) - categoryIndex(b[0]);
    });
    category = (ranked[0] as [QuestCategory, number])[0];
  }

  const minutes = positive(input.declaredMinutes) ??
    positive(input.estimatedMinutes) ??
    extractMinutes(text) ??
    TIER_DEFAULT_MINUTES[tier];

  let difficulty = minutes < 15 ? 1 : minutes < 45 ? 2 : minutes < 120 ? 3 : 4;
  if (tier !== 'daily') difficulty++;
  if (HIGH_STAKES.some((k) => matches(text, k))) difficulty++;
  difficulty = clamp(difficulty, 1, 5);

  return {
    category,
    similarityKey: normaliseSimilarityKey(topic(text) ?? category, category),
    difficulty,
    estimatedMinutes: clamp(minutes, 1, 600),
    attributes: defaultWeightEntries(category).map(([attribute, weight]) => ({
      attribute,
      weight,
      reason: '',
    })),
    trivial: minutes < 5,
    confidence: scores.size > 0 || (input.categoryHint ?? null) !== null ? 0.7 : 0.35,
    summary: '',
    source: 'heuristic',
  };
}

/**
 * Lowercase, Persian-normalised text with Latin digits; ZWNJ is replaced by
 * a space so keyword variants match.
 */
export function normaliseText(input: string): string {
  let out = '';
  for (const ch of input.toLowerCase()) {
    const rune = ch.codePointAt(0) as number;
    if (rune >= 0x06f0 && rune <= 0x06f9) {
      out += String.fromCharCode(0x30 + rune - 0x06f0); // Persian digits
    } else if (rune >= 0x0660 && rune <= 0x0669) {
      out += String.fromCharCode(0x30 + rune - 0x0660); // Arabic-Indic digits
    } else if (rune === 0x064a || rune === 0x0649) {
      out += 'ی'; // Arabic yeh → Persian yeh
    } else if (rune === 0x0643) {
      out += 'ک'; // Arabic kaf → Persian keheh
    } else if (rune === 0x200c) {
      out += ' '; // ZWNJ
    } else if (rune === 0x066b) {
      out += '.'; // Arabic decimal separator
    } else {
      out += ch;
    }
  }
  return out.replace(/\s+/g, ' ').trim();
}

/**
 * Extracts a duration such as "90m", "1.5 hours", "۲ ساعت" or "half an
 * hour" from normalised text. Multiple mentions are summed ("1h 30m" → 90).
 */
export function extractMinutes(normalised: string): number | null {
  let total = 0;
  let found = false;
  const hours = /(\d+(?:\.\d+)?)\s*(hours|hour|hrs|hr|h|ساعت)(?![a-z])/g;
  for (const m of normalised.matchAll(hours)) {
    total += parseFloat(m[1] as string) * 60;
    found = true;
  }
  const minutes = /(\d+(?:\.\d+)?)\s*(minutes|minute|mins|min|m|دقیقه)(?![a-z])/g;
  for (const m of normalised.matchAll(minutes)) {
    total += parseFloat(m[1] as string);
    found = true;
  }
  if (!found) {
    for (const [phrase, value] of WORD_DURATIONS) {
      if (normalised.includes(phrase)) return value;
    }
    return null;
  }
  return roundHalfAwayFromZero(total);
}

function topic(normalised: string): string | null {
  for (const token of normalised.split(/[\s.,;:!?،؟()[\]"]+/)) {
    if (token.length < 3) continue;
    if (/^\d/.test(token)) continue;
    if (STOPWORDS.has(token)) continue;
    if (ALL_KEYWORDS.some((k) => matches(token, k))) continue;
    return token;
  }
  return null;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\/-]/g, '\\$&');
}

const LATIN_KEYWORD = /^[a-z0-9 \-]+$/;
const keywordPatterns = new Map<string, RegExp>();

function matches(text: string, keyword: string): boolean {
  if (!LATIN_KEYWORD.test(keyword)) return text.includes(keyword);
  let pattern = keywordPatterns.get(keyword);
  if (pattern === undefined) {
    // Latin keywords must start at a word boundary ("run" ≠ "brunch") but may
    // be a prefix ("meditat" matches "meditation").
    pattern = new RegExp(`(^|[^a-z])${escapeRegExp(keyword)}`);
    keywordPatterns.set(keyword, pattern);
  }
  return pattern.test(text);
}

function positive(value: number | null | undefined): number | null {
  return value !== undefined && value !== null && value > 0 ? value : null;
}

const TIER_DEFAULT_MINUTES: Readonly<Record<QuestTier, number>> = {
  daily: 25,
  contract: 90,
  objective: 120,
};

/** Insertion order matters: the first contained phrase wins. */
const WORD_DURATIONS: ReadonlyArray<readonly [string, number]> = [
  ['half an hour', 30],
  ['an hour', 60],
  ['one hour', 60],
  ['two hours', 120],
  ['نیم ساعت', 30],
  ['یک ساعت', 60],
  ['یه ساعت', 60],
  ['دو ساعت', 120],
];

const STOPWORDS: ReadonlySet<string> = new Set([
  'for', 'the', 'and', 'with', 'from', 'into', 'some', 'my', 'our', 'about',
  'today', 'tomorrow', 'tonight', 'morning', 'evening', 'minutes', 'minute',
  'mins', 'hours', 'hour', 'more', 'session',
  'برای', 'با', 'از', 'در', 'را', 'که', 'این', 'آن', 'یک', 'دقیقه',
  'ساعت', 'امروز', 'فردا', 'امشب', 'صبح', 'عصر', 'کمی', 'جلسه',
]);

const HIGH_STAKES: readonly string[] = [
  'exam', 'final', 'interview', 'competition', 'presentation', 'deadline',
  'defense', 'امتحان', 'آزمون', 'مصاحبه', 'مسابقه', 'ارائه', 'کنکور',
  'دفاع',
];

/** Keyword lists in category declaration order (ties resolve by category order). */
const KEYWORD_ENTRIES: ReadonlyArray<readonly [QuestCategory, readonly string[]]> = [
  ['study', [
    'study', 'learn', 'lecture', 'course', 'homework', 'assignment', 'exam',
    'revise', 'revision', 'flashcard', 'tutorial', 'class', 'research',
    'thesis', 'practice problems', 'lesson',
    'درس', 'مطالعه', 'یادگیری', 'امتحان', 'آزمون', 'تکلیف', 'کلاس',
    'دانشگاه', 'پایان نامه', 'تحقیق', 'جزوه', 'دوره آموزشی', 'کنکور',
  ]],
  ['reading', [
    'read', 'book', 'chapter', 'pages', 'novel', 'article',
    'کتاب', 'خواندن', 'بخوانم', 'فصل', 'صفحه', 'رمان', 'مقاله',
  ]],
  ['work', [
    'work', 'meeting', 'report', 'project', 'client', 'deploy',
    'code review', 'presentation', 'shift', 'proposal', 'sprint',
    'کار', 'جلسه', 'گزارش', 'پروژه', 'مشتری', 'ارائه', 'شیفت',
  ]],
  ['fitness', [
    'gym', 'workout', 'run', 'jog', 'exercise', 'lift', 'weights',
    'push-up', 'pushup', 'squat', 'swim', 'cycling', 'bike', 'hike',
    'walk', 'steps', 'training', 'football', 'basketball', 'climb',
    'ورزش', 'باشگاه', 'دویدن', 'تمرین بدنی', 'وزنه', 'شنا', 'دوچرخه',
    'کوهنوردی', 'پیاده روی', 'فوتبال', 'والیبال', 'بدنسازی',
  ]],
  ['health', [
    'sleep', 'doctor', 'dentist', 'medicine', 'meds', 'water', 'vitamin',
    'healthy', 'stretch', 'nap', 'therapy', 'checkup',
    'خواب', 'دکتر', 'دندانپزشک', 'دارو', 'ویتامین', 'سلامت', 'رژیم',
    'استراحت', 'کشش', 'چکاپ',
  ]],
  ['mindfulness', [
    'meditat', 'breath', 'journal', 'gratitude', 'mindful', 'reflect',
    'مدیتیشن', 'مراقبه', 'تنفس', 'ژورنال', 'شکرگزاری', 'تامل',
  ]],
  ['creative', [
    'draw', 'paint', 'sketch', 'design', 'writing', 'compose', 'music',
    'guitar', 'piano', 'violin', 'sing', 'photo', 'film', 'poem', 'story',
    'craft', 'knit', 'calligraph',
    'نقاشی', 'طراحی', 'نوشتن', 'داستان', 'شعر', 'موسیقی', 'گیتار',
    'پیانو', 'ویولن', 'سه تار', 'آواز', 'عکاسی', 'فیلم', 'خوشنویسی',
  ]],
  ['social', [
    'call', 'friend', 'family', 'mom', 'dad', 'parents', 'visit', 'party',
    'hangout', 'volunteer', 'community', 'dinner with', 'catch up',
    'دوست', 'خانواده', 'مادر', 'پدر', 'مامان', 'بابا', 'تماس', 'دیدار',
    'مهمانی', 'ملاقات', 'داوطلب',
  ]],
  ['chores', [
    'clean', 'laundry', 'dishes', 'tidy', 'vacuum', 'groceries', 'cook',
    'organize', 'organise', 'declutter', 'garden', 'repair',
    'تمیز', 'نظافت', 'لباس', 'ظرف', 'مرتب', 'خرید', 'آشپزی', 'باغچه',
    'تعمیر', 'جارو',
  ]],
  ['admin', [
    'bill', 'pay', 'tax', 'bank', 'email', 'paperwork', 'form',
    'appointment', 'budget', 'insurance', 'renew', 'invoice',
    'قبض', 'پرداخت', 'مالیات', 'بانک', 'ایمیل', 'اداری', 'فرم', 'نوبت',
    'بودجه', 'بیمه', 'تمدید',
  ]],
];

const ALL_KEYWORDS: readonly string[] = [
  ...new Set(KEYWORD_ENTRIES.flatMap(([, keywords]) => keywords)),
];
