import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class WorkItemDetailView extends StatefulWidget {
  const WorkItemDetailView({super.key, required this.workItemId});

  final int? workItemId;

  @override
  State<WorkItemDetailView> createState() => _WorkItemDetailViewState();
}

class _WorkItemDetailViewState extends State<WorkItemDetailView> {
  final _api = WorkItemApi();
  WorkItemResponse? _item;
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
      final item = await _api.getWorkItemById(widget.workItemId!);
      if (!mounted) return;
      setState(() {
        _item = item;
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
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          _item?.key ?? '工作项详情',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme, palette)
              : _buildContent(theme, palette),
    );
  }

  Widget _buildErrorState(ThemeData theme, AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: palette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadItem,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AppPalette palette) {
    final item = _item!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      children: [
        // 标题
        Text(
          item.summary,
          style: theme.textTheme.headlineMedium?.copyWith(height: 1.3),
        ),
        const SizedBox(height: 16),

        // 状态 + 类型标签
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => _updateStatus(_nextStatus(item.status)),
              child: _StatusChip(status: item.status),
            ),
            _TypeChip(workType: item.workType),
            if (item.bucket == WorkItemBucket.sprint)
              _TagChip(
                label: 'Sprint',
                color: palette.primary,
                backgroundColor: palette.primarySoft,
              ),
          ],
        ),
        const SizedBox(height: 24),

        // 描述
        if (item.description != null && item.description!.isNotEmpty) ...[
          Text('描述', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          AppSurface(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.description!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 详情字段
        Text('详情', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        AppSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _DetailRow(label: '经办人', value: item.assignee?.title ?? '未分配'),
              _DetailRow(label: '报告人', value: item.reporter.title),
              if (item.team != null)
                _DetailRow(label: '团队', value: item.team!.title),
              if (item.parent != null)
                _DetailRow(label: '父项', value: item.parent!.title),
              _DetailRow(
                label: '工作区',
                value: '${item.workspace.title} (${item.key.split('-').first})',
              ),
              _DetailRow(label: '类型', value: item.workType.title),
              if (item.startDate != null)
                _DetailRow(
                  label: '开始日期',
                  value: _formatDate(item.startDate!),
                ),
              if (item.dueDate != null)
                _DetailRow(
                  label: '截止日期',
                  value: _formatDate(item.dueDate!),
                ),
              if (item.createdAt != null)
                _DetailRow(
                  label: '创建时间',
                  value: _formatDateTime(item.createdAt!),
                ),
            ],
          ),
        ),

        // 标签
        if (item.labels.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('标签', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.labels
                .map(
                  (label) => Chip(
                    label: Text(label.title),
                    backgroundColor: palette.surfaceRaised,
                    side: BorderSide(color: palette.border),
                  ),
                )
                .toList(),
          ),
        ],

        // 附件
        if (item.attachments.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('附件', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...item.attachments.map(
            (att) => AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _attachmentIcon(att.kind),
                    color: palette.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      att.name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(WorkItemStatus newStatus) async {
    try {
      await _api.updateWorkItemStatus(_item!.id, newStatus);
      if (!mounted) return;
      setState(() {
        _item = WorkItemResponse(
          id: _item!.id,
          summary: _item!.summary,
          workspace: _item!.workspace,
          workType: _item!.workType,
          reporter: _item!.reporter,
          labels: _item!.labels,
          attachments: _item!.attachments,
          key: _item!.key,
          bucket: _item!.bucket,
          status: newStatus,
          description: _item!.description,
          assignee: _item!.assignee,
          parent: _item!.parent,
          team: _item!.team,
          dueDate: _item!.dueDate,
          startDate: _item!.startDate,
          createdAt: _item!.createdAt,
          lastViewedAt: _item!.lastViewedAt,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('状态更新失败：$e')),
      );
    }
  }

  WorkItemStatus _nextStatus(WorkItemStatus current) {
    switch (current) {
      case WorkItemStatus.todo:
        return WorkItemStatus.inProgress;
      case WorkItemStatus.inProgress:
        return WorkItemStatus.done;
      case WorkItemStatus.done:
        return WorkItemStatus.todo;
    }
  }

  IconData _attachmentIcon(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.photo:
        return Icons.image_outlined;
      case AttachmentKind.video:
        return Icons.videocam_outlined;
      case AttachmentKind.document:
        return Icons.description_outlined;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final WorkItemStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final (label, color) = switch (status) {
      WorkItemStatus.todo => ('待办', palette.textSecondary),
      WorkItemStatus.inProgress => ('进行中', palette.primary),
      WorkItemStatus.done => ('已完成', const Color(0xFF22A06B)),
    };

    return _TagChip(
      label: label,
      color: color,
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.workType});

  final LookupOption workType;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return _TagChip(
      label: workType.title,
      color: palette.textSecondary,
      backgroundColor: palette.surfaceInset,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
