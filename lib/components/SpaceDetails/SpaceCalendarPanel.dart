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
        markerDecoration: BoxDecoration(
          color: palette.primary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
      ),
    );
  }

  List<IssueSummary> _eventsForDay(DateTime day) {
    return items
        .where((item) => item.dueDate != null && isSameDay(item.dueDate!, day))
        .toList(growable: false);
  }
}
