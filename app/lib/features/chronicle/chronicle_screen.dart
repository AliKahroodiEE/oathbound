import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../app/providers.dart';
import '../../core/format/formatters.dart';
import '../../data/models.dart';
import '../../data/repositories/character_repository.dart';
import '../../design/components/panel.dart';
import '../../design/components/progress.dart';
import '../../design/components/states.dart';
import '../../design/sigils.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';

enum ChroniclePeriod { week, month, year }

/// Weekly, monthly and yearly analytics with a written summary
/// (requirements §4.7, ux-spec §3 "Chronicle").
class ChronicleScreen extends ConsumerStatefulWidget {
  const ChronicleScreen({super.key});

  @override
  ConsumerState<ChronicleScreen> createState() => _ChronicleScreenState();
}

class _ChronicleScreenState extends ConsumerState<ChronicleScreen> {
  ChroniclePeriod _period = ChroniclePeriod.week;
  int _offset = 0;

  PeriodRange _range(AppFormatters f, int firstWeekday, int offset) {
    final now = DateTime.now();
    switch (_period) {
      case ChroniclePeriod.week:
        final today = DateTime(now.year, now.month, now.day);
        final back = (today.weekday - firstWeekday) % 7;
        final start = DateTime(today.year, today.month, today.day - back + 7 * offset);
        return (start: start, end: DateTime(start.year, start.month, start.day + 7));
      case ChroniclePeriod.month:
        final start = f.addMonths(f.startOfMonth(now), offset);
        return (start: start, end: f.addMonths(start, 1));
      case ChroniclePeriod.year:
        final start = f.addYears(f.startOfYear(now), offset);
        return (start: start, end: f.addYears(start, 1));
    }
  }

  String _label(AppFormatters f, PeriodRange r) => switch (_period) {
    ChroniclePeriod.week => '${f.dayMonth(r.start)} – ${f.dayMonth(r.end.subtract(const Duration(days: 1)))}',
    ChroniclePeriod.month => f.monthYear(r.start),
    ChroniclePeriod.year => f.year(r.start),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final firstWeekday = ref.watch(regionalProvider).firstWeekday;
    final range = _range(f, firstWeekday, _offset);
    var previous = _range(f, firstWeekday, _offset - 1);
    // An unfinished period is compared with the same elapsed span of the
    // previous one, never with a whole period (no false "−60 %").
    final inProgress = _offset == 0;
    if (inProgress) {
      final now = DateTime.now();
      final elapsedDays = DateTime(now.year, now.month, now.day).difference(range.start).inDays + 1;
      final cut = DateTime(previous.start.year, previous.start.month, previous.start.day + elapsedDays);
      previous = (start: previous.start, end: cut.isBefore(previous.end) ? cut : previous.end);
    }
    final stats = ref.watch(periodStatsProvider(range));
    final prevStats = ref.watch(periodStatsProvider(previous)).value;
    final text = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.chronicleTitle),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/chronicle/ledger'),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text(l10n.ledgerTitle),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        children: [
          SegmentedButton<ChroniclePeriod>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ChroniclePeriod.week, label: Text(l10n.periodWeek)),
              ButtonSegment(value: ChroniclePeriod.month, label: Text(l10n.periodMonth)),
              ButtonSegment(value: ChroniclePeriod.year, label: Text(l10n.periodYear)),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() {
              _period = s.first;
              _offset = 0;
            }),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              IconButton(
                tooltip: l10n.previousPeriod,
                icon: const _DirectionalChevron(back: true),
                onPressed: () => setState(() => _offset--),
              ),
              Expanded(
                child: Text(_label(f, range), style: text.titleMedium, textAlign: TextAlign.center),
              ),
              IconButton(
                tooltip: l10n.nextPeriod,
                icon: const _DirectionalChevron(back: false),
                onPressed: _offset >= 0 ? null : () => setState(() => _offset++),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          stats.when(
            loading: () => const LoadingPanels(count: 2),
            error: (_, _) => ErrorState(message: l10n.errorGeneric),
            data: (s) {
              final panels = [
                _SummaryPanel(stats: s, previous: prevStats, period: _period, samePoint: inProgress),
                _XpChartPanel(stats: s, period: _period),
                _DistributionPanel(stats: s, previous: prevStats),
                _RhythmPanel(stats: s, period: _period),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (final p in panels) ...[p, const SizedBox(height: AppSpace.lg)],
                  ],
                );
              }
              return Column(
                children: [
                  panels[0],
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: panels[1]),
                      const SizedBox(width: AppSpace.lg),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            panels[2],
                            const SizedBox(height: AppSpace.lg),
                            panels[3],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends ConsumerWidget {
  const _SummaryPanel({required this.stats, required this.previous, required this.period, this.samePoint = false});

  final PeriodStats stats;
  final PeriodStats? previous;
  final ChroniclePeriod period;
  final bool samePoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    String? change(num now, num? before) {
      if (before == null || before == 0) return null;
      final delta = f.signedPercent((now - before) / before);
      return samePoint ? l10n.comparedToSamePoint(delta) : l10n.comparedToPrevious(delta);
    }

    final tiles = [
      (
        l10n.statCompletions,
        f.number(stats.completions),
        change(stats.completions, previous?.completions),
        Icons.task_alt_rounded,
        AppColors.ember,
      ),
      (
        l10n.statMinutes,
        f.duration(stats.minutes),
        change(stats.minutes, previous?.minutes),
        Icons.hourglass_bottom_rounded,
        AppColors.attrIntelligence,
      ),
      (
        l10n.statXp,
        f.number(stats.totalXp),
        change(stats.totalXp, previous?.totalXp),
        Icons.bolt_rounded,
        AppColors.gold,
      ),
      (
        l10n.statActiveDays,
        f.number(stats.activeDays.length),
        null,
        Icons.calendar_month_rounded,
        AppColors.attrVitality,
      ),
    ];
    final periodName = switch (period) {
      ChroniclePeriod.week => l10n.periodWeekNoun,
      ChroniclePeriod.month => l10n.periodMonthNoun,
      ChroniclePeriod.year => l10n.periodYearNoun,
    };
    final strongest = stats.strongest;
    return Panel(
      title: l10n.writtenChronicle,
      icon: Icons.auto_stories_rounded,
      accent: AppColors.arcane,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stats.completions == 0)
            Text(l10n.chronicleEmpty, style: text.bodyMedium)
          else
            Text(
              l10n.chronicleLocalSummary(
                periodName,
                f.number(stats.completions),
                f.duration(stats.minutes),
                strongest == null ? '' : l10n.attributeName(strongest),
              ),
              style: text.bodyLarge,
            ),
          const SizedBox(height: AppSpace.lg),
          LayoutBuilder(
            builder: (context, c) {
              final perRow = c.maxWidth > 560 ? 4 : 2;
              final w = (c.maxWidth - AppSpace.md * (perRow - 1)) / perRow;
              return Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final t in tiles)
                    SizedBox(
                      width: w,
                      child: StatTile(icon: t.$4, color: t.$5, value: t.$2, label: t.$1, caption: t.$3),
                    ),
                ],
              );
            },
          ),
          if (strongest != null && stats.quietest != null && stats.quietest != strongest) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _AreaLabel(caption: l10n.strongestArea, attribute: strongest),
                ),
                Expanded(
                  child: _AreaLabel(caption: l10n.quietestArea, attribute: stats.quietest!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AreaLabel extends StatelessWidget {
  const _AreaLabel({required this.caption, required this.attribute});
  final String caption;
  final Attribute attribute;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        AttributeSigil(attribute, size: 18),
        const SizedBox(width: AppSpace.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: text.bodySmall),
              Text(context.l10n.attributeName(attribute), style: text.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stacked XP by attribute over the period. Time runs from the start edge,
/// so the chart mirrors in RTL.
class _XpChartPanel extends ConsumerWidget {
  const _XpChartPanel({required this.stats, required this.period});
  final PeriodStats stats;
  final ChroniclePeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final buckets = <(String, Map<Attribute, int>)>[];
    if (period == ChroniclePeriod.year) {
      var m = stats.start;
      for (var i = 0; i < 12; i++) {
        final next = f.addMonths(m, 1);
        final sum = <Attribute, int>{};
        for (var d = m; d.isBefore(next); d = DateTime(d.year, d.month, d.day + 1)) {
          stats.xpByDay[dayKey(d)]?.forEach((a, v) => sum[a] = (sum[a] ?? 0) + v);
        }
        buckets.add((f.digits('${f.calendarMonth(m)}'), sum));
        m = next;
      }
    } else {
      for (var d = stats.start; d.isBefore(stats.endExclusive); d = DateTime(d.year, d.month, d.day + 1)) {
        final label = period == ChroniclePeriod.week ? f.weekdayShort(d) : f.digits(f.dayMonth(d).split(' ').first);
        buckets.add((label, stats.xpByDay[dayKey(d)] ?? const {}));
      }
    }
    final ordered = rtl ? buckets.reversed.toList() : buckets;
    final maxY = ordered.fold<int>(
      0,
      (m, b) => [m, b.$2.values.fold(0, (a, c) => a + c)].reduce((a, c) => a > c ? a : c),
    );
    final labelEvery = ordered.length > 16 ? 5 : 1;
    final valueAxis = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        getTitlesWidget: (v, meta) => SideTitleWidget(
          meta: meta,
          child: Text(f.number(v.round()), style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );

    return Panel(
      title: l10n.chartXpByAttribute,
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 220,
        child: maxY == 0
            ? Center(
                child: EmptyState(message: l10n.chronicleEmpty, icon: Icons.bar_chart),
              )
            : BarChart(
                BarChartData(
                  maxY: (maxY * 1.15).ceilToDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.hairline, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.slateHigh,
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        '${ordered[group.x].$1}\n${l10n.totalXp(f.number(rod.toY.round()))}',
                        Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.bone),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: rtl ? valueAxis : const AxisTitles(),
                    leftTitles: rtl ? const AxisTitles() : valueAxis,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= ordered.length || i % labelEvery != 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(ordered[i].$1, style: Theme.of(context).textTheme.bodySmall),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < ordered.length; i++)
                      BarChartGroupData(x: i, barRods: [_stackedRod(ordered[i].$2, ordered.length)]),
                  ],
                ),
              ),
      ),
    );
  }

  BarChartRodData _stackedRod(Map<Attribute, int> xp, int count) {
    var from = 0.0;
    final items = <BarChartRodStackItem>[];
    for (final a in Attribute.values) {
      final v = (xp[a] ?? 0).toDouble();
      if (v <= 0) continue;
      items.add(BarChartRodStackItem(from, from + v, AppColors.forAttribute(a)));
      from += v;
    }
    return BarChartRodData(
      toY: from,
      rodStackItems: items,
      width: count > 16 ? 7 : 18,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      color: AppColors.slateHigh,
    );
  }
}

class _DistributionPanel extends ConsumerWidget {
  const _DistributionPanel({required this.stats, required this.previous});
  final PeriodStats stats;
  final PeriodStats? previous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final total = stats.totalXp;
    return Panel(
      title: l10n.chartDistribution,
      icon: Icons.donut_large_rounded,
      child: Column(
        children: [
          for (final a in Attribute.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
              child: Row(
                children: [
                  AttributeSigil(a, size: 16),
                  const SizedBox(width: AppSpace.sm),
                  SizedBox(width: 92, child: Text(l10n.attributeName(a), style: text.bodySmall)),
                  Expanded(
                    child: XpBar(
                      fraction: total == 0 ? 0 : (stats.xpByAttribute[a] ?? 0) / total,
                      color: AppColors.forAttribute(a),
                      height: 6,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  SizedBox(
                    width: 48,
                    child: Text(
                      f.number(stats.xpByAttribute[a] ?? 0),
                      style: text.labelMedium,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          if (stats.minutesByCategory.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpace.sm),
            for (final e in (stats.minutesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(
              5,
            ))
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.categoryName(e.key), style: text.bodySmall)),
                    Text(f.duration(e.value), style: text.labelMedium),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Active, rest and quiet days. Quiet days are neutral, never "missed".
class _RhythmPanel extends ConsumerWidget {
  const _RhythmPanel({required this.stats, required this.period});
  final PeriodStats stats;
  final ChroniclePeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.fmt(context);
    final text = Theme.of(context).textTheme;
    final today = DateTime.now();
    final days = <DateTime>[
      for (var d = stats.start; d.isBefore(stats.endExclusive); d = DateTime(d.year, d.month, d.day + 1)) d,
    ];
    Color colorFor(DateTime d) {
      final k = dayKey(d);
      if (stats.activeDays.contains(k)) return AppColors.crimson;
      if (stats.restDays.contains(k)) return AppColors.attrVitality;
      if (d.isAfter(today)) return Colors.transparent;
      return AppColors.abyss;
    }

    return Panel(
      title: l10n.chartConsistency,
      icon: Icons.grid_view_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final d in days)
                Tooltip(
                  message: f.date(d),
                  child: Container(
                    width: period == ChroniclePeriod.year ? 9 : 18,
                    height: period == ChroniclePeriod.year ? 9 : 18,
                    decoration: BoxDecoration(
                      color: colorFor(d),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.hairline, width: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.lg,
            children: [
              for (final (c, label) in [
                (AppColors.crimson, l10n.legendActive),
                (AppColors.attrVitality, l10n.legendRest),
                (AppColors.abyss, l10n.legendQuiet),
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c,
                        border: Border.all(color: AppColors.hairline, width: 0.5),
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(label, style: text.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A chevron pointing toward the past (back) or the future. Material's
/// chevrons already mirror in right-to-left layouts (matchTextDirection),
/// so no manual flip is needed.
class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron({required this.back});
  final bool back;

  @override
  Widget build(BuildContext context) => Icon(back ? Icons.chevron_left : Icons.chevron_right);
}
