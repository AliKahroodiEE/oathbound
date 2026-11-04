import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../app/providers.dart';
import '../../core/locale/locale_registry.dart';
import '../tokens.dart';

/// Month-grid date picker that follows the user's calendar setting
/// (Gregorian or Jalali) and week start, independent of UI language.
Future<DateTime?> showCalendarDatePicker(BuildContext context, {DateTime? initial}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _CalendarDialog(initial: initial ?? DateTime.now()),
);

class _CalendarDialog extends ConsumerStatefulWidget {
  const _CalendarDialog({required this.initial});
  final DateTime initial;

  @override
  ConsumerState<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends ConsumerState<_CalendarDialog> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(widget.initial.year, widget.initial.month, widget.initial.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _month = ref.read(regionalProvider).calendar == CalendarSystem.jalali
        ? Jalali.fromDateTime(_selected).copy(day: 1).toDateTime()
        : DateTime(_selected.year, _selected.month);
  }

  int _daysInMonth(bool jalali) =>
      jalali ? Jalali.fromDateTime(_month).monthLength : DateUtils.getDaysInMonth(_month.year, _month.month);

  DateTime _dayAt(bool jalali, int day) =>
      jalali ? Jalali.fromDateTime(_month).copy(day: day).toDateTime() : DateTime(_month.year, _month.month, day);

  @override
  Widget build(BuildContext context) {
    final regional = ref.watch(regionalProvider);
    final f = ref.fmt(context);
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final jalali = regional.calendar == CalendarSystem.jalali;
    final days = _daysInMonth(jalali);
    final firstWeekday = regional.firstWeekday;
    final leading = (_month.weekday - firstWeekday) % 7;
    final today = DateUtils.dateOnly(DateTime.now());
    final headers = [
      for (var i = 0; i < 7; i++) f.weekdayShort(DateTime(2026, 11, 2).add(Duration(days: (firstWeekday - 1 + i) % 7))),
    ];

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.previousPeriod,
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_right : Icons.chevron_left,
                    ),
                    onPressed: () => setState(() => _month = f.addMonths(_month, -1)),
                  ),
                  Expanded(
                    child: Text(f.monthYear(_month), style: text.titleMedium, textAlign: TextAlign.center),
                  ),
                  IconButton(
                    tooltip: l10n.nextPeriod,
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                    ),
                    onPressed: () => setState(() => _month = f.addMonths(_month, 1)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final h in headers)
                    Center(
                      child: Text(h, style: text.bodySmall, overflow: TextOverflow.clip, maxLines: 1),
                    ),
                  for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                  for (var d = 1; d <= days; d++)
                    Builder(
                      builder: (context) {
                        final date = _dayAt(jalali, d);
                        final selected = DateUtils.isSameDay(date, _selected);
                        final isToday = DateUtils.isSameDay(date, today);
                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: Material(
                            color: selected ? AppColors.crimson : Colors.transparent,
                            shape: CircleBorder(
                              side: isToday && !selected ? const BorderSide(color: AppColors.ember) : BorderSide.none,
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => setState(() => _selected = date),
                              child: Center(
                                child: Text(
                                  f.digits('$d'),
                                  style: text.bodyMedium?.copyWith(color: selected ? AppColors.bone : AppColors.ash),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(child: Text(f.date(_selected), style: text.bodySmall)),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
                  FilledButton(onPressed: () => Navigator.of(context).pop(_selected), child: Text(l10n.actionDone)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
