import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemAttachmentsSection.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemLoadError.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemMoreFieldsSection.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemSectionCard.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemTopBar.dart';
import 'package:ottersync/components/CreateWorkItem/TypeSelectorBar.dart';
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
            ? CreateWorkItemLoadError(
                message: _loadError ?? '请检查 Firebase 配置和网络连接。',
                onRetry: _loadInitialData,
              )
            : ListView(
                padding: AppSpace.pagePaddingWithNav,
                children: [
                  CreateWorkItemTopBar(
                    saving: _saving,
                    onClose: () => context.pop(),
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: AppSpace.sectionGap),
                  TypeSelectorBar(
                    workspace: _selectedWorkspace,
                    workType: _selectedWorkType,
                    workspaces: _workspaces,
                    workTypes: _workTypes,
                    onWorkspaceChanged: (value) => setState(() {
                      _selectedWorkspace = value;
                      _selectedParent = null;
                    }),
                    onWorkTypeChanged: (value) => setState(() {
                      _selectedWorkType = value;
                    }),
                    onWorkspaceLoadParentItems: _loadParentItems,
                  ),
                  const SizedBox(height: AppSpace.sectionGap),
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
                    onAddDocument: () =>
                        _addAttachment(initialKind: AttachmentKind.document),
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
                    onPickStartDate: () => _pickDate(
                      initial: _startDate,
                      onPicked: (value) => setState(() => _startDate = value),
                    ),
                    onPickDueDate: () => _pickDate(
                      initial: _dueDate,
                      onPicked: (value) => setState(() => _dueDate = value),
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
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return AppSurface(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  radius: AppSpace.radiusXLarge,
                  child: Column(
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
                  ),
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
        final searchController = TextEditingController();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
                return AppSurface(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  radius: AppSpace.radiusXLarge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: title == '选择空间' ? '搜索空间' : '搜索工作类型',
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (allowClear)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('清空'),
                          onTap: () => Navigator.of(context).pop(null),
                        ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            emptyLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      else
                        SizedBox(
                          height: screenHeight * 0.5,
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
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
                );
              },
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
