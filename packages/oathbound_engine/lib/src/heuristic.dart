import 'model.dart';
import 'proposal.dart';

/// Inputs available to the offline/fallback evaluator.
class HeuristicInput {
  const HeuristicInput({
    required this.title,
    this.notes = '',
    this.tier = QuestTier.daily,
    this.categoryHint,
    this.declaredMinutes,
    this.estimatedMinutes,
  });

  final String title;
  final String notes;
  final QuestTier tier;

  /// A category the user picked explicitly; always wins over keywords.
  final QuestCategory? categoryHint;
  final int? declaredMinutes;
  final int? estimatedMinutes;
}

/// Deterministic, language-aware (English + Persian) evaluator used when
/// AI is offline, disabled, failing, or not configured. It never invents
/// attribute weights beyond the category defaults.
abstract final class HeuristicEvaluator {
  static EvaluationProposal evaluate(HeuristicInput input) {
    final text = normaliseText('${input.title} ${input.notes}');
    final scores = <QuestCategory, int>{};
    for (final entry in _keywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (_matches(text, keyword)) score++;
      }
      if (score > 0) scores[entry.key] = score;
    }

    QuestCategory category;
    if (input.categoryHint != null) {
      category = input.categoryHint!;
    } else if (scores.isEmpty) {
      category = QuestCategory.other;
    } else {
      final ranked = scores.entries.toList()
        ..sort((a, b) {
          final byScore = b.value.compareTo(a.value);
          return byScore != 0 ? byScore : a.key.index.compareTo(b.key.index);
        });
      category = ranked.first.key;
    }

    final minutes =
        _positive(input.declaredMinutes) ??
        _positive(input.estimatedMinutes) ??
        extractMinutes(text) ??
        _tierDefaultMinutes[input.tier]!;

    var difficulty = minutes < 15
        ? 1
        : minutes < 45
        ? 2
        : minutes < 120
        ? 3
        : 4;
    if (input.tier != QuestTier.daily) difficulty++;
    if (_highStakes.any((k) => _matches(text, k))) difficulty++;
    difficulty = difficulty.clamp(1, 5);

    final weights = category.defaultWeights;
    return EvaluationProposal(
      category: category,
      similarityKey: normaliseSimilarityKey(
        _topic(text) ?? category.name,
        category,
      ),
      difficulty: difficulty,
      estimatedMinutes: minutes.clamp(1, 600),
      attributes: [
        for (final e in weights.entries) AttributeWeight(e.key, e.value),
      ],
      trivial: minutes < 5,
      confidence: scores.isNotEmpty || input.categoryHint != null ? 0.7 : 0.35,
      source: ProposalSource.heuristic,
    );
  }

  /// Lowercase, Persian-normalised text with Latin digits and ZWNJ
  /// replaced by a space so keyword variants match.
  static String normaliseText(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0); // Persian digits
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660); // Arabic-Indic digits
      } else if (rune == 0x064A || rune == 0x0649) {
        buffer.writeCharCode(0x06CC); // Arabic yeh → Persian yeh
      } else if (rune == 0x0643) {
        buffer.writeCharCode(0x06A9); // Arabic kaf → Persian keheh
      } else if (rune == 0x200C) {
        buffer.write(' '); // ZWNJ
      } else if (rune == 0x066B) {
        buffer.write('.'); // Arabic decimal separator
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extracts a duration such as "90m", "1.5 hours", "۲ ساعت" or
  /// "half an hour" from normalised text. Multiple mentions are summed
  /// ("1h 30m" → 90).
  static int? extractMinutes(String normalised) {
    var total = 0.0;
    var found = false;
    final hours = RegExp(
      r'(\d+(?:\.\d+)?)\s*(hours|hour|hrs|hr|h|ساعت)(?![a-z])',
    );
    for (final m in hours.allMatches(normalised)) {
      total += double.parse(m.group(1)!) * 60;
      found = true;
    }
    final minutes = RegExp(
      r'(\d+(?:\.\d+)?)\s*(minutes|minute|mins|min|m|دقیقه)(?![a-z])',
    );
    for (final m in minutes.allMatches(normalised)) {
      total += double.parse(m.group(1)!);
      found = true;
    }
    if (!found) {
      for (final e in _wordDurations.entries) {
        if (normalised.contains(e.key)) return e.value;
      }
      return null;
    }
    return total.round();
  }

  static String? _topic(String normalised) {
    final keywords = {for (final list in _keywords.values) ...list};
    for (final token in normalised.split(RegExp(r'[\s.,;:!?،؟()\[\]"]+'))) {
      if (token.length < 3) continue;
      if (RegExp(r'^\d').hasMatch(token)) continue;
      if (_stopwords.contains(token)) continue;
      if (keywords.any((k) => _matches(token, k))) continue;
      return token;
    }
    return null;
  }

  static bool _matches(String text, String keyword) {
    final isLatin = RegExp(r'^[a-z0-9 \-]+$').hasMatch(keyword);
    if (!isLatin) return text.contains(keyword);
    return RegExp('(^|[^a-z])${RegExp.escape(keyword)}').hasMatch(text);
  }

  static int? _positive(int? v) => v != null && v > 0 ? v : null;

  static const Map<QuestTier, int> _tierDefaultMinutes = {
    QuestTier.daily: 25,
    QuestTier.contract: 90,
    QuestTier.objective: 120,
  };

  static const Map<String, int> _wordDurations = {
    'half an hour': 30,
    'an hour': 60,
    'one hour': 60,
    'two hours': 120,
    'نیم ساعت': 30,
    'یک ساعت': 60,
    'یه ساعت': 60,
    'دو ساعت': 120,
  };

  static const Set<String> _stopwords = {
    'for', 'the', 'and', 'with', 'from', 'into', 'some', 'my', 'our', 'about',
    'today', 'tomorrow', 'tonight', 'morning', 'evening', 'minutes', 'minute',
    'mins', 'hours', 'hour', 'more', 'session',
    'برای', 'با', 'از', 'در', 'را', 'که', 'این', 'آن', 'یک', 'دقیقه',
    'ساعت', 'امروز', 'فردا', 'امشب', 'صبح', 'عصر', 'کمی', 'جلسه',
  };

  static const List<String> _highStakes = [
    'exam', 'final', 'interview', 'competition', 'presentation', 'deadline',
    'defense', 'امتحان', 'آزمون', 'مصاحبه', 'مسابقه', 'ارائه', 'کنکور',
    'دفاع',
  ];

  static const Map<QuestCategory, List<String>> _keywords = {
    QuestCategory.study: [
      'study', 'learn', 'lecture', 'course', 'homework', 'assignment', 'exam',
      'revise', 'revision', 'flashcard', 'tutorial', 'class', 'research',
      'thesis', 'practice problems', 'lesson',
      'درس', 'مطالعه', 'یادگیری', 'امتحان', 'آزمون', 'تکلیف', 'کلاس',
      'دانشگاه', 'پایان نامه', 'تحقیق', 'جزوه', 'دوره آموزشی', 'کنکور',
    ],
    QuestCategory.reading: [
      'read', 'book', 'chapter', 'pages', 'novel', 'article',
      'کتاب', 'خواندن', 'بخوانم', 'فصل', 'صفحه', 'رمان', 'مقاله',
    ],
    QuestCategory.work: [
      'work', 'meeting', 'report', 'project', 'client', 'deploy',
      'code review', 'presentation', 'shift', 'proposal', 'sprint',
      'کار', 'جلسه', 'گزارش', 'پروژه', 'مشتری', 'ارائه', 'شیفت',
    ],
    QuestCategory.fitness: [
      'gym', 'workout', 'run', 'jog', 'exercise', 'lift', 'weights',
      'push-up', 'pushup', 'squat', 'swim', 'cycling', 'bike', 'hike',
      'walk', 'steps', 'training', 'football', 'basketball', 'climb',
      'ورزش', 'باشگاه', 'دویدن', 'تمرین بدنی', 'وزنه', 'شنا', 'دوچرخه',
      'کوهنوردی', 'پیاده روی', 'فوتبال', 'والیبال', 'بدنسازی',
    ],
    QuestCategory.health: [
      'sleep', 'doctor', 'dentist', 'medicine', 'meds', 'water', 'vitamin',
      'healthy', 'stretch', 'nap', 'therapy', 'checkup',
      'خواب', 'دکتر', 'دندانپزشک', 'دارو', 'ویتامین', 'سلامت', 'رژیم',
      'استراحت', 'کشش', 'چکاپ',
    ],
    QuestCategory.mindfulness: [
      'meditat', 'breath', 'journal', 'gratitude', 'mindful', 'reflect',
      'مدیتیشن', 'مراقبه', 'تنفس', 'ژورنال', 'شکرگزاری', 'تامل',
    ],
    QuestCategory.creative: [
      'draw', 'paint', 'sketch', 'design', 'writing', 'compose', 'music',
      'guitar', 'piano', 'violin', 'sing', 'photo', 'film', 'poem', 'story',
      'craft', 'knit', 'calligraph',
      'نقاشی', 'طراحی', 'نوشتن', 'داستان', 'شعر', 'موسیقی', 'گیتار',
      'پیانو', 'ویولن', 'سه تار', 'آواز', 'عکاسی', 'فیلم', 'خوشنویسی',
    ],
    QuestCategory.social: [
      'call', 'friend', 'family', 'mom', 'dad', 'parents', 'visit', 'party',
      'hangout', 'volunteer', 'community', 'dinner with', 'catch up',
      'دوست', 'خانواده', 'مادر', 'پدر', 'مامان', 'بابا', 'تماس', 'دیدار',
      'مهمانی', 'ملاقات', 'داوطلب',
    ],
    QuestCategory.chores: [
      'clean', 'laundry', 'dishes', 'tidy', 'vacuum', 'groceries', 'cook',
      'organize', 'organise', 'declutter', 'garden', 'repair',
      'تمیز', 'نظافت', 'لباس', 'ظرف', 'مرتب', 'خرید', 'آشپزی', 'باغچه',
      'تعمیر', 'جارو',
    ],
    QuestCategory.admin: [
      'bill', 'pay', 'tax', 'bank', 'email', 'paperwork', 'form',
      'appointment', 'budget', 'insurance', 'renew', 'invoice',
      'قبض', 'پرداخت', 'مالیات', 'بانک', 'ایمیل', 'اداری', 'فرم', 'نوبت',
      'بودجه', 'بیمه', 'تمدید',
    ],
  };
}
