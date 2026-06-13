import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/DatePickerSheet.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/components/Common/work_type_icon.dart';
import 'package:ottersync/services/pomodoro_service.dart';
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
  List<LookupOption> _members = const [];
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
      final members = item == null
          ? <LookupOption>[]
          : await _api.loadWorkspaceMembers(item.workspace.id);
      if (!mounted) return;
      setState(() {
        _item = item;
        _lookups = lookups;
        _sprints = sprints;
        _members = members;
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
          _buildFocusAction(),
          IconButton(
            tooltip: '附件',
            onPressed: _item == null ? null : _openAttachments,
            icon: const Icon(Icons.attach_file_rounded),
          ),
          IconButton(
            tooltip: '更多',
            onPressed: _item == null ? null : _openMoreMenu,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// AppBar 上的「专注计时」按钮：未计时时点开选时长 sheet；
  /// 正在计时时显示剩余 mm:ss，再点则停止。状态由前台服务驱动。
  Widget _buildFocusAction() {
    final palette = AppThemePalette.of(context);
    return ListenableBuilder(
      listenable: PomodoroController.instance,
      builder: (context, _) {
        final pomodoro = PomodoroController.instance;
        if (pomodoro.isRunning) {
          return TextButton.icon(
            onPressed: pomodoro.stop,
            icon: Icon(Icons.timer_rounded, color: palette.primary, size: 20),
            label: Text(
              pomodoro.remainingClock,
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        }
        return IconButton(
          tooltip: '专注计时',
          onPressed: _startFocus,
          icon: const Icon(Icons.timer_outlined),
        );
      },
    );
  }

  /// 弹出底部 sheet 选择专注时长，并启动番茄钟前台服务。
  Future<void> _startFocus() async {
    final item = _item;
    if (item == null) return;

    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        const options = <int>[25, 15, 5];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: '专注计时'),
              for (final m in options)
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text('$m 分钟'),
                  onTap: () => Navigator.of(sheetContext).pop(m),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (minutes == null || !mounted) return;

    final ok = await PomodoroController.instance.start(
      taskName: item.summary,
      duration: Duration(minutes: minutes),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法启动专注计时，请检查通知权限')),
      );
    }
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
    final users = _members;
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

  Future<void> _openAttachments() async {
    final palette = AppThemePalette.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final attachments = _item!.attachments;
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetHeader(
                    title: '附件',
                    trailing: TextButton.icon(
                      onPressed: () async {
                        final added = await _addAttachment();
                        if (added) setSheetState(() {});
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('添加'),
                    ),
                  ),
                  if (attachments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        '暂无附件',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                            ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: attachments.length,
                        itemBuilder: (ctx, index) {
                          final att = attachments[index];
                          return ListTile(
                            leading: Icon(
                              _attachmentIcon(att.kind),
                              color: palette.primary,
                            ),
                            title: Text(att.name),
                            subtitle: att.uri.isEmpty
                                ? null
                                : Text(
                                    att.uri,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: IconButton(
                              tooltip: '删除',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: palette.danger,
                              ),
                              onPressed: () async {
                                final removed =
                                    await _removeAttachment(index);
                                if (removed) setSheetState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _addAttachment() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final uriController = TextEditingController();
    final mimeTypeController = TextEditingController();
    AttachmentKind selectedKind = AttachmentKind.document;

    final result = await showDialog<AttachmentCreateRequest>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('添加附件'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入名称' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AttachmentKind>(
                  initialValue: selectedKind,
                  decoration: const InputDecoration(labelText: '类型'),
                  items: AttachmentKind.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(_attachmentKindLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedKind = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: uriController,
                  decoration: const InputDecoration(labelText: '地址或路径'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入地址' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mimeTypeController,
                  decoration:
                      const InputDecoration(labelText: 'MIME 类型（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop(
                  AttachmentCreateRequest(
                    name: nameController.text.trim(),
                    kind: selectedKind,
                    uri: uriController.text.trim(),
                    mimeType: mimeTypeController.text.trim().isEmpty
                        ? null
                        : mimeTypeController.text.trim(),
                  ),
                );
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    uriController.dispose();
    mimeTypeController.dispose();

    if (result == null) return false;
    try {
      final updated = await _api.addAttachment(_item!.id, result);
      if (!mounted) return false;
      if (updated != null) setState(() => _item = updated);
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnackBar('添加失败：$e');
      return false;
    }
  }

  Future<bool> _removeAttachment(int index) async {
    try {
      final updated = await _api.removeAttachment(_item!.id, index);
      if (!mounted) return false;
      if (updated != null) setState(() => _item = updated);
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnackBar('删除失败：$e');
      return false;
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

  String _attachmentKindLabel(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.photo:
        return '图片';
      case AttachmentKind.video:
        return '视频';
      case AttachmentKind.document:
        return '文档';
    }
  }

  Future<void> _openMoreMenu() async {
    final palette = AppThemePalette.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: '更多操作'),
            ListTile(
              leading: Icon(Icons.subdirectory_arrow_right_rounded,
                  color: palette.primary),
              title: const Text('创建子工作项'),
              onTap: () {
                Navigator.pop(ctx);
                _createChildItem();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.account_tree_rounded, color: palette.primary),
              title: const Text('分配给父工作项'),
              onTap: () {
                Navigator.pop(ctx);
                _pickParent();
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: palette.primary),
              title: const Text('复制工作项 Key'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: _item!.key));
                _showSnackBar('已复制 ${_item!.key}');
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline_rounded, color: palette.danger),
              title: Text('删除工作项',
                  style: TextStyle(color: palette.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteItem();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createChildItem() async {
    final controller = TextEditingController();
    final summary = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建子工作项'),
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
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (summary == null || summary.isEmpty) return;
    try {
      await _api.createWorkItem(
        WorkItemCreateRequest(
          workspaceId: _item!.workspace.id,
          workTypeId: _item!.workType.id,
          summary: summary,
          reporterId: _item!.reporter.id,
          parentId: _item!.id,
        ),
      );
      if (!mounted) return;
      _showSnackBar('已创建子工作项');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('创建失败：$e');
    }
  }

  Future<void> _deleteItem() async {
    final palette = AppThemePalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除工作项'),
        content: const Text('确定要删除此工作项吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteWorkItem(_item!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('删除失败：$e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDueDate() async {
    final start = _item!.startDate;
    final result = await showDatePickerSheet(
      context,
      title: '选择截止日期',
      initialEnd: _item!.dueDate ?? start ?? DateTime.now(),
      minDate: start,
      allowRange: false,
    );
    if (result?.end == null) return;
    await _api.updateWorkItemFields(_item!.id, dueDate: result!.end);
    if (!mounted) return;
    _patch(dueDate: result.end);
  }

  Future<void> _pickStartDate() async {
    final due = _item!.dueDate;
    final result = await showDatePickerSheet(
      context,
      title: '选择开始日期',
      initialEnd: _item!.startDate ?? due ?? DateTime.now(),
      maxDate: due,
      allowRange: false,
    );
    if (result?.end == null) return;
    await _api.updateWorkItemFields(_item!.id, startDate: result!.end);
    if (!mounted) return;
    _patch(startDate: result.end);
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
              if (item.updatedAt != null)
                _ReadOnlyRow(
                  label: '已更新',
                  value: _formatDateTime(item.updatedAt!),
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
        updatedAt: _item!.updatedAt,
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
    final radius = BorderRadius.circular(8);
    final child = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: tint.withValues(alpha: 0.18),
          highlightColor: tint.withValues(alpha: 0.08),
          child: Center(child: Icon(icon, color: tint, size: 20)),
        ),
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
            label: '开始日期',
            value: item.startDate == null
                ? '未设置'
                : _fmt(item.startDate!),
            onTap: onEditStartDate,
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
