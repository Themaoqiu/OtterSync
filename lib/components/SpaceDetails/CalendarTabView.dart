import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/CustomFilterChip.dart';
import 'package:ottersync/components/Common/IssueListTile.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class CalendarTabView extends StatefulWidget {
  const CalendarTabView({
    super.key,
    required this.filters,
    required this.items,
  });

  final List<String> filters;
  final List<IssueSummary> items;

  @override
  State<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends State<CalendarTabView> {
  int _selectedFilter = 0;
  int _selectedDay = 14;

  static const _days = [
    ['29', '30', '31', '1', '2', '3', '4'],
    ['5', '6', '7', '8', '9', '10', '11'],
    ['12', '13', '14', '15', '16', '17', '18'],
    ['19', '20', '21', '22', '23', '24', '25'],
    ['26', '27', '28', '29', '30', '1', '2'],
    ['3', '4', '5', '6', '7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.filters.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  right: entry.key == widget.filters.length - 1 ? 0 : 10,
                ),
                child: CustomFilterChip(
                  label: entry.value,
                  selected: entry.key == _selectedFilter,
                  onTap: () => setState(() => _selectedFilter = entry.key),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        AppSurface(
          child: _CalendarCard(selectedDay: _selectedDay, onDayTap: _onDayTap),
        ),
        const SizedBox(height: 18),
        if (_scheduledItems.isEmpty)
          AppSurface(child: _CalendarEmptyState(selectedDay: _selectedDay))
        else
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _scheduledItems
                  .map(
                    (item) => IssueListTile(
                      title: item.title,
                      subtitle: '${item.key} · ${item.subtitle ?? ''}',
                      status: item.status,
                      avatar: item.assigneeInitials,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 18),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('未安排 (${_unscheduledItems.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_unscheduledItems.isEmpty)
                Text('所有工作项都已安排到日历中。', style: Theme.of(context).textTheme.bodyMedium)
              else
                ..._unscheduledItems.map(
                  (item) => IssueListTile(
                    title: item.title,
                    subtitle: '${item.key} · ${item.subtitle ?? ''}',
                    status: item.status,
                    avatar: item.assigneeInitials,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<IssueSummary> get _scheduledItems {
    return widget.items.where((item) => item.dueDate?.day == _selectedDay).toList(growable: false);
  }

  List<IssueSummary> get _unscheduledItems {
    return widget.items.where((item) => item.dueDate == null).toList(growable: false);
  }

  void _onDayTap(String day) {
    final parsed = int.tryParse(day);
    if (parsed == null) {
      return;
    }
    setState(() => _selectedDay = parsed);
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.selectedDay, required this.onDayTap});

  final int selectedDay;
  final ValueChanged<String> onDayTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('四月 2026', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: palette.textSecondary),
            const Spacer(),
            Text(
              '今天',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.primary,
                  ),
            ),
            const SizedBox(width: 22),
            Icon(
              Icons.chevron_left_rounded,
              color: palette.textPrimary,
              size: 38,
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textPrimary,
              size: 38,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: const ['日', '一', '二', '三', '四', '五', '六']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(day),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        ..._CalendarTabViewState._days.map(
          (week) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: week
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: InkWell(
                          onTap: () => onDayTap(day),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: int.tryParse(day) == selectedDay
                                  ? palette.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              day,
                              style: TextStyle(
                                color: int.tryParse(day) == selectedDay
                                    ? Colors.white
                                    : palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState({required this.selectedDay});

  final int selectedDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE7E9EF),
          ),
          child: const Icon(
            Icons.task_alt_rounded,
            size: 86,
            color: Color(0xFF1F5DBD),
          ),
        ),
        const SizedBox(height: 20),
        Text('尚未安排任何事项', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        Text(
          '$selectedDay 日无任何到期工作项',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
