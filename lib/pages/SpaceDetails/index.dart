import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/components/SpaceDetails/BacklogTabView.dart';
import 'package:ottersync/components/SpaceDetails/BoardTabView.dart';
import 'package:ottersync/components/SpaceDetails/CalendarTabView.dart';
import 'package:ottersync/components/SpaceDetails/ReportTabView.dart';
import 'package:ottersync/components/SpaceDetails/SettingsTabView.dart';
import 'package:ottersync/components/SpaceDetails/SprintManagerSheet.dart';
import 'package:ottersync/components/SpaceDetails/SummaryTabView.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class SpaceDetailsView extends StatefulWidget {
  const SpaceDetailsView({super.key, this.spaceId, WorkItemApi? api})
    : _api = api;

  final int? spaceId;
  final WorkItemApi? _api;

  @override
  State<SpaceDetailsView> createState() => _SpaceDetailsViewState();
}

class _SpaceDetailsViewState extends State<SpaceDetailsView>
    with SingleTickerProviderStateMixin {
  late final WorkItemApi _api;
  late final TabController _tabController;
  JiraSpace? _space;
  List<SpaceSummaryMetric> _metrics = const [];
  List<BacklogGroup> _groups = const [];
  List<IssueSummary> _boardItems = const [];
  List<IssueSummary> _calendarItems = const [];
  List<IssueSummary> _allItems = const [];
  List<Sprint> _sprints = const [];
  WorkItemStatus? _statusFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _tabController = TabController(length: 6, vsync: this);
    _loadSpaceDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            Text(
              _space?.name ?? '空间详情',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: palette.textSecondary,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openStatusFilter,
            tooltip: '状态筛选',
            icon: Icon(
              _statusFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
          ),
          IconButton(
            onPressed: _openMoreActions,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          dividerColor: palette.divider,
          labelColor: palette.primary,
          unselectedLabelColor: palette.textSecondary,
          indicatorColor: palette.primary,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '摘要'),
            Tab(text: '面板'),
            Tab(text: '日历'),
            Tab(text: '待办事项列表'),
            Tab(text: '报告'),
            Tab(text: '设置'),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_space == null) {
      return const EmptyStateView(
        icon: Icons.public_off_outlined,
        title: '还没有这个空间',
        description: '请选择一个真实数据库空间后再查看详情。',
      );
    }

    final filteredGroups = _statusFilter == null
        ? _groups
        : _groups.map((group) {
            final filtered = group.items
                .where((item) => item.statusKey == _statusFilter)
                .toList(growable: false);
            return BacklogGroup(
              title: group.title,
              issueCount: filtered.length,
              todoCount: filtered.where((i) => i.statusKey == WorkItemStatus.todo).length,
              inProgressCount: filtered.where((i) => i.statusKey == WorkItemStatus.inProgress).length,
              doneCount: filtered.where((i) => i.statusKey == WorkItemStatus.done).length,
              items: filtered,
              sprintId: group.sprintId,
            );
          }).where((g) => g.items.isNotEmpty || g.sprintId == null).toList(growable: false);

    final filteredBoardItems = _statusFilter == null
        ? _boardItems
        : _boardItems.where((item) => item.statusKey == _statusFilter).toList(growable: false);

    final statusCounts = <WorkItemStatus, int>{};
    for (final s in WorkItemStatus.values) {
      statusCounts[s] = _allItems.where((i) => i.statusKey == s).length;
    }
    final priorityCounts = <String, int>{};
    for (final i in _allItems) {
      final p = i.priority ?? 'Medium';
      priorityCounts[p] = (priorityCounts[p] ?? 0) + 1;
    }

    return TabBarView(
      controller: _tabController,
      children: [
        SummaryTabView(
          metrics: _metrics,
          statusCounts: statusCounts,
          priorityCounts: priorityCounts,
          onMetricTap: (index) => _tabController.animateTo(_metricToTab(index)),
          onStatusTap: (status) {
            setState(() => _statusFilter = status);
            _tabController.animateTo(3);
          },
          onPriorityTap: (label) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已筛选优先级：$label（仅在数据存在时生效）')),
            );
          },
        ),
        BoardTabView(
          sprints: _sprints,
          items: filteredBoardItems,
          onOpenSprintManager: _openSprintManager,
          onItemTap: _openWorkItem,
          onItemStatusChanged: _onItemStatusChanged,
        ),
        CalendarTabView(
          items: _calendarItems,
          onItemTap: _openWorkItem,
          onScheduleItem: _scheduleItemDueDate,
        ),
        if (filteredGroups.isEmpty)
          EmptyStateView(
            icon: Icons.view_list_outlined,
            title: _statusFilter != null ? '没有匹配的工作项' : '还没有待办事项',
            description: _statusFilter != null ? '该状态下没有工作项。' : '当这个空间下有真实数据库任务后，会显示在这里。',
          )
        else
          BacklogTabView(
            groups: filteredGroups,
            onCreate: _createBacklogItemForGroup,
            onItemTap: _openWorkItem,
            onToggleDone: _toggleItemDone,
          ),
        ReportTabView(
          spaceKey: _space?.key ?? 'OT',
          sprints: _sprints,
          items: _allItems,
        ),
        SettingsTabView(space: _space!),
      ],
    );
  }

  int _metricToTab(int index) {
    switch (index) {
      case 0:
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 2;
      default:
        return 0;
    }
  }

  void _openMoreActions() {
    final palette = AppThemePalette.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: '空间操作'),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: palette.primary),
              title: const Text('编辑空间名称'),
              onTap: () {
                Navigator.pop(ctx);
                _editSpaceName();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded,
                  color: Color(0xFF1F5DBD)),
              title: const Text('管理冲刺'),
              onTap: () {
                Navigator.pop(ctx);
                _openSprintManager();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_rounded, color: palette.danger),
              title: Text(
                '删除空间',
                style: TextStyle(color: palette.danger),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteSpace();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editSpaceName() async {
    if (_space == null) return;
    final controller = TextEditingController(text: _space!.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑空间名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '空间名称'),
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
    if (result == null || result.isEmpty || !mounted) return;
    try {
      await _api.updateWorkspace(_space!.id, name: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('空间名称已更新')),
      );
      await _loadSpaceDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败：$e')),
      );
    }
  }

  Future<void> _confirmDeleteSpace() async {
    if (_space == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除空间'),
        content: Text('确定要删除「${_space!.name}」吗？该空间下的所有工作项将被一并删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.deleteWorkspace(_space!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('空间已删除')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  Future<void> _openSprintManager() async {
    if (_space == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SprintManagerSheet(
        api: _api,
        workspaceId: _space!.id,
        onChanged: _loadSpaceDetails,
      ),
    );
  }

  Future<void> _createBacklogItemForGroup(
      BacklogGroup group, String summary) async {
    if (_space == null) return;
    try {
      final created = await _api.createBacklogItem(
        workspaceId: _space!.id,
        summary: summary,
        sprintId: group.sprintId,
      );
      if (!mounted) return;
      // 局部更新：只刷新 backlog 与全部数据，避免整页 loading
      final groups = await _api.loadBacklogGroups(_space!.id);
      final allItems = await _api.loadCalendarItems(_space!.id);
      final boardItems = await _api.loadBoardItems(_space!.id);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _allItems = allItems;
        _calendarItems = allItems;
        _boardItems = boardItems;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已创建 ${created.key}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败：$e')),
      );
    }
  }

  Future<void> _toggleItemDone(IssueSummary item, bool done) async {
    if (item.id == null) return;
    final newStatus = done ? WorkItemStatus.done : WorkItemStatus.todo;
    _applyLocalStatus(item.id!, newStatus);
    try {
      await _api.updateWorkItemStatus(item.id!, newStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新失败：$e')));
    }
  }

  Future<void> _onItemStatusChanged(
      IssueSummary item, WorkItemStatus status) async {
    if (item.id == null) return;
    _applyLocalStatus(item.id!, status);
    try {
      await _api.updateWorkItemStatus(item.id!, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新失败：$e')));
    }
  }

  Future<void> _scheduleItemDueDate(
      IssueSummary item, DateTime date) async {
    if (item.id == null) return;
    final updated = item.copyWith(dueDate: date);
    setState(() {
      _allItems = _allItems
          .map((i) => i.id == item.id ? updated : i)
          .toList(growable: false);
      _calendarItems = _allItems;
      _boardItems = _boardItems
          .map((i) => i.id == item.id ? updated : i)
          .toList(growable: false);
    });
    try {
      await _api.updateWorkItemDueDate(item.id!, date);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已安排到 ${date.month}/${date.day}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新失败：$e')));
    }
  }

  void _applyLocalStatus(int id, WorkItemStatus status) {
    final label = workItemStatusLabel(status);
    IssueSummary patch(IssueSummary i) =>
        i.id == id ? i.copyWith(statusKey: status, status: label) : i;
    setState(() {
      _allItems = _allItems.map(patch).toList(growable: false);
      _calendarItems = _calendarItems.map(patch).toList(growable: false);
      _boardItems = _boardItems.map(patch).toList(growable: false);
      _groups = _groups
          .map((g) {
            final items = g.items.map(patch).toList(growable: false);
            return BacklogGroup(
              title: g.title,
              issueCount: items.length,
              todoCount:
                  items.where((i) => i.statusKey == WorkItemStatus.todo).length,
              inProgressCount: items
                  .where((i) => i.statusKey == WorkItemStatus.inProgress)
                  .length,
              doneCount:
                  items.where((i) => i.statusKey == WorkItemStatus.done).length,
              items: items,
              sprintId: g.sprintId,
            );
          })
          .toList(growable: false);
    });
  }

  (IconData, Color) _statusVisual(WorkItemStatus status) {
    switch (status) {
      case WorkItemStatus.todo:
        return (
          Icons.radio_button_unchecked_rounded,
          const Color(0xFF44546F),
        );
      case WorkItemStatus.inProgress:
        return (Icons.timelapse_rounded, const Color(0xFF1F5DBD));
      case WorkItemStatus.done:
        return (Icons.check_circle_rounded, const Color(0xFF1F8B4C));
    }
  }

  void _openWorkItem(IssueSummary item) {
    if (item.id == null) return;
    GoRouter.of(context).push('/work-item/${item.id}', extra: item);
  }

  void _openStatusFilter() {
    final palette = AppThemePalette.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: '按状态筛选'),
            ListTile(
              title: const Text('全部'),
              leading: const Icon(Icons.all_inclusive_rounded,
                  color: Color(0xFF44546F)),
              trailing: _statusFilter == null
                  ? Icon(Icons.check_rounded, color: palette.primary)
                  : null,
              onTap: () {
                setState(() => _statusFilter = null);
                Navigator.pop(ctx);
              },
            ),
            ...WorkItemStatus.values.map(
              (status) {
                final (icon, color) = _statusVisual(status);
                return ListTile(
                  title: Text(workItemStatusLabel(status)),
                  leading: Icon(icon, color: color),
                  trailing: _statusFilter == status
                      ? Icon(Icons.check_rounded, color: palette.primary)
                      : null,
                  onTap: () {
                    setState(() => _statusFilter = status);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSpaceDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spaceId = widget.spaceId;
      if (spaceId == null) {
        final spaces = await _api.listSpaces();
        if (spaces.isEmpty) {
          if (!mounted) return;
          setState(() {
            _space = null;
            _metrics = const [];
            _groups = const [];
            _boardItems = const [];
            _calendarItems = const [];
            _allItems = const [];
            _sprints = const [];
            _loading = false;
          });
          return;
        }
        _space = spaces.first;
      } else {
        _space = await _api.getWorkspaceById(spaceId);
      }

      if (_space == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final results = await Future.wait([
        _api.loadSpaceSummaryMetrics(_space!.id),
        _api.loadBacklogGroups(_space!.id),
        _api.loadBoardItems(_space!.id),
        _api.loadCalendarItems(_space!.id),
        _api.listSprints(workspaceId: _space!.id),
      ]);

      if (!mounted) return;
      setState(() {
        _metrics = results[0] as List<SpaceSummaryMetric>;
        _groups = results[1] as List<BacklogGroup>;
        _boardItems = results[2] as List<IssueSummary>;
        _calendarItems = results[3] as List<IssueSummary>;
        _allItems = results[3] as List<IssueSummary>;
        _sprints = results[4] as List<Sprint>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }
}
