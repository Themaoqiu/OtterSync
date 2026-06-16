import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:table_calendar/table_calendar.dart';

enum _PickerMode { single, range }

class DatePickResult {
  const DatePickResult({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool get isRange => start != null && end != null && !_isSameDay(start!, end!);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Future<DatePickResult?> showDatePickerSheet(
  BuildContext context, {
  String title = '选择日期',
  DateTime? initialStart,
  DateTime? initialEnd,
  DateTime? minDate,
  DateTime? maxDate,
  bool allowRange = true,
}) {
  return showModalBottomSheet<DatePickResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _DatePickerSheetBody(
      title: title,
      initialStart: initialStart,
      initialEnd: initialEnd,
      minDate: minDate,
      maxDate: maxDate,
      allowRange: allowRange,
    ),
  );
}

class _DatePickerSheetBody extends StatefulWidget {
  const _DatePickerSheetBody({
    required this.title,
    required this.initialStart,
    required this.initialEnd,
    required this.minDate,
    required this.maxDate,
    required this.allowRange,
  });

  final String title;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool allowRange;

  @override
  State<_DatePickerSheetBody> createState() => _DatePickerSheetBodyState();
}

class _DatePickerSheetBodyState extends State<_DatePickerSheetBody> {
  late _PickerMode _mode;
  DateTime? _start;
  DateTime? _end;
  late DateTime _focused;

  @override
  void initState() {
    super.initState();
    final hasRange =
        widget.initialStart != null &&
        widget.initialEnd != null &&
        !_isSameDay(widget.initialStart!, widget.initialEnd!);
    _mode = hasRange && widget.allowRange
        ? _PickerMode.range
        : _PickerMode.single;
    if (_mode == _PickerMode.range) {
      _start = widget.initialStart;
      _end = widget.initialEnd;
    } else {
      _end = widget.initialEnd ?? widget.initialStart;
    }
    _focused = _end ?? _start ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final firstDay = widget.minDate ?? DateTime(_focused.year - 2, 1, 1);
    final lastDay = widget.maxDate ?? DateTime(_focused.year + 5, 12, 31);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: widget.title),
            if (widget.allowRange)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: SegmentedButton<_PickerMode>(
                  segments: const [
                    ButtonSegment(
                      value: _PickerMode.single,
                      icon: Icon(Icons.event_rounded),
                      label: Text('单日'),
                    ),
                    ButtonSegment(
                      value: _PickerMode.range,
                      icon: Icon(Icons.date_range_rounded),
                      label: Text('时间段'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.first;
                    if (_mode == _PickerMode.single) {
                      _start = null;
                    } else {
                      _start ??= _end;
                      if (_start != null &&
                          _end != null &&
                          _end!.isBefore(_start!)) {
                        _end = _start;
                      }
                    }
                  }),
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar<void>(
                firstDay: firstDay,
                lastDay: lastDay,
                focusedDay: _clampToRange(_focused, firstDay, lastDay),
                rangeStartDay: _mode == _PickerMode.range ? _start : null,
                rangeEndDay: _mode == _PickerMode.range ? _end : null,
                rangeSelectionMode: _mode == _PickerMode.range
                    ? RangeSelectionMode.toggledOn
                    : RangeSelectionMode.toggledOff,
                selectedDayPredicate: _mode == _PickerMode.single
                    ? (d) => _end != null && _isSameDay(d, _end!)
                    : (_) => false,
                onDaySelected: (selected, focused) {
                  if (_mode != _PickerMode.single) return;
                  setState(() {
                    _end = selected;
                    _start = null;
                    _focused = focused;
                  });
                },
                onRangeSelected: (start, end, focused) {
                  if (_mode != _PickerMode.range) return;
                  setState(() {
                    _start = start;
                    _end = end ?? start;
                    _focused = focused;
                  });
                },
                onPageChanged: (f) => _focused = f,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                daysOfWeekHeight: 28,
                rowHeight: 46,
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    const labels = ['日', '一', '二', '三', '四', '五', '六'];
                    return Center(
                      child: Text(
                        labels[day.weekday % 7],
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  },
                  headerTitleBuilder: (context, day) => Text(
                    '${day.year} 年 ${day.month} 月',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: palette.textPrimary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textPrimary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  cellMargin: const EdgeInsets.all(4),
                  defaultTextStyle: TextStyle(color: palette.textPrimary),
                  weekendTextStyle: TextStyle(color: palette.textPrimary),
                  outsideTextStyle: TextStyle(color: palette.textTertiary),
                  todayDecoration: BoxDecoration(
                    color: palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  rangeStartDecoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeStartTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  rangeEndTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  withinRangeDecoration: BoxDecoration(
                    color: palette.primarySoft,
                  ),
                  withinRangeTextStyle: TextStyle(color: palette.primary),
                  rangeHighlightColor: palette.primarySoft,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _summary(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _canConfirm() ? _confirm : null,
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canConfirm() {
    if (_mode == _PickerMode.single) return _end != null;
    return _start != null && _end != null;
  }

  void _confirm() {
    if (_mode == _PickerMode.single) {
      Navigator.pop(context, DatePickResult(end: _end));
    } else {
      Navigator.pop(context, DatePickResult(start: _start, end: _end));
    }
  }

  String _summary() {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (_mode == _PickerMode.single) {
      return _end == null ? '请选择日期' : fmt(_end!);
    }
    if (_start == null || _end == null) return '请选择起止日期';
    return '${fmt(_start!)} ~ ${fmt(_end!)}';
  }

  DateTime _clampToRange(DateTime d, DateTime first, DateTime last) {
    if (d.isBefore(first)) return first;
    if (d.isAfter(last)) return last;
    return d;
  }
}
