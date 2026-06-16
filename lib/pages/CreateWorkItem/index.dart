import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemAttachmentsSection.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemLoadError.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemMoreFieldsSection.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemSectionCard.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemTopBar.dart';
import 'package:ottersync/components/CreateWorkItem/TypeSelectorBar.dart';
import 'package:ottersync/components/Common/DatePickerSheet.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/services/work_item_service.dart';
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

  final WorkItemService _api = WorkItemService();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newLabelsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _moreExpanded = true;
  String? _loadError;

  List<LookupOption> _workspaces = const [];
  List<LookupOption> _workTypes = const [];
  List<LookupOption> _users = const [];
  List<LookupOption> _teams = const [];
  List<LookupOption> _labels = const [];
  List<LookupOption> _parentItems = const [];
  List<LookupOption> _sprintOptions = const [];
  final List<AttachmentCreateRequest> _attachments = [];
  final Set<int> _selectedLabelIds = <int>{};

  LookupOption? _selectedWorkspace;
  LookupOption? _selectedWorkType;
  LookupOption? _selectedReporter;
  LookupOption? _selectedAssignee;
  LookupOption? _selectedTeam;
  LookupOption? _selectedParent;
  LookupOption? _selectedSprint;
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
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: CreateWorkItemTopBar(
                saving: _saving,
                onClose: () => context.pop(),
                onSubmit: _submit,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? CreateWorkItemLoadError(
                      message: _loadError ?? '请检查 Firebase 配置和网络连接。',
                      onRetry: _loadInitialData,
                    )
                  : _workspaces.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.public_outlined,
                      title: '还没有空间',
                      description: '请先创建一个真实数据库空间，再创建工作项。',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                      children: [
                        TypeSelectorBar(
                          workspace: _selectedWorkspace,
                          workType: _selectedWorkType,
                          workspaces: _workspaces,
                          workTypes: _workTypes,
                          onWorkspaceChanged: (value) {
                            setState(() {
                              _selectedWorkspace = value;
                              _selectedParent = null;
                              _selectedSprint = null;
                            });
                            _loadSprintOptions();
                            _loadMembers();
                          },
                          onWorkTypeChanged: (value) => setState(() {
                            _selectedWorkType = value;
                          }),
                          onWorkspaceLoadParentItems: _loadParentItems,
                        ),
                        const SizedBox(height: AppSpace.sectionGap),
                        TextField(
                          controller: _summaryController,
                          maxLength: 200,
                          style: theme.textTheme.headlineMedium,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '添加摘要...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sectionGap),
                        CreateWorkItemSectionCard(
                          title: '描述',
                          child: TextField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              hintText: '添加描述……',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.sectionGap),
                        CreateWorkItemAttachmentsSection(
                          attachments: _attachments,
                          saving: _saving,
                          onAddPhoto: () =>
                              _addAttachment(initialKind: AttachmentKind.photo),
                          onAddVideo: () =>
                              _addAttachment(initialKind: AttachmentKind.video),
                          onAddDocument: () => _addAttachment(
                            initialKind: AttachmentKind.document,
                          ),
                          onAddScreen: () =>
                              _addAttachment(initialKind: AttachmentKind.video),
                          onDeleteAttachment: (index) {
                            setState(() => _attachments.removeAt(index));
                          },
                        ),
                        const SizedBox(height: AppSpace.sectionGap),
                        CreateWorkItemMoreFieldsSection(
                          expanded: _moreExpanded,
                          onToggle: () =>
                              setState(() => _moreExpanded = !_moreExpanded),
                          reporter: _selectedReporter,
                          assignee: _selectedAssignee,
                          team: _selectedTeam,
                          parent: _selectedParent,
                          sprint: _selectedSprint,
                          startDate: _startDate,
                          dueDate: _dueDate,
                          selectedLabelCount: _selectedLabelIds.length,
                          selectedLabelNames: _selectedLabelNames,
                          newLabelsController: _newLabelsController,
                          onPickReporter: () async {
                            final result = await _pickLookup(
                              title: '选择经办人',
                              options: _users,
                              selected: _selectedReporter,
                            );
                            if (result != null) {
                              setState(() => _selectedReporter = result);
                            }
                          },
                          onPickAssignee: () async {
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
                          onPickLabels: _toggleLabelSheet,
                          onPickParent: () async {
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
                          onPickTeam: () async {
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
                          onPickSprint: () async {
                            if (_selectedWorkspace == null) {
                              _showSnackBar('请先选择空间');
                              return;
                            }
                            final result = await _pickLookup(
                              title: '选择冲刺',
                              options: _sprintOptions,
                              selected: _selectedSprint,
                              allowClear: true,
                              emptyLabel: '当前空间暂无冲刺，可前往空间内创建',
                            );
                            if (result != _selectedSprint) {
                              setState(() => _selectedSprint = result);
                            }
                          },
                          onPickStartDate: () => _pickDate(
                            title: '选择开始日期',
                            initial: _startDate,
                            onPicked: (value) =>
                                setState(() => _startDate = value),
                          ),
                          onPickDueDate: () => _pickDate(
                            title: '选择截止日期',
                            initial: _dueDate,
                            onPicked: (value) =>
                                setState(() => _dueDate = value),
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
        _teams = lookups.teams;
        _labels = lookups.labels;
        _selectedWorkspace = _selectedWorkspace ?? _firstOrNull(_workspaces);
        _selectedWorkType = _selectedWorkType ?? _firstOrNull(_workTypes);
        _loading = false;
      });
      await _loadMembers();
      await _loadParentItems();
      await _loadSprintOptions();
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

  Future<void> _loadMembers() async {
    final workspace = _selectedWorkspace;
    if (workspace == null) {
      setState(() {
        _users = const [];
        _selectedReporter = null;
        _selectedAssignee = null;
      });
      return;
    }
    try {
      final members = await _api.loadWorkspaceMembers(workspace.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _users = members;
        final memberIds = members.map((m) => m.id).toSet();
        if (_selectedReporter == null ||
            !memberIds.contains(_selectedReporter!.id)) {
          _selectedReporter = _firstOrNull(members);
        }
        if (_selectedAssignee != null &&
            !memberIds.contains(_selectedAssignee!.id)) {
          _selectedAssignee = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _users = const [];
        _selectedReporter = null;
        _selectedAssignee = null;
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

  Future<void> _loadSprintOptions() async {
    final workspace = _selectedWorkspace;
    if (workspace == null) {
      setState(() => _sprintOptions = const []);
      return;
    }
    try {
      final sprints = await _api.listSprints(workspaceId: workspace.id);
      if (!mounted) {
        return;
      }
      setState(
        () => _sprintOptions = sprints
            .where((sprint) => sprint.status != SprintStatus.completed)
            .map((sprint) => sprint.toLookup())
            .toList(growable: false),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _sprintOptions = const []);
    }
  }

  Future<void> _submit() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) {
      _showSnackBar('请输入摘要');
      return;
    }
    if (_selectedWorkspace == null ||
        _selectedWorkType == null ||
        _selectedReporter == null) {
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
          sprintId: _selectedSprint?.id,
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

  Future<void> _addAttachment({
    AttachmentKind initialKind = AttachmentKind.document,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final uriController = TextEditingController();
    final mimeTypeController = TextEditingController();
    AttachmentKind selectedKind = initialKind;

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
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHeader(title: '选择标签'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _labels.map((label) {
                            final isSelected = selected.contains(label.id);
                            return FilterChip(
                              label: Text(label.title),
                              selected: isSelected,
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
                            onPressed: () =>
                                Navigator.of(context).pop(selected),
                            child: const Text('完成'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
    required String title,
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final result = await showDatePickerSheet(
      context,
      title: title,
      initialEnd: initial,
      allowRange: false,
    );
    if (result != null) {
      onPicked(result.end);
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
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final palette = AppThemePalette.of(context);
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        final searchController = TextEditingController();
        final showSearch = options.length > 5;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  final query = searchController.text.trim().toLowerCase();
                  final filtered = options
                      .where((item) {
                        if (query.isEmpty) {
                          return true;
                        }
                        return item.title.toLowerCase().contains(query) ||
                            (item.subtitle?.toLowerCase().contains(query) ??
                                false);
                      })
                      .toList(growable: false);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SheetHeader(title: title),
                      if (showSearch)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: TextField(
                            controller: searchController,
                            autofocus: true,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(
                              hintText: '搜索',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                          ),
                        ),
                      if (allowClear)
                        ListTile(
                          leading: Icon(
                            Icons.clear_rounded,
                            color: palette.textSecondary,
                          ),
                          title: const Text('清空'),
                          onTap: () => Navigator.of(context).pop(null),
                        ),
                      Flexible(
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Text(
                                  emptyLabel,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected = item.id == selected?.id;
                                  return ListTile(
                                    title: Text(item.title),
                                    subtitle: item.subtitle == null
                                        ? null
                                        : Text(item.subtitle!),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: palette.primary,
                                          )
                                        : null,
                                    onTap: () =>
                                        Navigator.of(context).pop(item),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
