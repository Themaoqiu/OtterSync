import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/components/Common/work_type_icon.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class WorkItemDetailView extends StatefulWidget {
  const WorkItemDetailView({
    super.key,
    required this.workItemId,
    this.heroSeed,
  });

  final int? workItemId;
  final IssueSummary? heroSeed;

  @override
  State<WorkItemDetailView> createState() => _WorkItemDetailViewState();
}

class _WorkItemDetailViewState extends State<WorkItemDetailView> {
  final _api = WorkItemApi();
  WorkItemResponse? _item;
  CreateWorkItemLookups? _lookups;
  List<Sprint> _sprints = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    if (widget.workItemId == null) {
      setState(() {
        _loading = false;
        _error = '无效的工作项 ID';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getWorkItemById(widget.workItemId!),
        _api.loadCreateLookups(),
      ]);
      final item = results[0] as WorkItemResponse?;
      final lookups = results[1] as CreateWorkItemLookups;
      final sprints = item == null
          ? <Sprint>[]
          : await _api.listSprints(workspaceId: item.workspace.id);
      if (!mounted) return;
      setState(() {
        _item = item;
        _lookups = lookups;
        _sprints = sprints;
        _loading = false;
        if (item == null) _error = '工作项不存在';
      });
      if (item != null) {
        _api.recordRecentView(
          workItemId: item.id,
          workItemKey: item.key,
          workItemTitle: item.summary,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: '查看',
            onPressed: () {},
            icon: const Icon(Icons.remove_red_eye_outlined),
          ),
          IconButton(
            tooltip: '附件',
            onPressed: () {},
            icon: const Icon(Icons.attach_file_rounded),
          ),
          IconButton(
            tooltip: '更多',
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) return _buildErrorState();
    final item = _item!;
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WorkTypeIconBadge(title: item.workType.title, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.key,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _editSummary,
                child: Text(
                  item.summary,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(height: 1.25, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _AssigneeAvatar(item: item),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _StatusPill(
              status: item.status,
              onTap: _pickStatus,
            ),
            _SquareIconChip(
              icon: Icons.flag_rounded,
              tint: const Color(0xFFEF4444),
              onTap: () => _pickPriority(),
              tooltip: '优先级',
            ),
            _SquareIconChip(
              icon: Icons.bolt_rounded,
              tint: Theme.of(context).iconTheme.color ?? Colors.black87,
              onTap: () {},
              tooltip: '快捷操作',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ExpandableSection(
          title: '描述',
          subtitle: _emptyOrText(item.description, '点击添加描述'),
          onTap: _editDescription,
        ),
        const SizedBox(height: 12),
        _ExpandableSection(
          title: '父工作项',
          subtitle: item.parent?.title ?? '无',
          onTap: _pickParent,
        ),
        const SizedBox(height: 12),
        _DetailBlock(
          item: item,
          onEditAssignee: _pickAssignee,
          onEditTeam: _pickTeam,
          onEditDueDate: _pickDueDate,
          onEditStartDate: _pickStartDate,
          onEditSprint: _pickSprint,
        ),
        const SizedBox(height: 12),
        _ExpandableSection(
          title: '更多字段',
          subtitle: '项目、已创建和已更新',
          onTap: () => _showInfoSheet(item),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: palette.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _loadItem, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  String _emptyOrText(String? value, String hint) {
    if (value == null || value.trim().isEmpty) return hint;
    return value;
  }

  Future<void> _editSummary() async {
    final controller = TextEditingController(text: _item!.summary);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑摘要'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(labelText: '摘要'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == _item!.summary) return;
    await _api.updateWorkItemFields(_item!.id, summary: result);
    if (!mounted) return;
    _patch(summary: result);
  }

  Future<void> _editDescription() async {
    final controller =
        TextEditingController(text: _item!.description ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑描述'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '描述',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await _api.updateWorkItemFields(_item!.id, description: result);
    if (!mounted) return;
    _patch(description: result);
  }

  Future<void> _pickStatus() async {
    final picked = await _pickFromList<WorkItemStatus>(
      title: '更改状态',
      options: WorkItemStatus.values,
      labelBuilder: workItemStatusLabel,
      iconBuilder: (s) {
        switch (s) {
          case WorkItemStatus.todo:
            return const _OptionVisual(
              icon: Icons.radio_button_unchecked_rounded,
              color: Color(0xFF44546F),
            );
          case WorkItemStatus.inProgress:
            return const _OptionVisual(
              icon: Icons.timelapse_rounded,
              color: Color(0xFF1F5DBD),
            );
          case WorkItemStatus.done:
            return const _OptionVisual(
              icon: Icons.check_circle_rounded,
              color: Color(0xFF1F8B4C),
            );
        }
      },
      current: _item!.status,
    );
    if (picked == null) return;
    await _updateStatus(picked);
  }

  Future<void> _updateStatus(WorkItemStatus newStatus) async {
    try {
      await _api.updateWorkItemStatus(_item!.id, newStatus);
      if (!mounted) return;
      _patch(status: newStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('状态更新失败：$e')));
    }
  }

  Future<void> _pickAssignee() async {
    final users = _lookups?.users ?? const <LookupOption>[];
    final picked = await _pickFromList<LookupOption?>(
      title: '指派经办人',
      options: <LookupOption?>[null, ...users],
      labelBuilder: (o) => o?.title ?? '未分配',
      iconBuilder: (o) => o == null
          ? const _OptionVisual(
              icon: Icons.person_outline_rounded, color: Color(0xFF94A3B8))
          : const _OptionVisual(
              icon: Icons.person_rounded, color: Color(0xFF1F5DBD)),
      current: _item!.assignee,
    );
    if (picked == null && _item!.assignee == null) return;
    if (picked == null) {
      await _api.updateWorkItemFields(_item!.id, clearAssignee: true);
      _patch(assignee: const _Cleared());
    } else {
      await _api.updateWorkItemFields(_item!.id, assigneeId: picked.id);
      _patch(assignee: picked);
    }
  }

  Future<void> _pickTeam() async {
    final teams = _lookups?.teams ?? const <LookupOption>[];
    final picked = await _pickFromList<LookupOption?>(
      title: '选择团队',
      options: <LookupOption?>[null, ...teams],
      labelBuilder: (o) => o?.title ?? '无',
      iconBuilder: (o) => o == null
          ? const _OptionVisual(
              icon: Icons.groups_outlined, color: Color(0xFF94A3B8))
          : const _OptionVisual(
              icon: Icons.groups_rounded, color: Color(0xFF8E4BC3)),
      current: _item!.team,
    );
    if (picked == null && _item!.team == null) return;
    if (picked == null) {
      await _api.updateWorkItemFields(_item!.id, clearTeam: true);
      _patch(team: const _Cleared());
    } else {
      await _api.updateWorkItemFields(_item!.id, teamId: picked.id);
      _patch(team: picked);
    }
  }

  Future<void> _pickSprint() async {
    final picked = await _pickFromList<Sprint?>(
      title: '选择冲刺',
      options: <Sprint?>[null, ..._sprints],
      labelBuilder: (s) => s?.name ?? '无',
      iconBuilder: (s) => s == null
          ? const _OptionVisual(
              icon: Icons.flag_outlined, color: Color(0xFF94A3B8))
          : _OptionVisual(
              icon: s.status == SprintStatus.active
                  ? Icons.play_arrow_rounded
                  : Icons.flag_rounded,
              color: s.status == SprintStatus.active
                  ? const Color(0xFF1F5DBD)
                  : const Color(0xFF44546F),
            ),
      current: _sprints.firstWhere(
        (s) => s.id == _item!.sprint?.id,
        orElse: () => const Sprint(
            id: 0, workspaceId: 0, name: '', status: SprintStatus.planned),
      ),
    );
    if (picked == null && _item!.sprint == null) return;
    if (picked == null) {
      await _api.updateWorkItemFields(_item!.id, clearSprint: true);
      _patch(sprint: const _Cleared());
    } else {
      await _api.updateWorkItemFields(_item!.id, sprintId: picked.id);
      _patch(sprint: picked.toLookup());
    }
  }

  Future<void> _pickPriority() async {
    const opts = ['Highest', 'High', 'Medium', 'Low', 'Lowest'];
    final picked = await _pickFromList<String?>(
      title: '设置优先级',
      options: <String?>[null, ...opts],
      labelBuilder: (v) => v ?? '无',
      iconBuilder: (v) {
        switch (v) {
          case 'Highest':
            return const _OptionVisual(
              icon: Icons.keyboard_double_arrow_up_rounded,
              color: Color(0xFFE5493A),
            );
          case 'High':
            return const _OptionVisual(
              icon: Icons.keyboard_arrow_up_rounded,
              color: Color(0xFFFF8B6B),
            );
          case 'Medium':
            return const _OptionVisual(
              icon: Icons.drag_handle_rounded,
              color: Color(0xFFFF8B00),
            );
          case 'Low':
            return const _OptionVisual(
              icon: Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6CA6FF),
            );
          case 'Lowest':
            return const _OptionVisual(
              icon: Icons.keyboard_double_arrow_down_rounded,
              color: Color(0xFF4C84FF),
            );
          default:
            return const _OptionVisual(
              icon: Icons.remove_rounded, color: Color(0xFF94A3B8));
        }
      },
      current: null,
    );
    if (picked == null) {
      await _api.updateWorkItemFields(_item!.id, clearPriority: true);
    } else {
      await _api.updateWorkItemFields(_item!.id, priority: picked);
    }
  }

  Future<void> _pickParent() async {
    final options = await _api.listParentItems(workspaceId: _item!.workspace.id);
    final picked = await _pickFromList<LookupOption?>(
      title: '选择父工作项',
      options: <LookupOption?>[null, ...options],
      labelBuilder: (o) => o?.title ?? '无',
      iconBuilder: (o) => o == null
          ? const _OptionVisual(
              icon: Icons.remove_rounded, color: Color(0xFF94A3B8))
          : const _OptionVisual(
              icon: Icons.account_tree_rounded, color: Color(0xFF1F5DBD)),
      current: _item!.parent,
    );
    if (picked == null && _item!.parent == null) return;
    if (picked == null) {
      await _api.updateWorkItemFields(_item!.id, clearParent: true);
      _patch(parent: const _Cleared());
    } else {
      await _api.updateWorkItemFields(_item!.id, parentId: picked.id);
      _patch(parent: picked);
    }
  }

  Future<void> _pickDueDate() async {
    final initial = _item!.dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 5),
    );
    if (picked == null) return;
    await _api.updateWorkItemFields(_item!.id, dueDate: picked);
    if (!mounted) return;
    _patch(dueDate: picked);
  }

  Future<void> _pickStartDate() async {
    final initial = _item!.startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 5),
    );
    if (picked == null) return;
    await _api.updateWorkItemFields(_item!.id, startDate: picked);
    if (!mounted) return;
    _patch(startDate: picked);
  }

  Future<T?> _pickFromList<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelBuilder,
    required T? current,
    _OptionVisual Function(T)? iconBuilder,
  }) async {
    final palette = AppThemePalette.of(context);
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            SheetHeader(title: title),
            ...options.map(
              (o) {
                final visual = iconBuilder?.call(o);
                return ListTile(
                  leading: visual == null
                      ? null
                      : Icon(visual.icon, color: visual.color),
                  title: Text(labelBuilder(o)),
                  trailing: o == current
                      ? Icon(Icons.check_rounded, color: palette.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(WorkItemResponse item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('更多字段',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 14),
              _ReadOnlyRow(label: '项目', value: item.workspace.title),
              if (item.createdAt != null)
                _ReadOnlyRow(
                  label: '已创建',
                  value: _formatDateTime(item.createdAt!),
                ),
              if (item.lastViewedAt != null)
                _ReadOnlyRow(
                  label: '已更新',
                  value: _formatDateTime(item.lastViewedAt!),
                ),
              _ReadOnlyRow(label: '类型', value: item.workType.title),
              _ReadOnlyRow(label: '报告人', value: item.reporter.title),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _formatDateTime(DateTime d) =>
      '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _patch({
    String? summary,
    String? description,
    WorkItemStatus? status,
    Object? assignee,
    Object? team,
    Object? sprint,
    Object? parent,
    DateTime? dueDate,
    DateTime? startDate,
  }) {
    if (_item == null) return;
    setState(() {
      _item = WorkItemResponse(
        id: _item!.id,
        summary: summary ?? _item!.summary,
        workspace: _item!.workspace,
        workType: _item!.workType,
        reporter: _item!.reporter,
        labels: _item!.labels,
        attachments: _item!.attachments,
        key: _item!.key,
        bucket: _item!.bucket,
        status: status ?? _item!.status,
        description: description ?? _item!.description,
        assignee: assignee is _Cleared
            ? null
            : (assignee as LookupOption?) ?? _item!.assignee,
        parent: parent is _Cleared
            ? null
            : (parent as LookupOption?) ?? _item!.parent,
        team: team is _Cleared
            ? null
            : (team as LookupOption?) ?? _item!.team,
        sprint: sprint is _Cleared
            ? null
            : (sprint as LookupOption?) ?? _item!.sprint,
        dueDate: dueDate ?? _item!.dueDate,
        startDate: startDate ?? _item!.startDate,
        createdAt: _item!.createdAt,
        lastViewedAt: _item!.lastViewedAt,
      );
    });
  }
}

class _Cleared {
  const _Cleared();
}

class _OptionVisual {
  const _OptionVisual({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.onTap});

  final WorkItemStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(status);
    final label = workItemStatusLabel(status);
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.foreground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: colors.foreground),
            ],
          ),
        ),
      ),
    );
  }

  static _StatusColors _statusColors(WorkItemStatus status) {
    switch (status) {
      case WorkItemStatus.todo:
        return const _StatusColors(
          background: Color(0xFFE7E9EF),
          foreground: Color(0xFF44546F),
        );
      case WorkItemStatus.inProgress:
        return const _StatusColors(
          background: Color(0xFFE3EEFF),
          foreground: Color(0xFF1F5DBD),
        );
      case WorkItemStatus.done:
        return const _StatusColors(
          background: Color(0xFFD9F5E3),
          foreground: Color(0xFF1F8B4C),
        );
    }
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});
  final Color background;
  final Color foreground;
}

class _SquareIconChip extends StatelessWidget {
  const _SquareIconChip({
    required this.icon,
    required this.tint,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: palette.surfaceInset,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: tint, size: 20),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: child);
    return child;
  }
}

class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({required this.item});

  final WorkItemResponse item;

  @override
  Widget build(BuildContext context) {
    final initials =
        (item.assignee?.title ?? 'MT').characters.take(2).toString().toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF2C9C9F),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.item,
    required this.onEditAssignee,
    required this.onEditTeam,
    required this.onEditDueDate,
    required this.onEditStartDate,
    required this.onEditSprint,
  });

  final WorkItemResponse item;
  final VoidCallback onEditAssignee;
  final VoidCallback onEditTeam;
  final VoidCallback onEditDueDate;
  final VoidCallback onEditStartDate;
  final VoidCallback onEditSprint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('详细信息',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.expand_more_rounded, color: palette.textSecondary),
              ],
            ),
          ),
          _EditableRow(
            label: '事务类型',
            value: item.workType.title,
            onTap: null,
          ),
          _EditableRow(
            label: '经办人',
            value: item.assignee?.title ?? '未分配',
            onTap: onEditAssignee,
          ),
          _EditableRow(
            label: '冲刺',
            value: item.sprint?.title ?? '无',
            onTap: onEditSprint,
          ),
          _EditableRow(
            label: '截止日期',
            value: item.dueDate == null
                ? '未设置'
                : _fmt(item.dueDate!),
            onTap: onEditDueDate,
          ),
          _EditableRow(
            label: 'Team',
            value: item.team?.title ?? '无',
            onTap: onEditTeam,
          ),
          _EditableRow(
            label: '开始日期',
            value: item.startDate == null
                ? '未设置'
                : _fmt(item.startDate!),
            onTap: onEditStartDate,
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
