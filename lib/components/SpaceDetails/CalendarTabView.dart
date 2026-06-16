import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/DatePickerSheet.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/components/Common/work_type_icon.dart';
import 'package:ottersync/components/SpaceDetails/SpaceCalendarPanel.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

enum _CalendarFilterKind { workType, status, assignee, priority }

class CalendarTabView extends StatefulWidget {
  const CalendarTabView({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onScheduleItem,
  });

  final List<IssueSummary> items;
  final void Function(IssueSummary item) onItemTap;
  final Future<void> Function(
    IssueSummary item,
    DateTime? startDate,
    DateTime? dueDate,
  )
  onScheduleItem;

  @override
  State<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends State<CalendarTabView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String? _typeFilter;
  WorkItemStatus? _statusFilter;
  String? _assigneeFilter;
  String? _priorityFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                _CalendarFilterKind.workType,
                _typeFilter ?? '类型',
                _typeFilter != null,
              ),
              const SizedBox(width: 8),
              _filterChip(
                _CalendarFilterKind.status,
                _statusFilter == null
                    ? '状态'
                    : workItemStatusLabel(_statusFilter!),
                _statusFilter != null,
              ),
              const SizedBox(width: 8),
              _filterChip(
                _CalendarFilterKind.assignee,
                _assigneeFilter ?? '经办人',
                _assigneeFilter != null,
              ),
              const SizedBox(width: 8),
              _filterChip(
                _CalendarFilterKind.priority,
                _priorityFilter ?? '优先级',
                _priorityFilter != null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSurface(
          child: SpaceCalendarPanel(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
            items: _filteredItems,
          ),
        ),
        const SizedBox(height: 18),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedDay.month} 月 ${_selectedDay.day} 日 (${_scheduledItems.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (_scheduledItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '当天没有到期工作项',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ..._scheduledItems.map(
                  (item) => _ScheduledItemRow(
                    item: item,
                    onTap: () => widget.onItemTap(item),
                    onEditSchedule: () => _scheduleTo(item),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '未安排 (${_unscheduledItems.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '点击工作项可安排到选定日期',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              if (_unscheduledItems.isEmpty)
                Text(
                  '所有工作项都已安排到日历中。',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ..._unscheduledItems.map(
                  (item) => _ScheduledItemRow(
                    item: item,
                    onTap: () => _scheduleTo(item),
                    onEditSchedule: () => _scheduleTo(item),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _scheduleTo(IssueSummary item) async {
    final hasExisting = item.startDate != null || item.dueDate != null;
    if (hasExisting) {
      final palette = AppThemePalette.of(context);
      final action = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: '安排时间'),
              ListTile(
                leading: Icon(
                  Icons.edit_calendar_rounded,
                  color: palette.primary,
                ),
                title: const Text('修改时间'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(Icons.event_busy_rounded, color: palette.danger),
                title: const Text('清除安排'),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (action == null) return;
      if (action == 'clear') {
        await widget.onScheduleItem(item, null, null);
        return;
      }
    }

    if (!mounted) return;
    final result = await showDatePickerSheet(
      context,
      title: '安排时间',
      initialStart: item.startDate,
      initialEnd: item.dueDate ?? _selectedDay,
    );
    if (result == null) return;
    await widget.onScheduleItem(item, result.start, result.end);
  }

  Widget _filterChip(_CalendarFilterKind kind, String label, bool active) {
    final palette = AppThemePalette.of(context);
    return InkWell(
      onTap: () => _openFilterMenu(kind),
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? palette.primarySoft : palette.surface,
          borderRadius: BorderRadius.circular(AppSpace.radius),
          border: Border.all(color: active ? palette.primary : palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? palette.primary : palette.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active ? palette.primary : palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterMenu(_CalendarFilterKind kind) async {
    final options = _filterOptions(kind);
    final picked = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            SheetHeader(title: _filterTitle(kind)),
            ListTile(
              leading: const Icon(
                Icons.all_inclusive_rounded,
                color: Color(0xFF44546F),
              ),
              title: const Text('全部'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...options.map(
              (o) => ListTile(
                leading: _filterLeading(kind, o),
                title: Text(o),
                onTap: () => Navigator.pop(ctx, o),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      final value = picked.isEmpty ? null : picked;
      switch (kind) {
        case _CalendarFilterKind.workType:
          _typeFilter = value;
          break;
        case _CalendarFilterKind.status:
          _statusFilter = value == null
              ? null
              : WorkItemStatus.values.firstWhere(
                  (s) => workItemStatusLabel(s) == value,
                  orElse: () => WorkItemStatus.todo,
                );
          break;
        case _CalendarFilterKind.assignee:
          _assigneeFilter = value;
          break;
        case _CalendarFilterKind.priority:
          _priorityFilter = value;
          break;
      }
    });
  }

  Widget _filterLeading(_CalendarFilterKind kind, String value) {
    switch (kind) {
      case _CalendarFilterKind.workType:
        return WorkTypeIconBadge(title: value, size: 24);
      case _CalendarFilterKind.status:
        if (value == workItemStatusLabel(WorkItemStatus.done)) {
          return const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF1F8B4C),
          );
        }
        if (value == workItemStatusLabel(WorkItemStatus.inProgress)) {
          return const Icon(Icons.timelapse_rounded, color: Color(0xFF1F5DBD));
        }
        return const Icon(
          Icons.radio_button_unchecked_rounded,
          color: Color(0xFF44546F),
        );
      case _CalendarFilterKind.assignee:
        return const Icon(Icons.person_rounded, color: Color(0xFF1F5DBD));
      case _CalendarFilterKind.priority:
        switch (value) {
          case 'Highest':
            return const Icon(
              Icons.keyboard_double_arrow_up_rounded,
              color: Color(0xFFE5493A),
            );
          case 'High':
            return const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Color(0xFFFF8B6B),
            );
          case 'Medium':
            return const Icon(
              Icons.drag_handle_rounded,
              color: Color(0xFFFF8B00),
            );
          case 'Low':
            return const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6CA6FF),
            );
          case 'Lowest':
            return const Icon(
              Icons.keyboard_double_arrow_down_rounded,
              color: Color(0xFF4C84FF),
            );
        }
        return const Icon(Icons.flag_rounded, color: Color(0xFF44546F));
    }
  }

  String _filterTitle(_CalendarFilterKind kind) {
    switch (kind) {
      case _CalendarFilterKind.workType:
        return '按类型筛选';
      case _CalendarFilterKind.status:
        return '按状态筛选';
      case _CalendarFilterKind.assignee:
        return '按经办人筛选';
      case _CalendarFilterKind.priority:
        return '按优先级筛选';
    }
  }

  List<String> _filterOptions(_CalendarFilterKind kind) {
    switch (kind) {
      case _CalendarFilterKind.workType:
        final set =
            widget.items
                .map((i) => i.workTypeTitle)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();
        return set.isEmpty ? const ['任务', '缺陷', '故事'] : set;
      case _CalendarFilterKind.status:
        return WorkItemStatus.values.map(workItemStatusLabel).toList();
      case _CalendarFilterKind.assignee:
        return widget.items
            .map((i) => i.assigneeInitials)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
      case _CalendarFilterKind.priority:
        return const ['Highest', 'High', 'Medium', 'Low', 'Lowest'];
    }
  }

  bool _passesFilters(IssueSummary item) {
    if (_typeFilter != null && item.workTypeTitle != _typeFilter) return false;
    if (_statusFilter != null && item.statusKey != _statusFilter) return false;
    if (_assigneeFilter != null && item.assigneeInitials != _assigneeFilter) {
      return false;
    }
    if (_priorityFilter != null && item.priority != _priorityFilter) {
      return false;
    }
    return true;
  }

  List<IssueSummary> get _filteredItems =>
      widget.items.where(_passesFilters).toList(growable: false);

  List<IssueSummary> get _scheduledItems {
    final target = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    return _filteredItems
        .where((item) {
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
        })
        .toList(growable: false);
  }

  List<IssueSummary> get _unscheduledItems {
    return _filteredItems
        .where((item) => item.dueDate == null && item.startDate == null)
        .toList(growable: false);
  }
}

class _ScheduledItemRow extends StatelessWidget {
  const _ScheduledItemRow({
    required this.item,
    required this.onTap,
    required this.onEditSchedule,
  });

  final IssueSummary item;
  final VoidCallback onTap;
  final VoidCallback onEditSchedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WorkTypeIconBadge(title: item.workTypeTitle, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(item.key, style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      _ScheduleBadge(
                        startDate: item.startDate,
                        dueDate: item.dueDate,
                        onTap: onEditSchedule,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBadge extends StatelessWidget {
  const _ScheduleBadge({
    required this.startDate,
    required this.dueDate,
    this.onTap,
  });

  final DateTime? startDate;
  final DateTime? dueDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    final hasRange = startDate != null && dueDate != null;
    final hasAny = startDate != null || dueDate != null;
    if (!hasAny) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.surfaceInset,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                '安排时间',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = hasRange ? const Color(0xFF8E4BC3) : const Color(0xFF1F5DBD);
    final icon = hasRange ? Icons.date_range_rounded : Icons.event_rounded;
    final label = hasRange
        ? '${_fmt(startDate!)} ~ ${_fmt(dueDate!)}'
        : _fmt(dueDate ?? startDate!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}
