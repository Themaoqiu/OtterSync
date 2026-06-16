import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/services/work_item_service.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class SprintManagerSheet extends StatefulWidget {
  const SprintManagerSheet({
    super.key,
    required this.api,
    required this.workspaceId,
    required this.onChanged,
  });

  final WorkItemService api;
  final int workspaceId;
  final VoidCallback onChanged;

  @override
  State<SprintManagerSheet> createState() => _SprintManagerSheetState();
}

class _SprintManagerSheetState extends State<SprintManagerSheet> {
  bool _loading = true;
  String? _error;
  List<Sprint> _sprints = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.listSprints(
        workspaceId: widget.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _sprints = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final payload = await _showCreateDialog(context);
    if (payload == null) return;
    try {
      await widget.api.createSprint(
        SprintCreateRequest(
          workspaceId: widget.workspaceId,
          name: payload.name,
          goal: payload.goal,
          startDate: payload.startDate,
          endDate: payload.endDate,
        ),
      );
      widget.onChanged();
      await _reload();
    } catch (e) {
      _showError('创建失败：$e');
    }
  }

  Future<void> _updateStatus(int id, SprintStatus status) async {
    try {
      await widget.api.updateSprintStatus(id, status);
      widget.onChanged();
      await _reload();
    } catch (e) {
      _showError('更新失败：$e');
    }
  }

  Future<void> _delete(int id) async {
    try {
      await widget.api.deleteSprint(id);
      widget.onChanged();
      await _reload();
    } catch (e) {
      _showError('删除失败：$e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('冲刺管理', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('新建冲刺'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '冲刺用于将待办事项分组到一段时间内的工作目标中。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Text(_error!, style: theme.textTheme.bodyMedium),
                      )
                    : _sprints.isEmpty
                    ? _EmptyHint(palette: palette)
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _sprints.length,
                        separatorBuilder: (a, b) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _SprintCard(
                          sprint: _sprints[index],
                          onUpdateStatus: _updateStatus,
                          onDelete: _delete,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<_NewSprintDraft?> _showCreateDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final goalController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  final result = await showDialog<_NewSprintDraft>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('新建冲刺'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '名称'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: goalController,
                    decoration: const InputDecoration(labelText: '目标（可选）'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _DateRow(
                    label: '开始日期',
                    value: startDate,
                    onPick: () async {
                      final picked = await _pickDate(ctx, startDate);
                      if (picked != null) {
                        setState(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _DateRow(
                    label: '结束日期',
                    value: endDate,
                    onPick: () async {
                      final picked = await _pickDate(ctx, endDate);
                      if (picked != null) {
                        setState(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    ctx,
                    _NewSprintDraft(
                      name: name,
                      goal: goalController.text.trim().isEmpty
                          ? null
                          : goalController.text.trim(),
                      startDate: startDate,
                      endDate: endDate,
                    ),
                  );
                },
                child: const Text('创建'),
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}

class _NewSprintDraft {
  const _NewSprintDraft({
    required this.name,
    this.goal,
    this.startDate,
    this.endDate,
  });

  final String name;
  final String? goal;
  final DateTime? startDate;
  final DateTime? endDate;
}

Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 2),
    lastDate: DateTime(now.year + 5),
  );
}

class _SprintCard extends StatelessWidget {
  const _SprintCard({
    required this.sprint,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  final Sprint sprint;
  final Future<void> Function(int id, SprintStatus status) onUpdateStatus;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    final statusLabel = _statusLabel(sprint.status);
    final statusColor = _statusColor(sprint.status, palette);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sprint.name, style: theme.textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sprint.goal!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: palette.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                _dateRangeLabel(sprint.startDate, sprint.endDate),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (sprint.status == SprintStatus.planned)
                TextButton.icon(
                  onPressed: () =>
                      onUpdateStatus(sprint.id, SprintStatus.active),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('启动冲刺'),
                ),
              if (sprint.status == SprintStatus.active)
                TextButton.icon(
                  onPressed: () =>
                      onUpdateStatus(sprint.id, SprintStatus.completed),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('结束冲刺'),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: Icon(Icons.delete_outline_rounded, color: palette.danger),
                tooltip: '删除冲刺',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除冲刺'),
        content: const Text('删除后该冲刺下的工作项将回到普通待办。该操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await onDelete(sprint.id);
    }
  }

  String _statusLabel(SprintStatus status) {
    switch (status) {
      case SprintStatus.planned:
        return '计划中';
      case SprintStatus.active:
        return '进行中';
      case SprintStatus.completed:
        return '已结束';
    }
  }

  Color _statusColor(SprintStatus status, AppPalette palette) {
    switch (status) {
      case SprintStatus.planned:
        return palette.textSecondary;
      case SprintStatus.active:
        return palette.primary;
      case SprintStatus.completed:
        return palette.textTertiary;
    }
  }

  String _dateRangeLabel(DateTime? start, DateTime? end) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (start == null && end == null) return '未设置时间';
    if (start != null && end != null) return '${fmt(start)} ~ ${fmt(end)}';
    if (start != null) return '从 ${fmt(start)}';
    return '至 ${fmt(end!)}';
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: palette.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              value == null
                  ? '未设置'
                  : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: value == null
                    ? palette.textTertiary
                    : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 48, color: palette.textTertiary),
          const SizedBox(height: 12),
          Text('该空间还没有冲刺', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '点击右上角“新建冲刺”开始规划。',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
