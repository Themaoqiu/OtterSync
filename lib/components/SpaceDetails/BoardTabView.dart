import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class BoardTabView extends StatelessWidget {
  const BoardTabView({
    super.key,
    required this.sprints,
    required this.items,
    required this.onOpenSprintManager,
    required this.onItemTap,
    required this.onItemStatusChanged,
  });

  final List<Sprint> sprints;
  final List<IssueSummary> items;
  final VoidCallback onOpenSprintManager;
  final void Function(IssueSummary item) onItemTap;
  final void Function(IssueSummary item, WorkItemStatus status)
  onItemStatusChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    final openSprints = sprints
        .where((s) => s.status != SprintStatus.completed)
        .toList(growable: false);

    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        if (openSprints.isEmpty)
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined, color: palette.textSecondary),
                    const SizedBox(width: 10),
                    Text('暂无进行中冲刺', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '创建并启动冲刺后，团队的工作会显示在面板中。',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onOpenSprintManager,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('管理冲刺'),
                  ),
                ),
              ],
            ),
          )
        else
          ...openSprints.map(
            (sprint) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SprintBoard(
                sprint: sprint,
                items: items
                    .where((i) => i.sprintId == sprint.id)
                    .toList(growable: false),
                onItemTap: onItemTap,
                onItemStatusChanged: onItemStatusChanged,
                onManage: onOpenSprintManager,
              ),
            ),
          ),
      ],
    );
  }
}

class _SprintBoard extends StatelessWidget {
  const _SprintBoard({
    required this.sprint,
    required this.items,
    required this.onItemTap,
    required this.onItemStatusChanged,
    required this.onManage,
  });

  final Sprint sprint;
  final List<IssueSummary> items;
  final void Function(IssueSummary item) onItemTap;
  final void Function(IssueSummary item, WorkItemStatus status)
  onItemStatusChanged;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    final isActive = sprint.status == SprintStatus.active;
    final accent = isActive ? palette.primary : palette.textSecondary;

    final columns = const [
      _BoardColumnSpec(WorkItemStatus.todo, '待办', Color(0xFF94A3B8)),
      _BoardColumnSpec(WorkItemStatus.inProgress, '进行中', Color(0xFF3B82F6)),
      _BoardColumnSpec(WorkItemStatus.done, '已完成', Color(0xFF10B981)),
    ];

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(sprint.name, style: theme.textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? '进行中' : '计划中',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: '管理冲刺',
                onPressed: onManage,
                icon: Icon(Icons.tune_rounded, color: palette.textSecondary),
              ),
            ],
          ),
          if (sprint.startDate != null || sprint.endDate != null) ...[
            const SizedBox(height: 4),
            Text(
              _dateRangeLabel(sprint.startDate, sprint.endDate),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns
                    .map(
                      (spec) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 260,
                          child: _BoardColumn(
                            spec: spec,
                            items: items
                                .where((i) => i.statusKey == spec.status)
                                .toList(growable: false),
                            onItemTap: onItemTap,
                            onItemStatusChanged: onItemStatusChanged,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel(DateTime? start, DateTime? end) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (start != null && end != null) return '${fmt(start)} ~ ${fmt(end)}';
    if (start != null) return '从 ${fmt(start)}';
    if (end != null) return '至 ${fmt(end)}';
    return '';
  }
}

class _BoardColumnSpec {
  const _BoardColumnSpec(this.status, this.label, this.accent);

  final WorkItemStatus status;
  final String label;
  final Color accent;
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.spec,
    required this.items,
    required this.onItemTap,
    required this.onItemStatusChanged,
  });

  final _BoardColumnSpec spec;
  final List<IssueSummary> items;
  final void Function(IssueSummary item) onItemTap;
  final void Function(IssueSummary item, WorkItemStatus status)
  onItemStatusChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: spec.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(spec.label, style: theme.textTheme.titleSmall),
              const SizedBox(width: 6),
              Text(
                '${items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('没有工作项', style: theme.textTheme.bodySmall),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BoardCard(
                  item: item,
                  onTap: () => onItemTap(item),
                  onStatusChanged: (status) =>
                      onItemStatusChanged(item, status),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.item,
    required this.onTap,
    required this.onStatusChanged,
  });

  final IssueSummary item;
  final VoidCallback onTap;
  final ValueChanged<WorkItemStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppSpace.radius),
          border: Border.all(color: palette.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  item.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
                const Spacer(),
                if (item.assigneeInitials != null)
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: palette.primarySoft,
                    child: Text(
                      item.assigneeInitials!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                _StatusMenu(
                  current: item.statusKey,
                  onSelected: onStatusChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.current, required this.onSelected});

  final WorkItemStatus current;
  final ValueChanged<WorkItemStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return PopupMenuButton<WorkItemStatus>(
      tooltip: '更改状态',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: palette.textSecondary,
      ),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (ctx) => WorkItemStatus.values
          .map(
            (s) => PopupMenuItem<WorkItemStatus>(
              value: s,
              child: Row(
                children: [
                  Icon(
                    s == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: s == current
                        ? palette.primary
                        : palette.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(workItemStatusLabel(s)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
