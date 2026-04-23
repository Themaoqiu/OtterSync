import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class CreateWorkItemPage extends StatefulWidget {
  const CreateWorkItemPage({super.key});

  @override
  State<CreateWorkItemPage> createState() => _CreateWorkItemPageState();
}

class _CreateWorkItemPageState extends State<CreateWorkItemPage> {
  static const List<AttachmentKind> _attachmentKinds = [
    AttachmentKind.photo,
    AttachmentKind.video,
    AttachmentKind.document,
  ];

  final WorkItemApi _api = WorkItemApi();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newLabelsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _descriptionExpanded = true;
  bool _attachmentsExpanded = true;
  bool _moreExpanded = true;
  String? _loadError;

  List<LookupOption> _workspaces = const [];
  List<LookupOption> _workTypes = const [];
  List<LookupOption> _users = const [];
  List<LookupOption> _teams = const [];
  List<LookupOption> _labels = const [];
  List<LookupOption> _parentItems = const [];
  final List<AttachmentCreateRequest> _attachments = [];
  final Set<int> _selectedLabelIds = <int>{};

  LookupOption? _selectedWorkspace;
  LookupOption? _selectedWorkType;
  LookupOption? _selectedReporter;
  LookupOption? _selectedAssignee;
  LookupOption? _selectedTeam;
  LookupOption? _selectedParent;
  DateTime? _startDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    _newLabelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildLoadError(context)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _LookupPill(
                          icon: Icons.hub_outlined,
                          label: _selectedWorkspace?.title ?? '选择空间',
                          subtitle: _selectedWorkspace?.subtitle,
                          onTap: () async {
                            final result = await _pickLookup(
                              title: '选择空间',
                              options: _workspaces,
                              selected: _selectedWorkspace,
                            );
                            if (result != null) {
                              setState(() {
                                _selectedWorkspace = result;
                                _selectedParent = null;
                              });
                              await _loadParentItems();
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: palette.textTertiary,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: _LookupPill(
                          icon: Icons.check_box_outlined,
                          label: _selectedWorkType?.title ?? '选择类型',
                          subtitle: _selectedWorkType?.subtitle,
                          onTap: () async {
                            final result = await _pickLookup(
                              title: '选择工作类型',
                              options: _workTypes,
                              selected: _selectedWorkType,
                            );
                            if (result != null) {
                              setState(() => _selectedWorkType = result);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _summaryController,
                    maxLength: 200,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '添加摘要...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CircleIconButton(
                      icon: Icons.person_outline_rounded,
                      onTap: () async {
                        final result = await _pickLookup(
                          title: '选择处理人',
                          options: _users,
                          selected: _selectedAssignee,
                          allowClear: true,
                        );
                        if (result != _selectedAssignee) {
                          setState(() => _selectedAssignee = result);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    context,
                    title: '描述',
                    expanded: _descriptionExpanded,
                    onToggle: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: '添加描述……',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: '附件',
                    expanded: _attachmentsExpanded,
                    onToggle: () => setState(
                      () => _attachmentsExpanded = !_attachmentsExpanded,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _addAttachment,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('添加附件'),
                        ),
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ..._attachments.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AttachmentTile(
                                attachment: entry.value,
                                onDelete: _saving
                                    ? null
                                    : () {
                                        setState(
                                          () => _attachments.removeAt(entry.key),
                                        );
                                      },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: '更多字段',
                    expanded: _moreExpanded,
                    onToggle: () =>
                        setState(() => _moreExpanded = !_moreExpanded),
                    child: Column(
                      children: [
                        _FieldTile(
                          title: '经办人',
                          value: _selectedReporter?.title ?? '请选择',
                          helper: _selectedReporter?.subtitle,
                          leading: const Icon(Icons.person_outline_rounded),
                          onTap: () async {
                            final result = await _pickLookup(
                              title: '选择经办人',
                              options: _users,
                              selected: _selectedReporter,
                            );
                            if (result != null) {
                              setState(() => _selectedReporter = result);
                            }
                          },
                        ),
                        _FieldTile(
                          title: '处理人',
                          value: _selectedAssignee?.title ?? '无',
                          helper: _selectedAssignee?.subtitle,
                          leading: const Icon(Icons.assignment_ind_outlined),
                          onTap: () async {
                            final result = await _pickLookup(
                              title: '选择处理人',
                              options: _users,
                              selected: _selectedAssignee,
                              allowClear: true,
                            );
                            if (result != _selectedAssignee) {
                              setState(() => _selectedAssignee = result);
                            }
                          },
                        ),
                        _FieldTile(
                          title: '标签',
                          value: _selectedLabelIds.isEmpty
                              ? '无'
                              : '${_selectedLabelIds.length} 个',
                          helper: _selectedLabelNames.join('、'),
                          leading: const Icon(Icons.sell_outlined),
                          onTap: _toggleLabelSheet,
                        ),
                        _FieldTile(
                          title: '父项',
                          value: _selectedParent?.title ?? '无',
                          helper: _selectedParent?.subtitle,
                          leading: const Icon(Icons.account_tree_outlined),
                          onTap: () async {
                            final result = await _pickLookup(
                              title: '选择父项',
                              options: _parentItems,
                              selected: _selectedParent,
                              allowClear: true,
                              emptyLabel: '当前空间暂无父项可选',
                            );
                            if (result != _selectedParent) {
                              setState(() => _selectedParent = result);
                            }
                          },
                        ),
                        _FieldTile(
                          title: '团队',
                          value: _selectedTeam?.title ?? '无',
                          helper: _selectedTeam?.subtitle,
                          leading: const Icon(Icons.groups_2_outlined),
                          onTap: () async {
                            final result = await _pickLookup(
                              title: '选择团队',
                              options: _teams,
                              selected: _selectedTeam,
                              allowClear: true,
                            );
                            if (result != _selectedTeam) {
                              setState(() => _selectedTeam = result);
                            }
                          },
                        ),
                        _FieldTile(
                          title: '开始日期',
                          value: _formatDate(_startDate) ?? '无',
                          leading: const Icon(Icons.calendar_today_outlined),
                          onTap: () => _pickDate(
                            initial: _startDate,
                            onPicked: (value) => setState(() => _startDate = value),
                          ),
                        ),
                        _FieldTile(
                          title: '截止日期',
                          value: _formatDate(_dueDate) ?? '无',
                          leading: const Icon(Icons.event_available_outlined),
                          onTap: () => _pickDate(
                            initial: _dueDate,
                            onPicked: (value) => setState(() => _dueDate = value),
                          ),
                          showDivider: false,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newLabelsController,
                          decoration: const InputDecoration(
                            labelText: '新标签',
                            hintText: '多个标签请用逗号分隔',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.close_rounded,
          onTap: _saving ? null : () => context.pop(),
        ),
        Expanded(
          child: Center(
            child: Text(
              '创建',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _CircleIconButton(
          icon: Icons.check_rounded,
          filled: true,
          busy: _saving,
          onTap: _saving ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildLoadError(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: palette.textTertiary, size: 40),
            const SizedBox(height: 14),
            Text('加载失败', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _loadError ?? '请检查后端服务是否已启动。',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _loadInitialData,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSpace.radius),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.expand_more_rounded),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 18),
            child,
          ],
        ],
      ),
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final lookups = await _api.loadCreateLookups();
      if (!mounted) {
        return;
      }
      setState(() {
        _workspaces = lookups.workspaces;
        _workTypes = lookups.workTypes;
        _users = lookups.users;
        _teams = lookups.teams;
        _labels = lookups.labels;
        _selectedWorkspace = _selectedWorkspace ?? _firstOrNull(_workspaces);
        _selectedWorkType = _selectedWorkType ?? _firstOrNull(_workTypes);
        _selectedReporter = _selectedReporter ?? _firstOrNull(_users);
        _loading = false;
      });
      await _loadParentItems();
    } catch (error) {
      debugPrint('CreateWorkItemPage load failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _loadParentItems() async {
    final workspace = _selectedWorkspace;
    if (workspace == null) {
      setState(() => _parentItems = const []);
      return;
    }
    try {
      final items = await _api.listParentItems(workspaceId: workspace.id);
      if (!mounted) {
        return;
      }
      setState(() => _parentItems = items);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _parentItems = const []);
    }
  }

  Future<void> _submit() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) {
      _showSnackBar('请输入摘要');
      return;
    }
    if (_selectedWorkspace == null || _selectedWorkType == null || _selectedReporter == null) {
      _showSnackBar('请先选择空间、类型和经办人');
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await _api.createWorkItem(
        WorkItemCreateRequest(
          workspaceId: _selectedWorkspace!.id,
          workTypeId: _selectedWorkType!.id,
          summary: summary,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          reporterId: _selectedReporter!.id,
          assigneeId: _selectedAssignee?.id,
          parentId: _selectedParent?.id,
          teamId: _selectedTeam?.id,
          dueDate: _dueDate,
          startDate: _startDate,
          labelIds: _selectedLabelIds.toList(),
          newLabelNames: _splitLabels(_newLabelsController.text),
          attachments: List<AttachmentCreateRequest>.from(_attachments),
        ),
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('已创建 ${response.summary}');
      context.pop(response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('$error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addAttachment() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final uriController = TextEditingController();
    final mimeTypeController = TextEditingController();
    AttachmentKind selectedKind = AttachmentKind.document;

    final result = await showDialog<AttachmentCreateRequest>(
      context: context,
      builder: (context) {
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
                  items: _attachmentKinds
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(_attachmentKindLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedKind = value;
                    }
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
                  decoration: const InputDecoration(labelText: 'MIME 类型（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) {
                  return;
                }
                Navigator.of(context).pop(
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

    if (result != null) {
      setState(() => _attachments.add(result));
    }
  }

  Future<void> _toggleLabelSheet() async {
    final selected = Set<int>.from(_selectedLabelIds);
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final palette = AppThemePalette.of(context);
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('选择标签', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _labels.map((label) {
                        final isSelected = selected.contains(label.id);
                        return FilterChip(
                          label: Text(label.title),
                          selected: isSelected,
                          selectedColor: palette.primarySoft,
                          checkmarkColor: palette.primary,
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selected.add(label.id);
                              } else {
                                selected.remove(label.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(selected),
                        child: const Text('完成'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedLabelIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<LookupOption?> _pickLookup({
    required String title,
    required List<LookupOption> options,
    LookupOption? selected,
    bool allowClear = false,
    String emptyLabel = '暂无可选项',
  }) {
    return showModalBottomSheet<LookupOption?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final screenHeight = MediaQuery.of(context).size.height;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (allowClear)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('清空'),
                    onTap: () => Navigator.of(context).pop(null),
                  ),
                if (options.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(emptyLabel, style: theme.textTheme.bodyMedium),
                  )
                else
                  SizedBox(
                    height: screenHeight * 0.5,
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final item = options[index];
                        final isSelected = item.id == selected?.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: item.subtitle == null
                              ? null
                              : Text(item.subtitle!),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _splitLabels(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> get _selectedLabelNames {
    final selectedIds = _selectedLabelIds;
    return _labels
        .where((item) => selectedIds.contains(item.id))
        .map((item) => item.title)
        .toList();
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _attachmentKindLabel(AttachmentKind kind) {
    if (kind == AttachmentKind.photo) {
      return '图片';
    }
    if (kind == AttachmentKind.video) {
      return '视频';
    }
    return '文档';
  }

  T? _firstOrNull<T>(List<T> items) {
    if (items.isEmpty) {
      return null;
    }
    return items.first;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LookupPill extends StatelessWidget {
  const _LookupPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
          boxShadow: AppShadows.cardSoft,
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.onTap,
    this.filled = false,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radiusFull),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: filled ? palette.surfaceInset : palette.surface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: palette.primary,
                  ),
                )
              : Icon(
                  icon,
                  color: onTap == null ? palette.textTertiary : palette.textPrimary,
                  size: 28,
                ),
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.title,
    required this.value,
    required this.leading,
    required this.onTap,
    this.helper,
    this.showDivider = true,
  });

  final String title;
  final String value;
  final String? helper;
  final Widget leading;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: palette.divider))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.surfaceInset,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: palette.textSecondary),
                  child: leading,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: value == '无' || value == '请选择'
                          ? palette.textTertiary
                          : palette.textPrimary,
                    ),
                  ),
                  if (helper != null && helper!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      helper!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, this.onDelete});

  final AttachmentCreateRequest attachment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppSpace.radius),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, color: palette.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attachment.name, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${attachment.kind.value} · ${attachment.uri}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
