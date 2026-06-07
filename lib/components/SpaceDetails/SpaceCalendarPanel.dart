import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:table_calendar/table_calendar.dart';

class SpaceCalendarPanel extends StatelessWidget {
  const SpaceCalendarPanel({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.items,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final List<IssueSummary> items;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    final firstDay = DateTime.utc(focusedDay.year - 2, 1, 1);
    final lastDay = DateTime.utc(focusedDay.year + 2, 12, 31);

    return TableCalendar<IssueSummary>(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      eventLoader: _eventsForDay,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      daysOfWeekHeight: 28,
      rowHeight: 52,
      headerVisible: true,
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
        headerTitleBuilder: (context, day) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${day.year} 年 ${day.month} 月',
              style: theme.textTheme.titleMedium,
            ),
          );
        },
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          final eventsForDay = events.take(3).toList();
          return Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final raw in eventsForDay)
                  _EventMark(item: raw, day: day, palette: palette),
              ],
            ),
          );
        },
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        leftChevronIcon: Icon(
          Icons.chevron_left_rounded,
          color: palette.textPrimary,
          size: 28,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right_rounded,
          color: palette.textPrimary,
          size: 28,
        ),
        titleTextStyle:
            theme.textTheme.titleMedium ?? const TextStyle(fontSize: 18),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle:
            theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 13),
        weekendStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: palette.textTertiary),
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
      ),
    );
  }

  static const _rangeColor = Color(0xFF8E4BC3);
  static const _pointColor = Color(0xFF1F5DBD);

  List<IssueSummary> _eventsForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return items.where((item) {
      final start = item.startDate;
      final due = item.dueDate;
      if (start == null && due == null) return false;
      final from = start == null
          ? DateTime(due!.year, due.month, due.day)
          : DateTime(start.year, start.month, start.day);
      final to = due == null
          ? DateTime(start!.year, start.month, start.day)
          : DateTime(due.year, due.month, due.day);
      return !target.isBefore(from) && !target.isAfter(to);
    }).toList(growable: false);
  }
}

class _EventMark extends StatelessWidget {
  const _EventMark({
    required this.item,
    required this.day,
    required this.palette,
  });

  final IssueSummary item;
  final DateTime day;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final start = item.startDate;
    final due = item.dueDate;
    final hasRange = start != null && due != null && !_isSameDay(start, due);

    if (!hasRange) {
      return Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: const BoxDecoration(
          color: SpaceCalendarPanel._pointColor,
          shape: BoxShape.circle,
        ),
      );
    }

    final target = DateTime(day.year, day.month, day.day);
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(due.year, due.month, due.day);
    final isStart = _isSameDay(target, from);
    final isEnd = _isSameDay(target, to);
    final radiusLeft = isStart ? const Radius.circular(3) : Radius.zero;
    final radiusRight = isEnd ? const Radius.circular(3) : Radius.zero;

    return Container(
      width: double.infinity,
      height: 4,
      margin: EdgeInsets.only(
        top: 2,
        bottom: 1,
        left: isStart ? 4 : 0,
        right: isEnd ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: SpaceCalendarPanel._rangeColor,
        borderRadius: BorderRadius.horizontal(
          left: radiusLeft,
          right: radiusRight,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
