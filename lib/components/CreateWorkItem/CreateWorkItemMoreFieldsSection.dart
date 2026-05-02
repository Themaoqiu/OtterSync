import 'package:flutter/material.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemSectionCard.dart';
import 'package:ottersync/components/CreateWorkItem/FieldTile.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class CreateWorkItemMoreFieldsSection extends StatelessWidget {
  const CreateWorkItemMoreFieldsSection({
    required this.expanded,
    required this.onToggle,
    required this.reporter,
    required this.assignee,
    required this.team,
    required this.parent,
    required this.startDate,
    required this.dueDate,
    required this.selectedLabelCount,
    required this.selectedLabelNames,
    required this.newLabelsController,
    required this.onPickReporter,
    required this.onPickAssignee,
    required this.onPickLabels,
    required this.onPickParent,
    required this.onPickTeam,
    required this.onPickStartDate,
    required this.onPickDueDate,
    super.key,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final LookupOption? reporter;
  final LookupOption? assignee;
  final LookupOption? team;
  final LookupOption? parent;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int selectedLabelCount;
  final List<String> selectedLabelNames;
  final TextEditingController newLabelsController;
  final VoidCallback onPickReporter;
  final VoidCallback onPickAssignee;
  final VoidCallback onPickLabels;
  final VoidCallback onPickParent;
  final VoidCallback onPickTeam;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickDueDate;

  @override
  Widget build(BuildContext context) {
    return CreateWorkItemSectionCard(
      title: '更多字段',
      collapsible: true,
      expanded: expanded,
      onToggle: onToggle,
      child: Column(
        children: [
          FieldTile(
            title: '经办人',
            value: reporter?.title ?? '请选择',
            helper: reporter?.subtitle,
            leading: const Icon(Icons.person_outline_rounded),
            onTap: onPickReporter,
          ),
          FieldTile(
            title: '处理人',
            value: assignee?.title ?? '无',
            helper: assignee?.subtitle,
            leading: const Icon(Icons.assignment_ind_outlined),
            onTap: onPickAssignee,
          ),
          FieldTile(
            title: '标签',
            value: selectedLabelCount == 0 ? '无' : '$selectedLabelCount 个',
            helper: selectedLabelNames.join('、'),
            leading: const Icon(Icons.sell_outlined),
            onTap: onPickLabels,
          ),
          FieldTile(
            title: '父项',
            value: parent?.title ?? '无',
            helper: parent?.subtitle,
            leading: const Icon(Icons.account_tree_outlined),
            onTap: onPickParent,
          ),
          FieldTile(
            title: '团队',
            value: team?.title ?? '无',
            helper: team?.subtitle,
            leading: const Icon(Icons.groups_2_outlined),
            onTap: onPickTeam,
          ),
          FieldTile(
            title: '开始日期',
            value: _formatDate(startDate) ?? '无',
            leading: const Icon(Icons.calendar_today_outlined),
            onTap: onPickStartDate,
          ),
          FieldTile(
            title: '截止日期',
            value: _formatDate(dueDate) ?? '无',
            leading: const Icon(Icons.event_available_outlined),
            onTap: onPickDueDate,
            showDivider: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newLabelsController,
            decoration: const InputDecoration(
              labelText: '新标签',
              hintText: '多个标签请用逗号分隔',
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
